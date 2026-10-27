/* ==========================================================================
   auth.js — logging in, signing up and the account menu
   --------------------------------------------------------------------------
   All the real security (passwords, Google sign-in, reset emails) is done by
   Firebase Authentication — the same accounts your app uses. This file only
   draws the pop-up and passes what people type to Firebase.

   What it does:
   • Shows "Log in / Sign up" in the header, or the account menu once logged in
   • Opens the login pop-up on top of the current page, so visitors never
     lose their place. When they finish, the pop-up closes and they carry on.
   • Log in and sign up with email + password, "Continue with Google", and
     "Forgot password"
   • After a first sign-up, asks for interests — the same step as the app
   • Creates the same user record in Firebase that the app creates, so the
     account works in both places
   ========================================================================== */

import { loadAuth, loadFirestore, loadFunctions } from "./firebase.js";
import { onUserChanged } from "./favourites.js";
import { escapeHtml, showToast, ICONS } from "./utils.js";

// The app asks new users to pick at least this many interests
const MIN_INTERESTS = 3;

// The logged-in person (a Firebase "user"), or null for a guest
let currentUser = null;

// The pop-up element, created the first time it is needed
let dialog = null;

// If someone tries Google but already has a password account with that
// email, we keep Google's answer here until they log in with their password,
// then join the two together.
let pendingGoogleCredential = null;


/* --------------------------------------------------------------------------
   Public functions other files use
   -------------------------------------------------------------------------- */

// Resolves once Firebase has said whether someone is logged in (this takes a
// moment after the page opens). Pages like My Account wait for it.
let markAuthReady;
const authReady = new Promise((resolve) => {
  markAuthReady = resolve;
});

/* Waits until we know who is logged in, then gives back the user (or null). */
export function whenAuthReady() {
  return authReady;
}

/* Who is logged in right now (null for a guest). */
export function getCurrentUser() {
  return currentUser;
}

/* Starts watching for log in / log out. Called once by site.js.
   Firebase remembers logins between visits, so returning members are logged
   in again automatically. */
export async function initAuth() {
  renderAccountArea(null);
  try {
    const { auth, onAuthStateChanged, getRedirectResult } = await loadAuth();

    // If Google sign-in had to use a full-page redirect (some phones block
    // pop-ups), finish it off here when the visitor comes back.
    getRedirectResult(auth)
      .then((result) => {
        if (result?.user) afterSignIn(result.user, { method: "google" });
      })
      .catch((error) => console.error("Google redirect sign-in failed", error));

    onAuthStateChanged(auth, (user) => {
      currentUser = user;
      markAuthReady(user);
      renderAccountArea(user);
      onUserChanged(user);
      // Tell any page that cares (e.g. My Account) that the login changed
      document.dispatchEvent(new CustomEvent("chillingz:auth", { detail: { user } }));
    });
  } catch (error) {
    console.error("Could not start login system", error);
    markAuthReady(null);
  }
}

/* Opens the login pop-up. mode is "login", "signup" or "forgot".
   "message" is an optional line shown at the top, e.g. why we're asking.
   "prefill" can fill in the name and email, e.g. after a guest booking. */
export function openAuthModal(mode = "login", { message = "", prefill = null } = {}) {
  buildDialog();
  showPanel(mode);
  if (prefill) {
    const signupForm = dialog.querySelector('[data-form="signup"]');
    signupForm.elements.name.value = prefill.name ?? "";
    signupForm.elements.email.value = prefill.email ?? "";
    dialog.querySelector('[data-form="login"]').elements.email.value = prefill.email ?? "";
  }
  const intro = dialog.querySelector("[data-auth-intro]");
  intro.textContent = message;
  intro.hidden = !message;
  if (!dialog.open) dialog.showModal();
  // Put the cursor in the first box so people can start typing straight away
  dialog.querySelector(`[data-panel="${mode}"] input`)?.focus();
}

