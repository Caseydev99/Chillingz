/* ==========================================================================
   newsletter.js — "Sign up for updates and newsletters"
   --------------------------------------------------------------------------
   The sign-up box sits at the top of the footer on every page. Visitors
   choose what they'd like (Chillingz updates, the newsletter, or both), tick
   to agree, and their email is saved in Firebase (collection:
   newsletterSignups). Only Chillingz admins can read that list — for
   example to import it into your email platform (MailerLite).

   Logged-in members who sign up also get the matching boxes ticked in
   My Account → Email preferences, so both places agree.
   ========================================================================== */

import { escapeHtml, storage } from "./utils.js";
import { loadFirestore } from "./firebase.js";
import { getCurrentUser } from "./auth.js";

// Remembers that this browser has already signed up, to say "you're on the list"
const SIGNED_UP_KEY = "chillingz.newsletterEmail";

/* The HTML for the sign-up box (site.js puts it in the footer). */
export function newsletterHtml() {
  const already = storage.get(SIGNED_UP_KEY);
  return `
    <section class="newsletter" aria-labelledby="newsletter-title">
      <div class="newsletter-text">
        <h2 id="newsletter-title">Sign up for updates &amp; newsletters</h2>
        <p>New places, the best of what's on, and Chillingz news — straight to your inbox. No spam, and you can unsubscribe any time.</p>
      </div>
      ${already ? alreadyHtml(already) : `
      <form class="newsletter-form" novalidate data-newsletter-form>
        <div class="newsletter-fields">
          <div class="field">
            <label for="newsletter-email">Email address</label>
            <input class="input" id="newsletter-email" name="email" type="email" autocomplete="email" required placeholder="you@example.com">
          </div>
          <div class="field">
            <label for="newsletter-name">First name <span class="small-print">(optional)</span></label>
            <input class="input" id="newsletter-name" name="name" type="text" autocomplete="given-name">
          </div>
        </div>
        <fieldset class="newsletter-lists">
          <legend class="visually-hidden">What would you like?</legend>
          <label class="checkbox-row"><input type="checkbox" name="lists" value="newsletter" checked><span>The Chillingz newsletter</span></label>
          <label class="checkbox-row"><input type="checkbox" name="lists" value="updates" checked><span>Chillingz updates and launch news</span></label>
        </fieldset>
        <label class="checkbox-row">
          <input type="checkbox" name="consent" required>
          <span>I agree to receive these emails from Chillingz. See our <a href="privacy.html">privacy policy</a>.</span>
        </label>
        <p class="form-message" role="alert" data-form-message></p>
        <button class="btn btn-primary" type="submit">Sign me up</button>
      </form>`}
    </section>`;
}

/* What's shown once someone has signed up in this browser. */
function alreadyHtml(email) {
  return `
    <div class="newsletter-done" tabindex="-1" data-newsletter-done>
      <p><strong>You're on the list!</strong> We'll send updates to ${escapeHtml(email)}.</p>
      <p class="small-print">Every email has an unsubscribe link. <button class="link-btn" type="button" data-newsletter-reset>Use a different email</button></p>
    </div>`;
}

/* Checks the form, saves the sign-up, and shows a thank-you. */
async function handleSubmit(event) {
  event.preventDefault();
  const form = event.target;
  const message = form.querySelector("[data-form-message]");
  const email = form.elements.email.value.trim().toLowerCase();
  const name = form.elements.name.value.trim();
  const lists = [...form.querySelectorAll('[name="lists"]:checked')].map((box) => box.value);
  const consent = form.elements.consent.checked;

  // Check the boxes before sending anything
  let problem = "";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) problem = "Please enter a valid email address.";
  else if (!lists.length) problem = "Please choose at least one kind of email.";
  else if (!consent) problem = "Please tick to agree to receive emails.";
  form.elements.email.setAttribute("aria-invalid", problem.includes("email address") ? "true" : "false");
  message.dataset.type = "error";
  message.textContent = problem;
  if (problem) return;

  const button = form.querySelector('[type="submit"]');
  button.disabled = true;
  button.textContent = "Signing you up…";
  try {
    const user = getCurrentUser();
    const { db, collection, addDoc, doc, setDoc, serverTimestamp } = await loadFirestore();
    await addDoc(collection(db, "newsletterSignups"), {
      email,
      name: name.slice(0, 100),
      lists,
      consent: true,
      page: location.pathname.slice(0, 200),
      userId: user?.uid ?? null,
      source: "web",
      createdAt: serverTimestamp(),
    });

    // Members: tick the same boxes in My Account → Email preferences
    if (user) {
      await setDoc(doc(db, "users", user.uid), {
        emailPreferences: { bookingUpdates: true, newsletter: lists.includes("newsletter"), updates: lists.includes("updates"), updatedAt: new Date().toISOString() },
      }, { merge: true }).catch((error) => console.error("Could not update email preferences", error));
    }

    storage.set(SIGNED_UP_KEY, email);
    form.outerHTML = alreadyHtml(email);
    document.querySelector("[data-newsletter-done]")?.focus();
  } catch (error) {
    console.error("Newsletter sign-up failed", error);
    message.textContent = "Sorry, we couldn't sign you up just now. Please try again in a moment.";
    button.disabled = false;
    button.textContent = "Sign me up";
  }
}

/* Connects the form (called by site.js after the footer is drawn). */
export function initNewsletter() {
  document.addEventListener("submit", (event) => {
    if (event.target.matches("[data-newsletter-form]")) handleSubmit(event);
  });

  // "Use a different email" brings the form back
  document.addEventListener("click", (event) => {
    if (!event.target.closest("[data-newsletter-reset]")) return;
    storage.remove(SIGNED_UP_KEY);
    const box = document.querySelector(".newsletter");
    box.outerHTML = newsletterHtml();
    document.querySelector("#newsletter-email")?.focus();
  });
}
