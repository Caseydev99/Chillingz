/* ==========================================================================
   pages.js — the smaller pages: offers, vouchers, rewards, contact, FAQs
   --------------------------------------------------------------------------
   Each of these pages has  <main data-page="offers">  (or "vouchers", …).
   This file looks at that name and runs the matching function below.
   The words come from data.js, so you can edit them there.

   The contact form and the voucher form send an "enquiry" to Firebase
   (collection: enquiries). Only Chillingz admins can read them.
   ========================================================================== */

import { OFFERS, VOUCHER_AMOUNTS, REWARDS, FAQS, CONTACT_TOPICS, SITE } from "./data.js";
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
   Offers
   -------------------------------------------------------------------------- */
async function offersPage() {
  const today = new Date().toISOString().slice(0, 10);
  const current = OFFERS.filter((offer) => !offer.ends || offer.ends >= today);

  if (!current.length) {
    $("[data-offers]").innerHTML = `
      <div class="notice">
        <h2>No offers right now</h2>
        <p>We're lining up deals with venues across London. Create an account and switch on offer emails to hear first.</p>
        <div class="button-row">
          <button class="btn btn-primary" type="button" data-open-login="signup">Create an account</button>
          <a class="btn btn-secondary" href="search.html">Browse places</a>
        </div>
      </div>`;
    return;
  }

  const cards = await Promise.all(current.map(async (offer) => {
    const listing = offer.listingId ? await getListing(offer.listingId) : null;
    return `
      <li>
        <article class="guide-card">
          ${listingImage(listing ?? {}, { sizes: "(min-width: 1024px) 33vw, 90vw" })}
          <div class="card-body">
            ${offer.ends ? `<p class="chip">Ends ${escapeHtml(new Date(offer.ends).toLocaleDateString("en-GB", { day: "numeric", month: "short" }))}</p>` : ""}
            <h2 class="card-title">${listing ? `<a href="${detailUrl(listing)}">${escapeHtml(offer.title)}</a>` : escapeHtml(offer.title)}</h2>
            <p class="card-details">${escapeHtml(offer.venue ?? listing?.title ?? "")}</p>
            ${offer.details ? `<p class="small-print">${escapeHtml(offer.details)}</p>` : ""}
          </div>
        </article>
      </li>`;
  }));
  $("[data-offers]").innerHTML = `<ul class="guide-grid">${cards.join("")}</ul>`;
}


/* --------------------------------------------------------------------------
   Gift vouchers
   No card details are taken here: we send a request, and Chillingz replies
   with a secure payment link from a payment provider.
   -------------------------------------------------------------------------- */
function vouchersPage() {
  const form = $("[data-form='voucher']");
  form.querySelector("[data-amounts]").innerHTML = VOUCHER_AMOUNTS
    .map((amount, index) => `<label><input type="radio" name="amount" value="${amount}" ${index === 1 ? "checked" : ""}><span>£${amount}</span></label>`)
    .join("") + '<label><input type="radio" name="amount" value="other"><span>Other amount</span></label>';

  // Show the "other amount" box only when "Other amount" is picked
  const otherField = form.querySelector("[data-other-amount]");
  form.addEventListener("change", () => {
    otherField.hidden = form.elements.amount.value !== "other";
  });
  prefillFromAccount(form);

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const isOther = form.elements.amount.value === "other";
    const ok = checkForm(form, {
      ...(isOther ? { otherAmount: (value) => (Number(value) >= 10 && Number(value) <= 500 ? "" : "Please choose an amount between £10 and £500.") } : {}),
      recipientName: (value) => (value ? "" : "Please enter who it's for."),
      recipientEmail: (value) => (!value || looksLikeEmail(value) ? "" : "Please enter a valid email address, or leave it empty."),
      name: (value) => (value ? "" : "Please enter your name."),
      email: (value) => (looksLikeEmail(value) ? "" : "Please enter a valid email address."),
    });
    if (!ok) return;

    const amount = isOther ? Number(form.elements.otherAmount.value) : Number(form.elements.amount.value);
    const values = Object.fromEntries(new FormData(form));
    submitWithFeedback(form, () => sendEnquiry({
      topic: "vouchers",
      name: values.name.trim(),
      email: values.email.trim(),
      message: values.message.trim() || `Gift voucher for ${values.recipientName.trim()}`,
      details: {
        amount,
        recipientName: values.recipientName.trim().slice(0, 100),
        recipientEmail: values.recipientEmail.trim().slice(0, 200),
        sendOn: values.sendOn || "",
      },
    }), `
      <h2>Thanks — request received</h2>
      <p>We'll email <strong>${escapeHtml(values.email.trim())}</strong> a secure link to pay for your £${amount} voucher, then send it ${values.recipientEmail.trim() ? `to ${escapeHtml(values.recipientEmail.trim())}` : "to you"}${values.sendOn ? ` on ${escapeHtml(new Date(values.sendOn).toLocaleDateString("en-GB", { day: "numeric", month: "long" }))}` : ""}.</p>`);
  });
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
const pages = { offers: offersPage, vouchers: vouchersPage, rewards: rewardsPage, contact: contactPage, faqs: faqsPage };
pages[main.dataset.page]?.();