/* Logs the visitor out and goes back to being a guest. */
export async function signOutUser() {
  const { auth, signOut } = await loadAuth();
  await signOut(auth);
  showToast("You're logged out");
}


/* --------------------------------------------------------------------------
   Header account area
   Shows the login button for guests, or a small menu for members.
   -------------------------------------------------------------------------- */
function renderAccountArea(user) {
  const slot = document.querySelector("[data-account-slot]");
  const drawerSlot = document.querySelector("[data-drawer-account-slot]");

  // Guest: a normal "Log in / Sign up" button. No pop-up opens by itself.
  if (!user) {
    if (slot) {
      slot.innerHTML = `
        <button class="btn btn-primary" type="button" data-open-login>
          ${ICONS.user}<span class="btn-label">Log in / Sign up</span>
        </button>`;
    }
    if (drawerSlot) {
      drawerSlot.innerHTML = `
        <button class="btn btn-primary btn-block" type="button" data-open-login>Log in / Sign up</button>
        <p class="small-print" style="margin-top:8px">Optional — you can browse and book as a guest.</p>`;
    }
    return;
  }

  // Member: their picture (or an icon) that opens the account menu
  const name = user.displayName || user.email || "there";
  const firstName = name.split(" ")[0];
  const picture = user.photoURL
    ? `<img class="account-avatar" src="${escapeHtml(user.photoURL)}" alt="" width="32" height="32" referrerpolicy="no-referrer">`
    : ICONS.user;

  const accountLinks = `
    <a href="account.html#details">My details</a>
    <a href="account.html#bookings">My bookings</a>
    <a href="account.html#favourites">My favourites</a>
    <a href="account.html#rewards">My rewards</a>
    <a href="account.html#emails">Email preferences</a>`;

  if (slot) {
    slot.innerHTML = `
      <div class="account-menu">
        <button class="icon-btn" type="button" aria-label="Account menu for ${escapeHtml(firstName)}" aria-expanded="false" aria-controls="account-panel" data-dropdown-toggle>
          ${picture}
        </button>
        <div class="dropdown-panel" id="account-panel" hidden>
          <p class="dropdown-greeting">Hi ${escapeHtml(firstName)}</p>
          ${accountLinks}
          <button type="button" data-sign-out>Log out</button>
        </div>
      </div>`;
  }
  if (drawerSlot) {
    drawerSlot.innerHTML = `
      <p class="drawer-heading">Hi ${escapeHtml(firstName)}</p>
      <nav class="drawer-nav" aria-label="Account"><ul>
        <li><a href="account.html#details">My account</a></li>
        <li><a href="account.html#bookings">My bookings</a></li>
        <li><a href="account.html#favourites">My favourites</a></li>
      </ul></nav>
      <button class="btn btn-secondary btn-block" type="button" data-sign-out style="margin-top:16px">Log out</button>`;
  }
}

// Any "Log out" button on the page
document.addEventListener("click", (event) => {
  if (event.target.closest("[data-sign-out]")) signOutUser();
});


/* --------------------------------------------------------------------------
   The pop-up itself
   It uses the browser's built-in <dialog>, which already handles the
   keyboard (Tab stays inside, Escape closes it) and screen readers.
   -------------------------------------------------------------------------- */
