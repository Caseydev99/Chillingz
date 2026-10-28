/* ==========================================================================
   home.js — fills in the homepage
   --------------------------------------------------------------------------
   The homepage HTML already has the headings and empty boxes. This file
   loads the listings (content.js) and puts cards into each box:
     categories, Trending, Top 10, New on Chillingz, Hot events, Guides,
     the photo gallery and the offers tiles.
   When the visitor picks another city in the header, it all redraws.
   ========================================================================== */

import { HOME, GUIDES, PROMOS, CATEGORIES, CITIES } from "./data.js";
import { escapeHtml } from "./utils.js";
import { getCity } from "./site.js";
import { getRecentSearches, updateHeartButtons } from "./favourites.js";
import { loadContent, listingsForCity, inCategory, trending, newest, eventTickets, topRated, guideListings, detailUrl } from "./content.js";
import { cardRow, listingImage } from "./cards.js";

/* Shortcut: find one element on the page. */
const $ = (selector) => document.querySelector(selector);


/* --------------------------------------------------------------------------
   Hero: words, quick-search buttons and recent searches
   -------------------------------------------------------------------------- */
function renderHero() {
  document.querySelectorAll("[data-home-text]").forEach((element) => {
    element.textContent = HOME[element.dataset.homeText];
  });

  // Recent searches (from this visitor) come first, then the suggestions
  const recent = getRecentSearches().slice(0, 3);
  const suggestions = HOME.quickSearches.filter(
    (text) => !recent.some((item) => item.toLowerCase() === text.toLowerCase()),
  );
  const chip = (text, isRecent) =>
    `<a class="quick-chip ${isRecent ? "is-recent" : ""}" href="search.html?q=${encodeURIComponent(text)}">${isRecent ? '<span class="visually-hidden">Recent search: </span>↺ ' : ""}${escapeHtml(text)}</a>`;

  $("[data-quick-searches]").innerHTML = [
    ...recent.map((text) => chip(text, true)),
    ...suggestions.map((text) => chip(text, false)),
  ].join("");
}


/* --------------------------------------------------------------------------
   Category cards
   The photo for each category comes from Firebase (via the export); the
   name and short description come from data.js.
   -------------------------------------------------------------------------- */
function renderCategories(content, listings) {
  const items = CATEGORIES.map((category) => {
    const fromFirebase = content.categories.find((item) => item.slug === category.slug);
    // If the category has no photo of its own, borrow one from its listings
    const fallback = listings.find((listing) => listing.category === category.slug && listing.image);
    const image = fromFirebase?.image ?? fallback?.image;
    const count = listings.filter((listing) => inCategory(listing, category.slug)).length;

    return `
      <li>
        <a class="category-card" href="search.html?category=${category.slug}">
          ${image ? listingImage({ image }, { sizes: "(min-width: 1024px) 16vw, (min-width: 600px) 30vw, 45vw" }) : '<div class="card-media card-media-empty"></div>'}
          <span class="category-label">
            <strong>${escapeHtml(category.name)}</strong>
            <span>${count ? `${count} ${count === 1 ? "place" : "places"}` : "Coming soon"}</span>
          </span>
        </a>
      </li>`;
  });
  $("[data-categories]").innerHTML = items.join("");
}


/* --------------------------------------------------------------------------
   Guides: the first three guides that have listings
   -------------------------------------------------------------------------- */
function renderGuides(listings) {
  const guides = GUIDES
    .map((guide) => ({ guide, picks: guideListings(guide, listings) }))
    .filter(({ picks }) => picks.length >= 2)
    .slice(0, 3);

  // Give each guide a different cover photo where possible
  const usedPhotos = new Set();
  $("[data-guides]").innerHTML = guides
    .map(({ guide, picks }) => {
      const cover = picks.find((item) => item.image && !usedPhotos.has(item.image.fingerprint))
        ?? picks.find((item) => item.image) ?? {};
      if (cover.image) usedPhotos.add(cover.image.fingerprint);
      return `
      <li>
        <article class="guide-card">
          ${listingImage(cover, { sizes: "(min-width: 1024px) 33vw, 90vw" })}
          <div class="card-body">
            <p class="chip">${picks.length} picks</p>
            <h3 class="card-title"><a href="article.html?guide=${guide.slug}">${escapeHtml(guide.title)}</a></h3>
            <p class="card-details">${escapeHtml(guide.intro)}</p>
          </div>
        </article>
      </li>`;
    })
    .join("");
}


