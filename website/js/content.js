/* ==========================================================================
   content.js — reads the listings the export script copied from Firebase
   --------------------------------------------------------------------------
   scripts/export_content.py saves the app's listings into data/content.json.
   This file loads that file once and offers simple ways to ask for listings,
   for example "the newest ones" or "the top 10 things to do".

   Every listing looks like this (only the useful fields shown):
     { id, title, category, subcategory, venueName, priceLabel, priceFrom,
       rating, reviewCount, date, time, links: { website, map, ticket },
       image: { src, srcset, width, height }, createdAt, city, tags }
   ========================================================================== */

import { getCity } from "./site.js";

// The loaded file, kept so it is only downloaded once per page
let contentPromise = null;

/* Downloads data/content.json (only the first time it's asked for). */
export function loadContent() {
  if (!contentPromise) {
    contentPromise = fetch("data/content.json").then((response) => {
      if (!response.ok) throw new Error(`Could not load content (${response.status})`);
      return response.json();
    });
  }
  return contentPromise;
}

/* The listings for the city chosen in the header switcher. */
export async function listingsForCity(city = getCity()) {
  const { listings } = await loadContent();
  return listings.filter((listing) => listing.city.toLowerCase() === city);
}

/* One listing by its ID (the same ID the app uses), or undefined. */
export async function getListing(id) {
  const { listings } = await loadContent();
  return listings.find((listing) => listing.id === id);
}

/* Is this listing something with a date (an event), rather than a place? */
export function isEvent(listing) {
  return Boolean(listing.date) || listing.category === "events";
}

/* Has this event's date already gone by? (Places never "end".) */
export function isPast(listing) {
  if (!listing.date) return false;
  return listing.date.slice(0, 10) < new Date().toISOString().slice(0, 10);
}

/* Does this listing belong in a category? "Events" also includes anything
   with a date, because Firebase has no listings in the Events category yet. */
export function inCategory(listing, slug) {
  if (slug === "events") return isEvent(listing);
  return listing.category === slug;
}

/* The page that shows this listing in full. */
export function detailUrl(listing) {
  return `${isEvent(listing) ? "event" : "venue"}.html?id=${encodeURIComponent(listing.id)}`;
}


/* --------------------------------------------------------------------------
   Ready-made lists for the homepage rows
   -------------------------------------------------------------------------- */

/* "Trending": listings marked as featured in Firebase come first, then the
   best rated (a rating with more reviews counts for a little more). */
export function trending(listings, count = 12) {
  const score = (listing) =>
    (listing.isFeatured ? 100 : 0) + (listing.rating ?? 0) + Math.log10(1 + listing.reviewCount) / 2;
  return [...listings]
    .filter((listing) => listing.isFeatured || listing.rating)
    .sort((a, b) => score(b) - score(a))
    .slice(0, count);
}

/* "New to Book": listings marked as new first, then the most recently added. */
export function newest(listings, count = 12) {
  return [...listings]
    .sort((a, b) => Number(b.isNew) - Number(a.isNew) || (b.createdAt ?? "").localeCompare(a.createdAt ?? ""))
    .slice(0, count);
}

/* "Hot Event Tickets": upcoming dated listings (soonest first), topped up
   with music listings while there are only a few dated ones. */
export function eventTickets(listings, count = 12) {
  const today = new Date().toISOString().slice(0, 10);
  const upcoming = listings
    .filter((listing) => listing.date && listing.date.slice(0, 10) >= today)
    .sort((a, b) => a.date.localeCompare(b.date));
  const music = listings.filter((listing) => listing.category === "music" && !upcoming.includes(listing));
  return [...upcoming, ...music].slice(0, count);
}

/* The listings for one guide in data.js (GUIDES), best rated first. */
export function guideListings(guide, listings) {
  const { category, subcategories, tag } = guide.pick;
  const wanted = (subcategories ?? []).map((name) => name.toLowerCase());
  return listings
    .filter((listing) =>
      (!category || listing.category === category) &&
      (!wanted.length || wanted.includes(listing.subcategory.toLowerCase())) &&
      (!tag || listing.tags.some((item) => item.toLowerCase() === tag.toLowerCase())))
    .sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0));
}

/* "Top 10": the best-rated listings, optionally in one category. */
export function topRated(listings, { category, count = 10 } = {}) {
  return listings
    .filter((listing) => listing.rating && (!category || listing.category === category))
    .sort((a, b) => b.rating - a.rating || b.reviewCount - a.reviewCount)
    .slice(0, count);
}
