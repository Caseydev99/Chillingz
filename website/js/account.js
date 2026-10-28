/* ==========================================================================
   account.js — the My Account page
   --------------------------------------------------------------------------
   Guests see a friendly "Log in to see this" message (and anything they've
   saved on this device). Logged-in members see four sections:
     #details    name, email, interests, password
     #favourites the places they've saved (shared with the app)
     #rewards    Chillingz Rewards
     #emails     which emails they'd like from us
   The part after # in the address decides which section is open, so links
   like account.html#favourites go straight to the right place.
   ========================================================================== */

import { REWARDS } from "./data.js";
import { escapeHtml, showToast } from "./utils.js";
import { whenAuthReady, signOutUser } from "./auth.js";
import { loadAuth, loadFirestore, loadFunctions } from "./firebase.js";
import { getFavouriteIds, updateHeartButtons } from "./favourites.js";
import { loadContent } from "./content.js";
import { listingCard } from "./cards.js";

const box = document.querySelector("[data-account]");
const MIN_INTERESTS = 3;

const SECTIONS = [
  { id: "details", label: "My details" },
  { id: "favourites", label: "My favourites" },
  { id: "rewards", label: "My rewards" },
  { id: "emails", label: "Email preferences" },
];

// The member's record from Firebase (users/{id}), loaded once
let profile = {};


/* --------------------------------------------------------------------------
   Guests
   -------------------------------------------------------------------------- */

/* Friendly message for guests — not an error, and nothing is forced. */
async function renderGuest() {
  const ids = getFavouriteIds();
  const { listings } = await loadContent().catch(() => ({ listings: [] }));
  const saved = listings.filter((listing) => ids.includes(listing.id));

  box.innerHTML = `
    <div class="notice account-guest">
      <h2>Log in to see this</h2>
      <p>Log in or create a free account to see your favourites and rewards — on the website and in the Chillingz app.</p>
      <div class="button-row">
        <button class="btn btn-primary" type="button" data-open-login>Log in</button>
        <button class="btn btn-secondary" type="button" data-open-login="signup">Create an account</button>
      </div>
      <p class="small-print">You don't need an account to browse.</p>
    </div>
    ${saved.length ? `
      <section class="section" aria-labelledby="device-favourites">
        <h2 id="device-favourites">Saved on this device</h2>
        <p class="small-print">These move into your account when you log in.</p>
        <ul class="results-grid">${saved.map((listing) => `<li>${listingCard(listing)}</li>`).join("")}</ul>
      </section>` : ""}`;
  updateHeartButtons();
}


/* --------------------------------------------------------------------------
   Sections for members
   -------------------------------------------------------------------------- */

/* My details: name, email, interests, password. */
async function detailsHtml(user) {
  const usesPassword = user.providerData.some((provider) => provider.providerId === "password");
  let tags = [];
  try {
    const { db, collection, getDocs } = await loadFirestore();
    const snapshot = await getDocs(collection(db, "tags"));
    tags = snapshot.docs
      .map((tagDoc) => tagDoc.data())
      .filter((tag) => !tag.status || String(tag.status).toLowerCase() === "active")
      .map((tag) => String(tag.tagName || tag.name || "").trim())
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b));
  } catch (error) {
    console.error("Could not load interests", error);
  }
  const chosen = profile.tags ?? [];

  return `
    <form class="account-card" novalidate data-details-form>
      <h2>My details</h2>
      <div class="field">
        <label for="account-name">Name</label>
        <input class="input" id="account-name" name="name" type="text" autocomplete="name" value="${escapeHtml(profile.name || user.displayName || "")}" required>
        <p class="field-error" id="account-name-error"></p>
      </div>
      <div class="field">
        <label for="account-email">Email</label>
        <input class="input" id="account-email" type="email" value="${escapeHtml(user.email ?? "")}" readonly aria-describedby="account-email-note">
        <p class="small-print" id="account-email-note">
          ${user.emailVerified ? "✓ Verified" : 'Not verified yet. <button class="link-btn" type="button" data-verify-email>Send verification email</button>'}
        </p>
      </div>
      <fieldset class="filter-group">
        <legend>Interests <span class="small-print">(pick at least ${MIN_INTERESTS})</span></legend>
        <div class="chip-options">
          ${tags.map((tag) => `<label><input type="checkbox" name="tag" value="${escapeHtml(tag)}" ${chosen.includes(tag) ? "checked" : ""}><span>${escapeHtml(tag)}</span></label>`).join("")}
        </div>
      </fieldset>
      <p class="form-message" role="alert" data-form-message></p>
      <button class="btn btn-primary" type="submit">Save changes</button>
    </form>

    <div class="account-card">
      <h2>Password &amp; sign-in</h2>
      ${usesPassword
        ? '<p>We\'ll email you a link to choose a new password.</p><button class="btn btn-secondary" type="button" data-reset-password>Email me a reset link</button>'
        : "<p>You sign in with Google, so there's no Chillingz password to change.</p>"}
      <p style="margin-top:16px"><button class="btn btn-secondary" type="button" data-sign-out-account>Log out</button></p>
      <p class="small-print" style="margin-top:16px">Want to leave? <a href="delete-account.html">Delete my account</a> — this permanently removes your profile and sign-in from the website and the app.</p>
    </div>`;
}