function buildDialog() {
  if (dialog) return;

  dialog = document.createElement("dialog");
  dialog.className = "modal";
  dialog.setAttribute("aria-labelledby", "auth-title");
  dialog.innerHTML = `
    <div class="modal-inner">
      <button class="icon-btn modal-close" type="button" aria-label="Close" data-close-modal>${ICONS.close}</button>
      <h2 class="modal-title" id="auth-title">Welcome to Chillingz</h2>
      <p class="modal-subtitle" data-auth-intro hidden></p>

      <!-- Tabs: switch between logging in and signing up -->
      <div class="auth-tabs" role="tablist" data-auth-tabs>
        <button class="auth-tab" type="button" role="tab" id="tab-login" aria-controls="panel-login" data-show-panel="login">Log in</button>
        <button class="auth-tab" type="button" role="tab" id="tab-signup" aria-controls="panel-signup" data-show-panel="signup">Sign up</button>
      </div>

      <!-- LOG IN -->
      <div class="auth-panel" id="panel-login" role="tabpanel" aria-labelledby="tab-login" data-panel="login">
        <form novalidate data-form="login">
          <div class="field">
            <label for="login-email">Email</label>
            <input class="input" id="login-email" name="email" type="email" autocomplete="email" required>
            <p class="field-error" id="login-email-error"></p>
          </div>
          <div class="field">
            <label for="login-password">Password</label>
            <div class="password-wrap">
              <input class="input" id="login-password" name="password" type="password" autocomplete="current-password" required>
              <button class="icon-btn" type="button" aria-label="Show password" aria-pressed="false" data-toggle-password>${ICONS.eye}</button>
            </div>
            <p class="field-error" id="login-password-error"></p>
          </div>
          <div class="auth-footer-row">
            <button class="link-btn" type="button" data-show-panel="forgot">Forgot password?</button>
          </div>
          <p class="form-message" role="alert" data-form-message></p>
          <button class="btn btn-primary btn-block" type="submit">Log in</button>
        </form>
        <div class="auth-divider">or</div>
        <button class="btn btn-google" type="button" data-google>${ICONS.google} Continue with Google</button>
      </div>

      <!-- SIGN UP -->
      <div class="auth-panel" id="panel-signup" role="tabpanel" aria-labelledby="tab-signup" data-panel="signup" hidden>
        <form novalidate data-form="signup">
          <div class="field">
            <label for="signup-name">Name</label>
            <input class="input" id="signup-name" name="name" type="text" autocomplete="name" required>
            <p class="field-error" id="signup-name-error"></p>
          </div>
          <div class="field">
            <label for="signup-email">Email</label>
            <input class="input" id="signup-email" name="email" type="email" autocomplete="email" required>
            <p class="field-error" id="signup-email-error"></p>
          </div>
          <div class="field">
            <label for="signup-password">Password</label>
            <div class="password-wrap">
              <input class="input" id="signup-password" name="password" type="password" autocomplete="new-password" minlength="6" required aria-describedby="signup-password-hint">
              <button class="icon-btn" type="button" aria-label="Show password" aria-pressed="false" data-toggle-password>${ICONS.eye}</button>
            </div>
            <p class="small-print" id="signup-password-hint" style="margin:0">At least 6 characters.</p>
            <p class="field-error" id="signup-password-error"></p>
          </div>
          <label class="checkbox-row">
            <input type="checkbox" name="terms" required aria-describedby="signup-terms-error">
            <span>I agree to the <a href="terms.html" target="_blank" rel="noopener">Terms &amp; Conditions</a> and <a href="privacy.html" target="_blank" rel="noopener">Privacy Policy</a></span>
          </label>
          <p class="field-error" id="signup-terms-error"></p>
          <p class="form-message" role="alert" data-form-message></p>
          <button class="btn btn-primary btn-block" type="submit">Create account</button>
        </form>
        <div class="auth-divider">or</div>
        <button class="btn btn-google" type="button" data-google>${ICONS.google} Continue with Google</button>
        <p class="small-print" style="margin-top:12px">Your account also works in the Chillingz app.</p>
      </div>

      <!-- FORGOT PASSWORD -->
      <div class="auth-panel" data-panel="forgot" hidden>
        <p>Enter your email and we'll send you a link to reset your password.</p>
        <form novalidate data-form="forgot">
          <div class="field">
            <label for="forgot-email">Email</label>
            <input class="input" id="forgot-email" name="email" type="email" autocomplete="email" required>
            <p class="field-error" id="forgot-email-error"></p>
          </div>
          <p class="form-message" role="alert" data-form-message></p>
          <button class="btn btn-primary btn-block" type="submit">Send reset link</button>
        </form>
        <p style="margin-top:16px"><button class="link-btn" type="button" data-show-panel="login">Back to log in</button></p>
      </div>

      <!-- INTERESTS (shown once, after a first sign-up — same as the app) -->
      <div class="auth-panel" data-panel="interests" hidden>
        <p>Pick at least ${MIN_INTERESTS} things you're into and we'll tailor your suggestions.</p>
        <form novalidate data-form="interests">
          <fieldset style="border:0;padding:0;margin:0">
            <legend class="visually-hidden">Your interests</legend>
            <div class="interest-grid" data-interest-list><p class="small-print">Loading…</p></div>
          </fieldset>
          <p class="form-message" role="alert" data-form-message></p>
          <button class="btn btn-primary btn-block" type="submit">Save interests</button>
        </form>
        <p style="margin-top:12px;text-align:center"><button class="link-btn" type="button" data-close-modal>Skip for now</button></p>
      </div>
    </div>`;

  document.body.append(dialog);

  // Close button, "Skip for now", and clicking the dark area outside the box
  dialog.addEventListener("click", (event) => {
    if (event.target.closest("[data-close-modal]") || event.target === dialog) {
      dialog.close();
    }
  });

  // Switching between log in / sign up / forgot password
  dialog.addEventListener("click", (event) => {
    const button = event.target.closest("[data-show-panel]");
    if (button) {
      showPanel(button.dataset.showPanel);
      dialog.querySelector(`[data-panel="${button.dataset.showPanel}"] input`)?.focus();
    }
  });

  // The eye button that shows or hides the password
  dialog.addEventListener("click", (event) => {
    const button = event.target.closest("[data-toggle-password]");
    if (!button) return;
    const input = button.parentElement.querySelector("input");
    const showing = input.type === "text";
    input.type = showing ? "password" : "text";
    button.setAttribute("aria-pressed", String(!showing));
    button.setAttribute("aria-label", showing ? "Show password" : "Hide password");
  });

  // "Continue with Google" buttons
  dialog.querySelectorAll("[data-google]").forEach((button) => {
    button.addEventListener("click", () => signInWithGoogle(button));
  });

  // The four forms
  dialog.querySelector('[data-form="login"]').addEventListener("submit", handleLogin);
  dialog.querySelector('[data-form="signup"]').addEventListener("submit", handleSignup);
  dialog.querySelector('[data-form="forgot"]').addEventListener("submit", handleForgot);
  dialog.querySelector('[data-form="interests"]').addEventListener("submit", handleInterests);
}

