/* ==========================================================================
   pages.js — the smaller pages: rewards, contact, FAQs
   --------------------------------------------------------------------------
   Each of these pages has  <main data-page="contact">  (or "rewards", "faqs").
   This file looks at that name and runs the matching function below.
   The words come from data.js, so you can edit them there.

   The contact form sends an "enquiry" to Firebase
   (collection: enquiries). Only Chillingz admins can read them.
   ========================================================================== */

import { REWARDS, FAQS, CONTACT_TOPICS, SITE } from "./data.js";
import { escapeHtml } from "./utils.js";
import { getCurrentUser, whenAuthReady } from "./auth.js";
import { loadFirestore } from "./firebase.js";
import { getListing, detailUrl } from "./content.js";
import { listingImage } from "./cards.js";

const main = document.querySelector("[data-page]");
const $ = (selector) => main.querySelector(selector);


/* --------------------------------------------------------------------------
   Shared form helpers
   -------------------------------------------------------------------------- */

const looksLikeEmail = (text) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text);

/* Checks a form. "rules" maps each field name to a function that gives back
   an error message, or "" when the value is fine. Shows each message under
   its box (in <p id="FIELD-error">) and moves to the first problem. */
function checkForm(form, rules) {
  let firstProblem = null;
  Object.entries(rules).forEach(([name, rule]) => {
    const input = form.elements[name];
    const value = input.type === "checkbox" ? input.checked : input.value.trim();
    const message = rule(value);
    const errorBox = form.querySelector(`#${form.dataset.form}-${name}-error`);
    if (errorBox) errorBox.textContent = message;
    input.setAttribute("aria-invalid", message ? "true" : "false");
    if (message && !firstProblem) firstProblem = input;
  });
  firstProblem?.focus();
  return !firstProblem;
}

/* Sends a message to Chillingz (saved in Firebase "enquiries"). */
async function sendEnquiry({ topic, name, email, phone = "", message, details = {} }) {
  const { db, collection, addDoc, serverTimestamp } = await loadFirestore();
  await addDoc(collection(db, "enquiries"), {
    topic,
    name: name.slice(0, 100),
    email: email.toLowerCase().slice(0, 200),
    phone: phone.slice(0, 30),
    message: message.slice(0, 3000),
    details,
    userId: getCurrentUser()?.uid ?? null,
    source: "web",
    createdAt: serverTimestamp(),
  });
}

/* Runs a form's send button: "Sending…", then a thank-you, or an error that
   offers our email address instead. */
async function submitWithFeedback(form, send, thanksHtml) {
  const button = form.querySelector('[type="submit"]');
  const message = form.querySelector("[data-form-message]");
  const label = button.textContent;
  button.disabled = true;
  button.textContent = "Sending…";
  message.textContent = "";
  try {
    await send();
    form.outerHTML = `<div class="account-card form-thanks" tabindex="-1" data-thanks>${thanksHtml}</div>`;
    main.querySelector("[data-thanks]").focus();
  } catch (error) {
    console.error("Sending failed", error);
    message.dataset.type = "error";
    message.innerHTML = `Sorry, that didn't send. Please try again, or email us at <a href="mailto:${SITE.email}">${SITE.email}</a>.`;
    button.disabled = false;
    button.textContent = label;
  }
}

/* Fills in name and email for logged-in members. */
async function prefillFromAccount(form) {
  const user = await whenAuthReady();
  if (!user) return;
  if (form.elements.name && !form.elements.name.value) form.elements.name.value = user.displayName ?? "";
  if (form.elements.email && !form.elements.email.value) form.elements.email.value = user.email ?? "";
}


/* --------------------------------------------------------------------------
   Rewards
   -------------------------------------------------------------------------- */
async function rewardsPage() {
  $("[data-rewards-intro]").textContent = REWARDS.intro;
  $("[data-rewards-steps]").innerHTML = REWARDS.steps.map((step) => `<li>${escapeHtml(step)}</li>`).join("");
  const user = await whenAuthReady();
  $("[data-rewards-cta]").innerHTML = user
    ? '<a class="btn btn-primary" href="account.html#rewards">Go to My Rewards</a>'
    : '<button class="btn btn-primary" type="button" data-open-login="signup">Create a free account</button>';
}


/* --------------------------------------------------------------------------
   Contact
   -------------------------------------------------------------------------- */
function contactPage() {
  const form = $("[data-form='contact']");
  const wanted = new URLSearchParams(location.search).get("topic");
  form.elements.topic.innerHTML = CONTACT_TOPICS
    .map((topic) => `<option value="${topic.id}" ${topic.id === wanted ? "selected" : ""}>${escapeHtml(topic.label)}</option>`)
    .join("");
  main.querySelectorAll("[data-site-email]").forEach((link) => {
    link.href = `mailto:${SITE.email}`;
    link.textContent = SITE.email;
  });
  prefillFromAccount(form);

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const ok = checkForm(form, {
      name: (value) => (value ? "" : "Please enter your name."),
      email: (value) => (looksLikeEmail(value) ? "" : "Please enter a valid email address."),
      phone: (value) => (!value || /^[\d\s+()-]{7,20}$/.test(value) ? "" : "Please enter a valid phone number, or leave it empty."),
      message: (value) => (value.length >= 10 ? "" : "Please write a little more (at least 10 characters)."),
    });
    if (!ok) return;
    const values = Object.fromEntries(new FormData(form));
    submitWithFeedback(form, () => sendEnquiry({
      topic: values.topic,
      name: values.name.trim(),
      email: values.email.trim(),
      phone: values.phone.trim(),
      message: values.message.trim(),
    }), `
      <h2>Thanks, ${escapeHtml(values.name.trim().split(" ")[0])}!</h2>
      <p>We've got your message and will reply to <strong>${escapeHtml(values.email.trim())}</strong>, usually within two working days.</p>`);
  });
}


/* --------------------------------------------------------------------------
   FAQs: questions that open when tapped, plus information for Google
   -------------------------------------------------------------------------- */
function faqsPage() {
  $("[data-faqs]").innerHTML = FAQS
    .map((item) => `
      <details class="faq">
        <summary>${escapeHtml(item.question)}</summary>
        <p>${escapeHtml(item.answer)}</p>
      </details>`)
    .join("");

  const script = document.createElement("script");
  script.type = "application/ld+json";
  script.textContent = JSON.stringify({
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQS.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: { "@type": "Answer", text: item.answer },
    })),
  });
  document.head.append(script);
}


/* --------------------------------------------------------------------------
   Start the right one
   -------------------------------------------------------------------------- */
const pages = { rewards: rewardsPage, contact: contactPage, faqs: faqsPage };
pages[main.dataset.page]?.();