/* My favourites: the same list the app uses. */
async function favouritesHtml() {
  const ids = getFavouriteIds();
  const { listings } = await loadContent().catch(() => ({ listings: [] }));
  const saved = listings.filter((listing) => ids.includes(listing.id));
  // Items saved in the app that the website doesn't show (e.g. social posts)
  const appOnly = ids.length - saved.length;

  return `
    <div class="account-card">
      <h2>My favourites</h2>
      ${saved.length
        ? `<ul class="results-grid">${saved.map((listing) => `<li>${listingCard(listing)}</li>`).join("")}</ul>`
        : '<p>Nothing saved yet. Tap the ♡ on anything you like and it appears here and in the app.</p>'}
      ${appOnly > 0 ? `<p class="small-print" style="margin-top:12px">Plus ${appOnly} saved ${appOnly === 1 ? "item" : "items"} you can see in the Chillingz app.</p>` : ""}
    </div>`;
}

/* My rewards (placeholder until the scheme starts — see REWARDS in data.js). */
function rewardsHtml() {
  return `
    <div class="account-card">
      <h2>My rewards</h2>
      <p>${escapeHtml(REWARDS.intro)}</p>
      <ol class="steps">${REWARDS.steps.map((step) => `<li>${escapeHtml(step)}</li>`).join("")}</ol>
      <a class="btn btn-secondary" href="rewards.html">Find out more</a>
    </div>`;
}

/* Email preferences, saved in the member's record (users/{id}.emailPreferences). */
function emailsHtml() {
  const prefs = { offers: false, newsletter: false, updates: false, ...(profile.emailPreferences ?? {}) };
  return `
    <form class="account-card" data-emails-form>
      <h2>Email preferences</h2>
      <label class="checkbox-row"><input type="checkbox" name="offers" ${prefs.offers ? "checked" : ""}><span><strong>Offers and deals</strong> — perks and discounts at places we love.</span></label>
      <label class="checkbox-row"><input type="checkbox" name="newsletter" ${prefs.newsletter ? "checked" : ""}><span><strong>The Chillingz newsletter</strong> — new places, guides and what's on.</span></label>
      <label class="checkbox-row"><input type="checkbox" name="updates" ${prefs.updates ? "checked" : ""}><span><strong>Chillingz updates</strong> — launch news and new features.</span></label>
      <p class="form-message" role="status" data-form-message></p>
      <button class="btn btn-primary" type="submit">Save preferences</button>
    </form>`;
}


/* --------------------------------------------------------------------------
   Buttons and forms inside the sections
   -------------------------------------------------------------------------- */