/* Shows one part of the pop-up (login, signup, forgot or interests) and
   hides the rest. The tabs only appear for log in and sign up. */
function showPanel(name) {
  const titles = {
    login: "Welcome back",
    signup: "Create your account",
    forgot: "Reset your password",
    interests: "What are you into?",
  };
  dialog.querySelector("#auth-title").textContent = titles[name];
  dialog.querySelectorAll("[data-panel]").forEach((panel) => {
    panel.hidden = panel.dataset.panel !== name;
  });
  dialog.querySelector("[data-auth-tabs]").hidden = !(name === "login" || name === "signup");
  dialog.querySelectorAll("[data-show-panel].auth-tab").forEach((tab) => {
    tab.setAttribute("aria-selected", String(tab.dataset.showPanel === name));
  });
  if (name !== "interests") {
    const intro = dialog.querySelector("[data-auth-intro]");
    intro.hidden = !intro.textContent;
  }
}


/* --------------------------------------------------------------------------
   Form checking (before anything is sent to Firebase)
   -------------------------------------------------------------------------- */

/* Shows (or clears) the red message under one field. */
function setFieldError(form, fieldName, message) {
  const input = form.elements[fieldName];
  const errorId = `${input.id}-error`;
  input.setAttribute("aria-invalid", message ? "true" : "false");
  form.querySelector(`#${errorId}`).textContent = message;
  // Link the message to the box so screen readers read it out
  const describedBy = (input.getAttribute("aria-describedby") ?? "").split(" ").filter(Boolean);
  if (!describedBy.includes(errorId)) {
    input.setAttribute("aria-describedby", [...describedBy, errorId].join(" "));
  }
}

