/* ==========================================================================
   site.js — the shared parts of every page
   --------------------------------------------------------------------------
   Every page loads this one file. It:
     1. draws the header (logo, city switcher, menu, search, login button)
     2. draws the footer
     3. makes the mobile menu, drop-downs and city switcher work
     4. shows the cookie banner the first time someone visits
     5. starts the login system (auth.js) and favourites (favourites.js)

   A page only needs these three placeholders for it all to appear:
     <div data-site-header></div>  <main id="main">…</main>  <div data-site-footer></div>
   ========================================================================== */

import {
  CITIES,
  CATEGORIES,
  MAIN_MENU,
  FOOTER_LINKS,
  LEGAL_LINKS,
  TRUST,
  SITE,
} from "./data.js";
import { storage, escapeHtml, showToast, ICONS } from "./utils.js";
import { initAuth, openAuthModal } from "./auth.js";
import { initFavourites, addRecentSearch } from "./favourites.js";
import { newsletterHtml, initNewsletter } from "./newsletter.js";


/* Works out which page we are on (e.g. "search.html"), used to highlight the
   current menu item. */
function currentPageName() {
  const name = location.pathname.split("/").pop();
  return name === "" ? "index.html" : name;
}


/* --------------------------------------------------------------------------
   City switcher
   The chosen city is remembered in the browser. Other pages read it with
   getCity() to decide which listings to show.
   -------------------------------------------------------------------------- */
export function getCity() {
  const saved = storage.get("chillingz.city");
  return CITIES.some((city) => city.id === saved) ? saved : CITIES[0].id;
}

/* Builds the HTML for one city drop-down. "idSuffix" keeps the ids unique,
   because the switcher appears twice (header and mobile menu). */
function citySwitcherHtml(idSuffix) {
  const selected = getCity();
  const options = CITIES.map(
    (city) =>
      `<option value="${city.id}" ${city.id === selected ? "selected" : ""}>${escapeHtml(city.name)}</option>`,
  ).join("");
  return `
    <div class="city-switcher">
      <label class="visually-hidden" for="city-${idSuffix}">Choose your city</label>
      ${ICONS.pin}
      <select id="city-${idSuffix}" data-city-select>${options}</select>
      ${ICONS.caret}
    </div>`;
}

/* When a city is picked: remember it, keep both drop-downs in step, and tell
   the page so it can reload its listings. */
function setUpCitySwitchers() {
  document.querySelectorAll("[data-city-select]").forEach((select) => {
    select.addEventListener("change", () => {
      storage.set("chillingz.city", select.value);
      document.querySelectorAll("[data-city-select]").forEach((other) => {
        other.value = select.value;
      });
      const city = CITIES.find((item) => item.id === select.value);
      showToast(`Showing ${city.name}`);
      document.dispatchEvent(new CustomEvent("chillingz:city", { detail: city }));
    });
  });
}


/* --------------------------------------------------------------------------
   Header
   -------------------------------------------------------------------------- */

/* Builds the desktop menu, including the mega-menu and small drop-downs. */
function mainMenuHtml() {
  const page = currentPageName();

  const items = MAIN_MENU.map((item, index) => {
    // Big "Explore" panel listing every category
    if (item.megaMenu) {
      const links = CATEGORIES.map(
        (category) => `
          <a href="search.html?category=${category.slug}">
            <strong>${escapeHtml(category.name)}</strong>
            <span>${escapeHtml(category.blurb)}</span>
          </a>`,
      ).join("");
      return `
        <li class="nav-item">
          <button class="nav-link" type="button" aria-expanded="false" aria-controls="menu-panel-${index}" data-dropdown-toggle>
            ${escapeHtml(item.label)} ${ICONS.caret}
          </button>
          <div class="mega-menu" id="menu-panel-${index}" hidden>${links}</div>
        </li>`;
    }

    // Small drop-down, e.g. "Offers"
    if (item.children) {
      const links = item.children
        .map((child) => `<a href="${child.href}">${escapeHtml(child.label)}</a>`)
        .join("");
      return `
        <li class="nav-item">
          <button class="nav-link" type="button" aria-expanded="false" aria-controls="menu-panel-${index}" data-dropdown-toggle>
            ${escapeHtml(item.label)} ${ICONS.caret}
          </button>
          <div class="dropdown-panel" id="menu-panel-${index}" hidden style="left:0;right:auto">${links}</div>
        </li>`;
    }

    // Plain link
    // Highlight the menu item for this page (including its ?category=…)
    const isCurrent = item.href === page + location.search;
    return `
      <li class="nav-item">
        <a class="nav-link" href="${item.href}" ${isCurrent ? 'aria-current="page"' : ""}>${escapeHtml(item.label)}</a>
      </li>`;
  }).join("");

  return `<nav class="main-nav" aria-label="Main menu"><ul>${items}</ul></nav>`;
}