function setUpSection(id, user) {
  const panel = box.querySelector(`[data-panel="${id}"]`);

  // Save name and interests
  panel.querySelector("[data-details-form]")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const message = form.querySelector("[data-form-message]");
    const name = form.elements.name.value.trim();
    const tags = [...form.querySelectorAll('[name="tag"]:checked')].map((input) => input.value);
    form.querySelector("#account-name-error").textContent = name ? "" : "Please enter your name.";
    if (!name) return;
    if (tags.length < MIN_INTERESTS) {
      message.dataset.type = "error";
      message.textContent = `Please pick at least ${MIN_INTERESTS} interests.`;
      return;
    }
    try {
      const { updateProfile } = await loadAuth();
      const { db, doc, setDoc } = await loadFirestore();
      await updateProfile(user, { displayName: name });
      await setDoc(doc(db, "users", user.uid), { name, tags, onboarding: true, lastActive: new Date().toISOString() }, { merge: true });
      profile = { ...profile, name, tags };
      message.dataset.type = "success";
      message.textContent = "Saved. Your app will show the same details.";
    } catch (error) {
      console.error(error);
      message.dataset.type = "error";
      message.textContent = "Sorry, that didn't save. Please try again.";
    }
  });

  // Verification email
  panel.querySelector("[data-verify-email]")?.addEventListener("click", async (event) => {
    try {
      const { sendEmailVerification } = await loadAuth();
      await sendEmailVerification(user);
      event.target.closest("p").textContent = `Verification email sent to ${user.email}. Click the link in it, then come back here.`;
    } catch (error) {
      console.error(error);
      showToast("Couldn't send the email. Please try again later.");
    }
  });

  // Password reset email (same Cloud Function as the app)
  panel.querySelector("[data-reset-password]")?.addEventListener("click", async (event) => {
    const button = event.currentTarget;
    button.disabled = true;
    try {
      const { functions, httpsCallable } = await loadFunctions();
      await httpsCallable(functions, "sendPasswordReset")({ email: user.email });
      button.insertAdjacentHTML("afterend", `<p class="form-message" data-type="success">Reset link sent to ${escapeHtml(user.email)}.</p>`);
    } catch (error) {
      console.error(error);
      button.disabled = false;
      showToast("Couldn't send the email. Please try again later.");
    }
  });

  panel.querySelector("[data-sign-out-account]")?.addEventListener("click", signOutUser);

  // Save email preferences
  panel.querySelector("[data-emails-form]")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const message = form.querySelector("[data-form-message]");
    const emailPreferences = { offers: form.elements.offers.checked, newsletter: form.elements.newsletter.checked, updates: form.elements.updates.checked, updatedAt: new Date().toISOString() };
    try {
      const { db, doc, setDoc } = await loadFirestore();
      await setDoc(doc(db, "users", user.uid), { emailPreferences }, { merge: true });
      profile.emailPreferences = emailPreferences;
      message.dataset.type = "success";
      message.textContent = "Preferences saved.";
    } catch (error) {
      console.error(error);
      message.dataset.type = "error";
      message.textContent = "Sorry, that didn't save. Please try again.";
    }
  });
}


/* --------------------------------------------------------------------------
   Page layout: section menu + the open section
   -------------------------------------------------------------------------- */
const builders = { details: detailsHtml, favourites: favouritesHtml, rewards: rewardsHtml, emails: emailsHtml };

/* Shows one section (from the # in the address) and builds it the first time. */
async function showSection(user) {
  const id = SECTIONS.some((section) => `#${section.id}` === location.hash) ? location.hash.slice(1) : "details";
  box.querySelectorAll("[data-section-link]").forEach((link) => {
    if (link.dataset.sectionLink === id) link.setAttribute("aria-current", "page");
    else link.removeAttribute("aria-current");
  });
  box.querySelectorAll("[data-panel]").forEach((panel) => {
    panel.hidden = panel.dataset.panel !== id;
  });

  const panel = box.querySelector(`[data-panel="${id}"]`);
  // Favourites are rebuilt each time, as they change often
  if (!panel.dataset.built || id === "favourites") {
    panel.innerHTML = '<p class="detail-loading">Loading…</p>';
    panel.innerHTML = await builders[id](user);
    panel.dataset.built = "yes";
    setUpSection(id, user);
    updateHeartButtons();
  }
}

async function renderMember(user) {
  try {
    const { db, doc, getDoc } = await loadFirestore();
    const snapshot = await getDoc(doc(db, "users", user.uid));
    profile = snapshot.exists() ? snapshot.data() : {};
  } catch (error) {
    console.error("Could not load profile", error);
    profile = {};
  }

  const firstName = (profile.name || user.displayName || "there").split(" ")[0];
  box.innerHTML = `
    <p class="account-hello">Hi ${escapeHtml(firstName)} 👋</p>
    <div class="account-layout">
      <nav class="account-nav" aria-label="Account sections">
        <ul>${SECTIONS.map((section) => `<li><a href="#${section.id}" data-section-link="${section.id}">${section.label}</a></li>`).join("")}</ul>
      </nav>
      <div class="account-panels">
        ${SECTIONS.map((section) => `<section data-panel="${section.id}" aria-label="${section.label}" hidden></section>`).join("")}
      </div>
    </div>`;
  await showSection(user);
}


/* --------------------------------------------------------------------------
   Start: wait to find out if someone is logged in, then draw the page.
   Logging in or out while here redraws it.
   -------------------------------------------------------------------------- */
let current = null;

async function draw(user) {
  current = user;
  if (user) await renderMember(user);
  else await renderGuest();
}

whenAuthReady().then(draw);

document.addEventListener("chillingz:auth", ({ detail: { user } }) => {
  if ((user?.uid ?? null) !== (current?.uid ?? null)) draw(user);
});

window.addEventListener("hashchange", () => {
  if (current) showSection(current);
});

// When the account's favourites finish loading (just after logging in),
// refresh the favourites section if it's the one on screen
document.addEventListener("chillingz:favourites", () => {
  if (current && location.hash === "#favourites") showSection(current);
});