/* Shows a message for the whole form (e.g. "Wrong password"). */
function setFormMessage(form, message, type = "error") {
  const box = form.querySelector("[data-form-message]");
  box.textContent = message;
  box.dataset.type = type;
}

/* Turns the submit button into a "please wait" state and back. */
function setBusy(form, busy) {
  const button = form.querySelector('[type="submit"]');
  if (!button.dataset.label) button.dataset.label = button.textContent;
  button.disabled = busy;
  button.textContent = busy ? "Please wait…" : button.dataset.label;
}

/* A simple, reliable email check: something@something.something */
function looksLikeEmail(text) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text);
}

/* Turns Firebase's technical error codes into plain English. */
function friendlyError(error) {
  const messages = {
    "auth/invalid-credential": "That email and password don't match. Please try again.",
    "auth/wrong-password": "That email and password don't match. Please try again.",
    "auth/user-not-found": "That email and password don't match. Please try again.",
    "auth/email-already-in-use": "There's already an account with this email. Try logging in instead.",
    "auth/weak-password": "Please choose a password with at least 6 characters.",
    "auth/invalid-email": "Please enter a valid email address.",
    "auth/too-many-requests": "Too many attempts. Please wait a few minutes and try again.",
    "auth/network-request-failed": "No internet connection. Please check it and try again.",
    "auth/popup-closed-by-user": "Google sign-in was closed before it finished.",
    "auth/unauthorized-domain": "Login isn't switched on for this web address yet. Please try again later.",
    "auth/operation-not-allowed": "This way of logging in isn't switched on yet.",
  };
  return messages[error?.code] ?? "Something went wrong. Please try again.";
}


/* --------------------------------------------------------------------------
   Log in with email and password
   -------------------------------------------------------------------------- */
async function handleLogin(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const email = form.elements.email.value.trim();
  const password = form.elements.password.value;

  // Check the boxes are filled in properly first
  setFieldError(form, "email", looksLikeEmail(email) ? "" : "Please enter a valid email address.");
  setFieldError(form, "password", password ? "" : "Please enter your password.");
  setFormMessage(form, "");
  if (!looksLikeEmail(email) || !password) return;

  setBusy(form, true);
  try {
    const { auth, signInWithEmailAndPassword } = await loadAuth();
    const { user } = await signInWithEmailAndPassword(auth, email, password);
    await afterSignIn(user, { method: "password" });
  } catch (error) {
    setFormMessage(form, friendlyError(error));
  } finally {
    setBusy(form, false);
  }
}


/* --------------------------------------------------------------------------
   Sign up with email and password
   -------------------------------------------------------------------------- */
async function handleSignup(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const name = form.elements.name.value.trim();
  const email = form.elements.email.value.trim();
  const password = form.elements.password.value;
  const agreed = form.elements.terms.checked;

  const errors = {
    name: name ? "" : "Please enter your name.",
    email: looksLikeEmail(email) ? "" : "Please enter a valid email address.",
    password: password.length >= 6 ? "" : "Please choose a password with at least 6 characters.",
  };
  Object.entries(errors).forEach(([field, message]) => setFieldError(form, field, message));
  form.querySelector("#signup-terms-error").textContent = agreed ? "" : "Please agree to the terms to continue.";
  setFormMessage(form, "");
  if (Object.values(errors).some(Boolean) || !agreed) return;

  setBusy(form, true);
  try {
    const { auth, createUserWithEmailAndPassword, updateProfile } = await loadAuth();
    const { user } = await createUserWithEmailAndPassword(auth, email, password);
    await updateProfile(user, { displayName: name });
    await createUserRecord(user, name);
    await afterSignIn(user, { method: "password", isNew: true });
  } catch (error) {
    setFormMessage(form, friendlyError(error));
  } finally {
    setBusy(form, false);
  }
}