/* Builds the whole header and puts it into <div data-site-header>. */
function renderHeader() {
  const slot = document.querySelector("[data-site-header]");
  if (!slot) return;

  // Keep whatever the visitor last searched for in the box
  const query = new URLSearchParams(location.search).get("q") ?? "";

  slot.outerHTML = `
    <a class="skip-link" href="#main">Skip to content</a>
    <header class="site-header">
      <div class="container header-bar">
        <button class="icon-btn menu-toggle" type="button" aria-label="Open menu" aria-expanded="false" aria-controls="mobile-drawer" data-drawer-open>
          ${ICONS.menu}
        </button>

        <a class="logo" href="index.html" aria-label="Chillingz home">
          <picture>
            <source srcset="images/logo.webp" type="image/webp">
            <img src="images/logo.png" alt="Chillingz" width="288" height="79">
          </picture>
        </a>

        ${citySwitcherHtml("header")}
        ${mainMenuHtml()}

        <div class="header-search">
          <form class="search-form" action="search.html" method="get" role="search" data-search-form>
            <label class="visually-hidden" for="site-search">Search venues and events</label>
            ${ICONS.search}
            <input class="input" id="site-search" name="q" type="search" placeholder="Search bars, events, brunch…" value="${escapeHtml(query)}" autocomplete="off">
          </form>
        </div>

        <!-- auth.js fills this with "Log in / Sign up" or the account menu -->
        <div class="header-account" data-account-slot>
          <button class="btn btn-primary" type="button" data-open-login>
            ${ICONS.user}<span class="btn-label">Log in / Sign up</span>
          </button>
        </div>
      </div>
    </header>

    <div class="drawer-backdrop" hidden data-drawer-backdrop></div>
    <aside class="drawer" id="mobile-drawer" aria-label="Menu" hidden data-drawer>
      <div class="drawer-head">
        <img src="images/logo.png" alt="" width="146" height="40" style="height:32px;width:auto">
        <button class="icon-btn" type="button" aria-label="Close menu" data-drawer-close>${ICONS.close}</button>
      </div>
      <div class="drawer-body">
        ${citySwitcherHtml("drawer")}
        <nav class="drawer-nav" aria-label="Mobile menu">
          <ul>
            <li><a href="index.html">Home</a></li>
            <li><a href="search.html?category=food-drinks">Food &amp; Drink</a></li>
            <li><a href="search.html?category=events">Find Events</a></li>
            <li><a href="search.html">Browse Venues</a></li>
            <li><a href="guides.html">Guides</a></li>
          </ul>
          <p class="drawer-heading">Explore</p>
          <ul>
            ${CATEGORIES.map((category) => `<li><a href="search.html?category=${category.slug}">${escapeHtml(category.name)}</a></li>`).join("")}
          </ul>
          <p class="drawer-heading">Treat yourself</p>
          <ul>
            <li><a href="offers.html">Offers &amp; deals</a></li>
            <li><a href="vouchers.html">Gift vouchers</a></li>
            <li><a href="rewards.html">Rewards</a></li>
          </ul>
        </nav>
        <!-- auth.js fills this with a login button or account links -->
        <div class="drawer-account" data-drawer-account-slot></div>
      </div>
    </aside>`;
}


/* --------------------------------------------------------------------------
   Mobile menu drawer
   -------------------------------------------------------------------------- */

/* Opens and closes the slide-out menu used on phones and tablets. While it is
   open the page behind can't scroll, and Escape or tapping outside closes it. */