/* --------------------------------------------------------------------------
   Photo gallery: a mosaic of the best photos, each linking to its listing
   -------------------------------------------------------------------------- */
function renderGallery(listings) {
  // Skip listings already shown in "Trending", and photos already used
  // (several listings in Firebase share the same photo)
  const shown = new Set(trending(listings, 8).map((listing) => listing.id));
  const usedPhotos = new Set();
  const photos = trending(listings, 200).filter((listing) => {
    if (!listing.image || shown.has(listing.id) || usedPhotos.has(listing.image.fingerprint)) return false;
    usedPhotos.add(listing.image.fingerprint);
    return true;
  }).slice(0, 5);
  $("[data-gallery]").innerHTML = photos
    .map((listing, index) => `
      <li class="${index === 0 ? "gallery-large" : ""}">
        <a href="${detailUrl(listing)}">
          ${listingImage(listing, { sizes: index === 0 ? "(min-width: 768px) 50vw, 100vw" : "(min-width: 768px) 25vw, 50vw" })}
          <span class="gallery-caption">${escapeHtml(listing.title)}</span>
        </a>
      </li>`)
    .join("");
}


/* --------------------------------------------------------------------------
   Offers, vouchers and rewards tiles (from data.js)
   -------------------------------------------------------------------------- */
function renderPromos() {
  $("[data-promos]").innerHTML = PROMOS
    .map((promo) => `
      <li class="promo-card">
        <h3>${escapeHtml(promo.title)}</h3>
        <p>${escapeHtml(promo.text)}</p>
        <a class="btn btn-secondary" href="${promo.href}">${escapeHtml(promo.cta)}</a>
      </li>`)
    .join("");
}


/* --------------------------------------------------------------------------
   Put it all together
   -------------------------------------------------------------------------- */
async function renderListings() {
  const city = CITIES.find((item) => item.id === getCity());
  document.querySelectorAll("[data-city-name]").forEach((element) => {
    element.textContent = city.name;
  });

  try {
    const content = await loadContent();
    const listings = await listingsForCity(city.id);

    // A city with nothing yet shows a friendly "coming soon" message instead
    const isEmpty = listings.length === 0;
    $("[data-city-empty]").hidden = !isEmpty;
    $("[data-city-content]").hidden = isEmpty;
    if (isEmpty) return;

    renderCategories(content, listings);
    $('[data-row="trending"]').innerHTML = cardRow(trending(listings, 8), { id: "trending-title" });
    $('[data-row="top10"]').innerHTML = cardRow(topRated(listings), { id: "top10-title", rankStart: 1 });
    $('[data-row="new"]').innerHTML = cardRow(newest(listings, 8), { id: "new-title" });
    $('[data-row="events"]').innerHTML = cardRow(eventTickets(listings, 8), { id: "events-title" });
    renderGuides(listings);
    renderGallery(listings);
    updateHeartButtons();
  } catch (error) {
    console.error(error);
    document.querySelectorAll(".row-slot").forEach((slot) => {
      slot.innerHTML = '<p class="empty-note">We couldn\'t load listings just now. Please refresh the page.</p>';
    });
  }
}

renderHero();
renderPromos();
renderListings();

// Redraw when the visitor changes city in the header
document.addEventListener("chillingz:city", renderListings);

// "Show me London" button in the "coming soon" message
$("[data-switch-london]").addEventListener("click", () => {
  const select = document.querySelector("[data-city-select]");
  select.value = "london";
  select.dispatchEvent(new Event("change"));
});