/* --------------------------------------------------------------------------
   Continue with Google
   Opens Google's own sign-in window. If the browser blocks pop-ups (common on
   phones), it switches to a full-page redirect and comes back here after.
   -------------------------------------------------------------------------- */
async function signInWithGoogle(button) {
  const form = button.closest("[data-panel]").querySelector("form");
  setFormMessage(form, "");
  button.disabled = true;

  try {
    const { auth, GoogleAuthProvider, signInWithPopup, signInWithRedirect } = await loadAuth();
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });

    try {
      const result = await signInWithPopup(auth, provider);
      await afterSignIn(result.user, { method: "google" });
    } catch (error) {
      if (error.code === "auth/popup-blocked" || error.code === "auth/operation-not-supported-in-this-environment") {
        await signInWithRedirect(auth, provider);
        return;
      }
      throw error;
    }
  } catch (error) {
    if (error.code === "auth/account-exists-with-different-credential") {
      // The email already has an account that uses a password. Ask them to
      // log in with it once; Google is then linked to that same account.
      const { GoogleAuthProvider } = await loadAuth();
      pendingGoogleCredential = GoogleAuthProvider.credentialFromError(error);
      showPanel("login");
      const loginForm = dialog.querySelector('[data-form="login"]');
      loginForm.elements.email.value = error.customData?.email ?? "";
      setFormMessage(loginForm, "You already have an account with this email. Log in with your password and we'll link Google to it.");
      loginForm.elements.password.focus();
      return;
    }
    setFormMessage(form, friendlyError(error));
  } finally {
    button.disabled = false;
  }
}


/* --------------------------------------------------------------------------
   Forgot password
   Uses the same "sendPasswordReset" Cloud Function as the app, so the email
   looks the same whichever one people use.
   -------------------------------------------------------------------------- */
async function handleForgot(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const email = form.elements.email.value.trim();

  setFieldError(form, "email", looksLikeEmail(email) ? "" : "Please enter a valid email address.");
  setFormMessage(form, "");
  if (!looksLikeEmail(email)) return;

  setBusy(form, true);
  try {
    const { functions, httpsCallable } = await loadFunctions();
    await httpsCallable(functions, "sendPasswordReset")({ email });
    // Same message whether or not the email has an account, for privacy
    setFormMessage(form, "If there's an account for that email, a reset link is on its way. Check your inbox.", "success");
  } catch (error) {
    console.error("Password reset failed", error);
    setFormMessage(form, "We couldn't send the email just now. Please try again in a moment.");
  } finally {
    setBusy(form, false);
  }
}


/* --------------------------------------------------------------------------
   After a successful log in or sign up
   -------------------------------------------------------------------------- */

/* Makes sure the person has a user record, records the login like the app
   does, then either asks for interests (new people) or closes the pop-up so
   they're back exactly where they were. */