function setUpDrawer() {
  const drawer = document.querySelector("[data-drawer]");
  const backdrop = document.querySelector("[data-drawer-backdrop]");
  const openButton = document.querySelector("[data-drawer-open]");
  if (!drawer || !openButton) return;

  function open() {
    drawer.hidden = false;
    backdrop.hidden = false;
    openButton.setAttribute("aria-expanded", "true");
    document.body.classList.add("no-scroll");
    drawer.querySelector("[data-drawer-close]").focus();
  }

  function close() {
    drawer.hidden = true;
    backdrop.hidden = true;
    openButton.setAttribute("aria-expanded", "false");
    document.body.classList.remove("no-scroll");
    openButton.focus();
  }

  openButton.addEventListener("click", open);
  backdrop.addEventListener("click", close);
  drawer.querySelector("[data-drawer-close]").addEventListener("click", close);
  drawer.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
  });

  // Close the drawer when a link inside it is followed or the login opens
  drawer.addEventListener("click", (event) => {
    if (event.target.closest("a, [data-open-login]")) {
      drawer.hidden = true;
      backdrop.hidden = true;
      openButton.setAttribute("aria-expanded", "false");
      document.body.classList.remove("no-scroll");
    }
  });
}


/* --------------------------------------------------------------------------
   Drop-down menus (desktop menu and account menu)
   One click opens a panel; clicking elsewhere or pressing Escape closes it.
   -------------------------------------------------------------------------- */
function closeAllDropdowns(except) {
  document.querySelectorAll("[data-dropdown-toggle]").forEach((toggle) => {
    if (toggle === except) return;
    toggle.setAttribute("aria-expanded", "false");
    const panel = document.getElementById(toggle.getAttribute("aria-controls"));
    if (panel) panel.hidden = true;
  });
}

