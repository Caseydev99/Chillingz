/* ==========================================================================
   cards.js — the listing "cards" (photo, name, price, rating, heart)
   --------------------------------------------------------------------------
   The homepage, search results and favourites all show listings the same
   way, so the card is written once here and used everywhere.
   ========================================================================== */

import { escapeHtml, ICONS } from "./utils.js";
import { detailUrl, isEvent, isPast } from "./content.js";
import { isFavourite } from "./favourites.js";

/* The listing's photo as a <picture>. The browser picks the right size for
   the screen from "srcset", and "loading=lazy" means photos further down the
   page are only downloaded when the visitor scrolls near them.
   "sizes" tells the browser roughly how wide the photo will be shown. */
export function listingImage(listing, { sizes = "(min-width: 1024px) 25vw, (min-width: 600px) 45vw, 80vw", eager = false } = {}) {
  if (!listing.image) {
    return '<div class="card-media card-media-empty" aria-hidden="true"></div>';
  }
  const { src, srcset, width, height } = listing.image;
  return `
    <img class="card-media" src="${src}" srcset="${srcset}" sizes="${sizes}"
      width="${width}" height="${height}" alt=""
      ${eager ? 'fetchpriority="high"' : 'loading="lazy"'} decoding="async">`;
}

/* A short date like "Sat 8 Nov" for event listings. */
export function shortDate(isoDate) {
  if (!isoDate) return "";
  return new Date(isoDate).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" });
}

/* One card. "rank" adds a big number for Top 10 lists. */
export function listingCard(listing, { rank } = {}) {
  const saved = isFavourite(listing.id);
  const details = [listing.subcategory || listing.type, listing.venueName !== listing.title ? listing.venueName : ""]
    .filter(Boolean)
    .join(" · ");
  // Little label on the photo: "Ended", the event date, or "New"
  let badge = "";
  if (isPast(listing)) badge = '<span class="card-badge">Ended</span>';
  else if (isEvent(listing) && listing.date) badge = `<span class="card-badge">${escapeHtml(shortDate(listing.date))}</span>`;
  else if (listing.isNew) badge = '<span class="card-badge">New</span>';

  return `
    <article class="listing-card">
      <div class="card-media-wrap">
        ${listingImage(listing)}
        ${badge}
        ${rank ? `<span class="card-rank" aria-hidden="true">${rank}</span>` : ""}
        <button class="icon-btn heart-btn ${saved ? "is-saved" : ""}" type="button"
          data-favourite-id="${escapeHtml(listing.id)}" aria-pressed="${saved}"
          aria-label="Save ${escapeHtml(listing.title)} to favourites">${ICONS.heart}</button>
      </div>
      <div class="card-body">
        <h3 class="card-title">
          <a href="${detailUrl(listing)}">${rank ? `<span class="visually-hidden">Number ${rank}: </span>` : ""}${escapeHtml(listing.title)}</a>
        </h3>
        ${details ? `<p class="card-details">${escapeHtml(details)}</p>` : ""}
        <p class="card-meta">
          ${listing.priceLabel ? `<span>From ${escapeHtml(listing.priceLabel)}</span>` : ""}
          ${listing.rating ? `<span class="card-rating"><span aria-hidden="true">★</span> ${listing.rating.toFixed(1)}<span class="visually-hidden"> out of 5</span></span>` : ""}
        </p>
      </div>
    </article>`;
}

/* A row of cards that scrolls sideways on phones and becomes a grid on
   bigger screens. "id" is used to link the heading to the list. */
export function cardRow(listings, { id, rankStart } = {}) {
  if (!listings.length) {
    return '<p class="empty-note">Nothing here yet — check back soon.</p>';
  }
  return `
    <ul class="card-row" aria-labelledby="${id}">
      ${listings.map((listing, index) => `<li>${listingCard(listing, { rank: rankStart ? rankStart + index : undefined })}</li>`).join("")}
    </ul>`;
}