async function afterSignIn(user, { method, isNew = false }) {
  let needsInterests = isNew;

  try {
    const { db, doc, getDoc, setDoc } = await loadFirestore();
    const userRef = doc(db, "users", user.uid);
    const snapshot = await getDoc(userRef);

    // First time this person has logged in anywhere (e.g. first Google login)
    if (!snapshot.exists()) {
      await createUserRecord(user, user.displayName ?? "");
      needsInterests = true;
    } else if (!snapshot.data().onboarding) {
      needsInterests = true;
    }

    // Record the login, with the same fields the app writes
    const now = new Date();
    await setDoc(userRef, {
      lastActive: now.toISOString(),
      loginAt: now.toISOString(),
      loginDate: now.getDate(),
      loginMonth: now.getMonth() + 1,
      loginYear: now.getFullYear(),
      loginDateLabel: now.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" }),
    }, { merge: true });
  } catch (error) {
    // Logging in still worked; only the extra details failed to save
    console.error("Could not update user record", error);
  }

  if (method === "password") await linkPendingGoogle(user);

  if (needsInterests) {
    buildDialog();
    if (!dialog.open) dialog.showModal();
    showPanel("interests");
    loadInterestChoices();
    return;
  }

  dialog?.close();
  showToast(`Welcome${user.displayName ? `, ${user.displayName.split(" ")[0]}` : ""}!`);
}

/* Creates the user record with exactly the same fields the app creates
   (see Chillingz-main/lib/features/auth/providers/auth_provider.dart). */
async function createUserRecord(user, name) {
  const { db, doc, setDoc } = await loadFirestore();
  const now = new Date().toISOString();
  const email = user.email ?? "";
  await setDoc(doc(db, "users", user.uid), {
    authUid: user.uid,
    avatarUrl: user.photoURL ?? `https://i.pravatar.cc/96?u=${encodeURIComponent(email)}`,
    city: "London",
    createdAt: now,
    email,
    id: `usr-${user.uid.slice(0, 8)}`,
    lastActive: now,
    name,
    notes: "",
    onboarding: false,
    tags: [],
    signedUpOn: "web",
  }, { merge: true });
}

/* If someone tried Google first and was told to log in with their password,
   link Google to their account now so next time either way works. */
async function linkPendingGoogle(user) {
  if (!pendingGoogleCredential) return;
  const credential = pendingGoogleCredential;
  pendingGoogleCredential = null;
  try {
    const { linkWithCredential } = await loadAuth();
    await linkWithCredential(user, credential);
    showToast("Google is now linked to your account");
  } catch (error) {
    console.error("Could not link Google", error);
  }
}


/* --------------------------------------------------------------------------
   Interests (first sign-up only)
   The choices come from the "tags" list in Firebase, the same list the app
   shows, and are saved in the same way.
   -------------------------------------------------------------------------- */
async function loadInterestChoices() {
  const list = dialog.querySelector("[data-interest-list]");
  try {
    const { db, collection, getDocs } = await loadFirestore();
    const snapshot = await getDocs(collection(db, "tags"));
    const labels = snapshot.docs
      .map((tagDoc) => tagDoc.data())
      .filter((tag) => !tag.status || String(tag.status).toLowerCase() === "active")
      .map((tag) => String(tag.tagName || tag.name || tag.title || tag.slug || "").trim())
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b));

    list.innerHTML = labels
      .map((label) => `
        <label>
          <input type="checkbox" name="interest" value="${escapeHtml(label)}">
          <span>${escapeHtml(label)}</span>
        </label>`)
      .join("");
  } catch (error) {
    console.error("Could not load interests", error);
    list.innerHTML = '<p class="small-print">We couldn\'t load the list. You can choose your interests later in My Account.</p>';
  }
}

async function handleInterests(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const chosen = [...form.querySelectorAll('input[name="interest"]:checked')].map((input) => input.value);

  if (chosen.length < MIN_INTERESTS) {
    setFormMessage(form, `Please pick at least ${MIN_INTERESTS}.`);
    return;
  }

  setBusy(form, true);
  try {
    const { auth } = await loadAuth();
    const { db, doc, setDoc } = await loadFirestore();
    await setDoc(doc(db, "users", auth.currentUser.uid), {
      tags: chosen,
      onboarding: true,
      lastActive: new Date().toISOString(),
    }, { merge: true });
    dialog.close();
    showToast("Thanks! Your suggestions are now tailored to you.");
  } catch (error) {
    setFormMessage(form, friendlyError(error));
  } finally {
    setBusy(form, false);
  }
}