function setUpDropdowns() {
  // One listener on the whole page handles every drop-down, including ones
  // added later (such as the account menu once someone logs in).
  document.addEventListener("click", (event) => {
    const toggle = event.target.closest("[data-dropdown-toggle]");
    if (toggle) {
      const panel = document.getElementById(toggle.getAttribute("aria-controls"));
      const willOpen = toggle.getAttribute("aria-expanded") !== "true";
      closeAllDropdowns(toggle);
      toggle.setAttribute("aria-expanded", String(willOpen));
      if (panel) panel.hidden = !willOpen;
      return;
    }
    // Click outside any open panel closes them
    if (!event.target.closest(".mega-menu, .dropdown-panel")) {
      closeAllDropdowns();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    const openToggle = document.querySelector('[data-dropdown-toggle][aria-expanded="true"]');
    if (openToggle) {
      closeAllDropdowns();
      openToggle.focus();
    }
  });
}


/* --------------------------------------------------------------------------
   Search box
   Remembers what people search for (shown later as "recent searches").
   -------------------------------------------------------------------------- */
function setUpSearch() {
  document.querySelectorAll("[data-search-form]").forEach((form) => {
    form.addEventListener("submit", () => {
      const text = form.querySelector('input[name="q"]').value.trim();
      if (text) addRecentSearch(text);
    });
  });
}


/* --------------------------------------------------------------------------
   Footer
   -------------------------------------------------------------------------- */
function renderFooter() {
  const slot = document.querySelector("[data-site-footer]");
  if (!slot) return;

  // Review score and press mentions — only shown once real ones are added in data.js
  const hasTrust = TRUST.rating || TRUST.pressMentions.length;
  const trustHtml = hasTrust
    ? `
      <div class="trust-strip">
        ${TRUST.rating ? `
          <p class="trust-score">
            <span class="stars" aria-hidden="true">★★★★★</span>
            <span>Rated ${TRUST.rating}/5 from ${escapeHtml(TRUST.reviewCount)} reviews</span>
          </p>` : ""}
        ${TRUST.pressMentions.length ? `
          <div>
            <p class="visually-hidden">As featured in</p>
            <ul class="press-list">${TRUST.pressMentions.map((name) => `<li>${escapeHtml(name)}</li>`).join("")}</ul>
          </div>` : ""}
      </div>`
    : "";

  const columns = FOOTER_LINKS.map(
    (column) => `
      <div>
        <h2>${escapeHtml(column.heading)}</h2>
        <ul>${column.links.map((link) => `<li><a href="${link.href}">${escapeHtml(link.label)}</a></li>`).join("")}</ul>
      </div>`,
  ).join("");

  const appLinks = appStoreLinksHtml("btn-secondary");

  slot.outerHTML = `
    <footer class="site-footer">
      <div class="container">
        ${newsletterHtml()}
        ${trustHtml}
        <div class="footer-grid">
          <div class="footer-brand">
            <img src="images/logo.png" alt="Chillingz" width="146" height="40" style="height:36px;width:auto;margin-bottom:12px" loading="lazy">
            <p>${escapeHtml(SITE.tagline)}</p>
            ${appLinks ? `<div class="app-badges">${appLinks}</div>` : ""}
          </div>
          ${columns}
        </div>
        <div class="footer-bottom">
          <p>© ${new Date().getFullYear()} ${escapeHtml(SITE.name)}. All rights reserved.</p>
          <ul class="press-list" style="font-weight:400;letter-spacing:0">
            ${LEGAL_LINKS.map((link) => `<li><a href="${link.href}" style="color:inherit">${escapeHtml(link.label)}</a></li>`).join("")}
            <li><button class="link-btn" type="button" data-cookie-settings>Cookie settings</button></li>
          </ul>
        </div>
      </div>
    </footer>`;
}


/* Buttons to the app on the App Store and Google Play (links in SITE in
   data.js). Used in the footer and on the homepage. */
export function appStoreLinksHtml(buttonClass = "btn-secondary") {
  return [
    SITE.appStoreUrl && `<a class="btn ${buttonClass}" href="${escapeHtml(SITE.appStoreUrl)}" rel="noopener" aria-label="Download Chillingz on the App Store">App Store</a>`,
    SITE.playStoreUrl && `<a class="btn ${buttonClass}" href="${escapeHtml(SITE.playStoreUrl)}" rel="noopener" aria-label="Get Chillingz on Google Play">Google Play</a>`,
  ].filter(Boolean).join("");
}


/* --------------------------------------------------------------------------
   Cookie banner
   The site itself only uses "essential" browser storage (your city, your
   guest favourites, your login). Nothing non-essential is loaded unless the
   visitor clicks "Accept all", so "Decline" really does mean no tracking.
   Other code can check hasAnalyticsConsent() before adding analytics later.
   -------------------------------------------------------------------------- */
export function hasAnalyticsConsent() {
  return storage.get("chillingz.cookieConsent") === "accepted";
}

function showCookieBanner() {
  let banner = document.getElementById("cookie-banner");
  if (!banner) {
    banner = document.createElement("section");
    banner.id = "cookie-banner";
    banner.className = "cookie-banner";
    banner.setAttribute("aria-label", "Cookie choices");
    banner.innerHTML = `
      <h2>Cookies on Chillingz</h2>
      <p>We use essential storage to remember your city, favourites and login.
        With your OK we'd also like to use analytics cookies to improve the site.
        <a href="cookies.html">Read our cookie policy</a>.</p>
      <div class="cookie-actions">
        <button class="btn btn-secondary" type="button" data-cookie-choice="declined">Decline</button>
        <button class="btn btn-primary" type="button" data-cookie-choice="accepted">Accept all</button>
      </div>`;
    document.body.append(banner);

    banner.addEventListener("click", (event) => {
      const button = event.target.closest("[data-cookie-choice]");
      if (!button) return;
      storage.set("chillingz.cookieConsent", button.dataset.cookieChoice);
      banner.hidden = true;
      showToast(button.dataset.cookieChoice === "accepted" ? "Thanks — cookies accepted" : "Got it — only essential cookies");
    });
  }
  banner.hidden = false;
}

function setUpCookieBanner() {
  if (!storage.get("chillingz.cookieConsent")) {
    showCookieBanner();
  }
  // "Cookie settings" link in the footer lets people change their mind
  document.addEventListener("click", (event) => {
    if (event.target.closest("[data-cookie-settings]")) showCookieBanner();
  });
}


/* --------------------------------------------------------------------------
   Start everything
   -------------------------------------------------------------------------- */
renderHeader();
renderFooter();
setUpCitySwitchers();
setUpDrawer();
setUpDropdowns();
setUpSearch();
setUpCookieBanner();
initFavourites();
initNewsletter();
initAuth();

// Bookings used to be remembered on the visitor's device. The website no
// longer takes bookings, so tidy away any copies left from before.
storage.remove("chillingz.guestBookings");

// Offline support: register the service worker (see sw.js). Browsers only
// allow this on https:// addresses and on localhost.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("sw.js").catch((error) => console.error("Offline support not available", error));
  });
}

// Any button with data-open-login (anywhere on any page) opens the login
// pop-up. data-open-login="signup" opens it on the sign-up tab instead.
document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-open-login]");
  if (button) {
    openAuthModal(button.dataset.openLogin === "signup" ? "signup" : "login");
  }
});
