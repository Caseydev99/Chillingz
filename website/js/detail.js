/* ==========================================================================
   detail.js — the venue page and the event page
   --------------------------------------------------------------------------
   venue.html?id=…  and  event.html?id=…  both use this file. The id is the
   listing's Firebase ID (the same one the app uses).

   The page shows:
     • the photo, name, rating, price and a heart to save it
     • "About", the details (where, phone, website), a map and the rating
     • a card linking to the venue's own booking site, or the organiser's
       ticket site (Chillingz doesn't take bookings itself)
     • "You might also like" — similar listings
   ========================================================================== */

import { CATEGORIES } from "./data.js";
import { escapeHtml, showToast, ICONS } from "./utils.js";
import { isFavourite, updateHeartButtons } from "./favourites.js";
import { getListing, listingsForCity, isEvent, isPast, detailUrl, inCategory } from "./content.js";
import { listingImage, cardRow } from "./cards.js";

const page = document.querySelector("[data-detail]");
const listingId = new URLSearchParams(location.search).get("id") ?? "";


/* --------------------------------------------------------------------------
   Small helpers
   -------------------------------------------------------------------------- */

/* "Saturday 8 November 2026" */
function longDate(isoDate) {
  return new Date(isoDate).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
}

/* "www.rocketpadel.com/club" -> "rocketpadel.com" for showing links. */
function shortHost(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url;
  }
}

/* The category's friendly name, e.g. "Food & Drink". */
function categoryName(listing) {
  const slug = isEvent(listing) ? "events" : listing.category;
  return CATEGORIES.find((category) => category.slug === slug)?.name ?? "Explore";
}

/* Firebase has very few descriptions yet, so when there isn't one we write a
   short, factual one from what we do know. */
function aboutText(listing) {
  if (listing.description) return listing.description;
  const kind = listing.subcategory || listing.type || categoryName(listing);
  const where = listing.venueName && listing.venueName !== listing.title ? ` at ${listing.venueName}` : "";
  const area = listing.area ? ` in ${listing.area}` : " in London";
  const price = listing.priceLabel ? ` Prices start from ${listing.priceLabel}.` : "";
  return `${listing.title} — ${kind.toLowerCase()}${where}${area}.${price}`;
}


/* --------------------------------------------------------------------------
   Search-engine information (title, description, structured data)
   -------------------------------------------------------------------------- */
function setPageInfo(listing) {
  const title = `${listing.title} — ${listing.subcategory || categoryName(listing)} in London | Chillingz`;
  const description = aboutText(listing).slice(0, 155);
  document.title = title;
  document.querySelector('meta[name="description"]').setAttribute("content", description);
  document.querySelector('meta[property="og:title"]').setAttribute("content", title);
  if (listing.image) {
    document.querySelector('meta[property="og:image"]').setAttribute("content", listing.image.src);
  }

  // schema.org data helps Google show rich results (dates, prices, ratings)
  const place = {
    "@type": "Place",
    name: listing.venueName || listing.title,
    address: { "@type": "PostalAddress", addressLocality: listing.area || "London", addressCountry: "GB", streetAddress: listing.address || undefined },
  };
  const data = isEvent(listing) && listing.date
    ? {
        "@context": "https://schema.org",
        "@type": "Event",
        name: listing.title,
        startDate: listing.date,
        eventStatus: "https://schema.org/EventScheduled",
        eventAttendanceMode: "https://schema.org/OfflineEventAttendanceMode",
        location: place,
        image: listing.image ? [new URL(listing.image.src, location.href).href] : undefined,
        description: aboutText(listing),
        offers: listing.priceFrom !== null ? {
          "@type": "Offer", price: listing.priceFrom, priceCurrency: "GBP",
          url: location.href, availability: "https://schema.org/InStock",
        } : undefined,
      }
    : {
        "@context": "https://schema.org",
        "@type": "LocalBusiness",
        name: listing.title,
        image: listing.image ? new URL(listing.image.src, location.href).href : undefined,
        address: place.address,
        telephone: listing.phone || undefined,
        url: listing.links.website || undefined,
        description: aboutText(listing),
      };
  // Google only accepts a rating together with how many reviews it's based on
  if (listing.rating && listing.reviewCount > 0) {
    data.aggregateRating = { "@type": "AggregateRating", ratingValue: listing.rating, reviewCount: listing.reviewCount, bestRating: 5 };
  }
  const script = document.createElement("script");
  script.type = "application/ld+json";
  script.textContent = JSON.stringify(data);
  document.head.append(script);
}


/* --------------------------------------------------------------------------
   How to book
   Chillingz doesn't take bookings: this card sends people to the venue's own
   booking site or the organiser's ticket site.
   -------------------------------------------------------------------------- */

/* Where to book: the ticket/booking link if there is one, else the website. */
function bookingLink(listing) {
  if (listing.links.ticket) {
    return { href: listing.links.ticket, label: isEvent(listing) ? "Get tickets" : "Book on their site" };
  }
  if (listing.links.website) {
    return { href: listing.links.website, label: "Visit their website" };
  }
  return null;
}

/* The card on the right (or below the details on phones). */
function bookingCardHtml(listing) {
  const forTickets = isEvent(listing);

  // An event that has already happened
  if (isPast(listing)) {
    return `
      <section class="booking-card" id="book" aria-labelledby="booking-title">
        <h2 id="booking-title">This event has ended</h2>
        <p>It took place on ${escapeHtml(longDate(listing.date))}. Have a look at what's coming up instead.</p>
        <a class="btn btn-primary btn-block" href="search.html?category=events&amp;sort=soonest">See upcoming events</a>
      </section>`;
  }

  const link = bookingLink(listing);
  const who = forTickets ? "the organiser" : "the venue";
  return `
    <section class="booking-card" id="book" aria-labelledby="booking-title">
      <h2 id="booking-title">${forTickets ? "Tickets" : "How to book"}</h2>
      ${listing.priceLabel ? `<p class="booking-price">From <strong>${escapeHtml(listing.priceLabel)}</strong>${forTickets ? " per ticket" : " per person"}</p>` : ""}
      ${forTickets && listing.date ? `<p class="booking-when"><strong>${escapeHtml(longDate(listing.date))}</strong>${listing.time ? ` · ${escapeHtml(listing.time)}` : ""}</p>` : ""}
      ${link ? `<a class="btn btn-primary btn-block" href="${escapeHtml(link.href)}" target="_blank" rel="noopener">${link.label} ↗</a>` : ""}
      <p class="small-print booking-note">${link
        ? `${forTickets ? "Tickets are sold directly by" : "Bookings are made directly with"} ${who}, not through Chillingz.`
        : `Contact ${who} directly to ${forTickets ? "get tickets" : "book"}.`}</p>
    </section>`;
}


/* --------------------------------------------------------------------------
   Extras: map, share, add to calendar
   -------------------------------------------------------------------------- */

/* The map is only loaded when someone asks for it: it comes from Google, so
   this keeps the page fast and avoids Google cookies until it's wanted. */
function setUpMap(listing) {
  const button = page.querySelector("[data-show-map]");
  if (!button) return;
  button.addEventListener("click", () => {
    const query = encodeURIComponent([listing.venueName || listing.title, listing.address, listing.area, "London"].filter(Boolean).join(", "));
    button.parentElement.innerHTML = `
      <iframe class="map-frame" title="Map showing ${escapeHtml(listing.title)}"
        src="https://maps.google.com/maps?q=${query}&output=embed" loading="lazy"
        referrerpolicy="no-referrer-when-downgrade"></iframe>`;
  });
}

/* "Share": uses the phone's share menu, or copies the link on computers. */
function setUpShare(listing) {
  page.querySelector("[data-share]")?.addEventListener("click", async () => {
    const shareData = { title: listing.title, text: `${listing.title} on Chillingz`, url: location.href };
    try {
      if (navigator.share) {
        await navigator.share(shareData);
      } else {
        await navigator.clipboard.writeText(location.href);
        showToast("Link copied");
      }
    } catch {
      /* the visitor closed the share menu — nothing to do */
    }
  });
}

/* "Add to calendar": makes a small calendar file (.ics) that phones and
   computers know how to open. */
function setUpCalendar(listing) {
  page.querySelector("[data-add-calendar]")?.addEventListener("click", () => {
    const start = new Date(listing.date);
    if (listing.time && /^\d{1,2}:\d{2}/.test(listing.time)) {
      const [hours, minutes] = listing.time.split(":").map(Number);
      start.setHours(hours, minutes, 0, 0);
    }
    const end = new Date(start.getTime() + 3 * 60 * 60 * 1000);
    const stamp = (date) => date.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const file = [
      "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Chillingz//Website//EN", "BEGIN:VEVENT",
      `UID:${listing.id}@chillingz`, `DTSTAMP:${stamp(new Date())}`,
      `DTSTART:${stamp(start)}`, `DTEND:${stamp(end)}`,
      `SUMMARY:${listing.title.replace(/[,;]/g, " ")}`,
      `LOCATION:${(listing.venueName || "London").replace(/[,;]/g, " ")}`,
      `URL:${location.href}`, "END:VEVENT", "END:VCALENDAR",
    ].join("\r\n");
    const link = document.createElement("a");
    link.href = URL.createObjectURL(new Blob([file], { type: "text/calendar" }));
    link.download = `${listing.title.replace(/[^\w]+/g, "-").toLowerCase()}.ics`;
    link.click();
    URL.revokeObjectURL(link.href);
  });
}


/* --------------------------------------------------------------------------
   Drawing the page
   -------------------------------------------------------------------------- */
function render(listing, similar) {
  const event = isEvent(listing);
  const link = bookingLink(listing);
  const saved = isFavourite(listing.id);
  const category = categoryName(listing);
  const categorySlug = event ? "events" : listing.category;
  const where = [listing.venueName && listing.venueName !== listing.title ? listing.venueName : "", listing.area].filter(Boolean).join(", ");

  // Each detail row only appears when Firebase has that information
  const facts = [
    event && listing.date ? ["When", `${escapeHtml(longDate(listing.date))}${listing.time ? ` · ${escapeHtml(listing.time)}` : ""}`] : null,
    where || listing.address ? ["Where", escapeHtml([where, listing.address].filter(Boolean).join(" — "))] : null,
    listing.priceLabel ? ["Price", `From ${escapeHtml(listing.priceLabel)}`] : null,
    listing.type ? ["Good for", escapeHtml(listing.type)] : null,
    listing.phone ? ["Phone", `<a href="tel:${escapeHtml(listing.phone.replace(/\s/g, ""))}">${escapeHtml(listing.phone)}</a>`] : null,
    listing.links.website ? ["Website", `<a href="${escapeHtml(listing.links.website)}" target="_blank" rel="noopener">${escapeHtml(shortHost(listing.links.website))} ↗</a>`] : null,
    listing.links.map ? ["Directions", `<a href="${escapeHtml(listing.links.map)}" target="_blank" rel="noopener">Open in Google Maps ↗</a>`] : null,
  ].filter(Boolean);

  page.innerHTML = `
    <nav class="breadcrumb" aria-label="Breadcrumb">
      <ol>
        <li><a href="index.html">Home</a></li>
        <li><a href="search.html?category=${categorySlug}">${escapeHtml(category)}</a></li>
        <li aria-current="page">${escapeHtml(listing.title)}</li>
      </ol>
    </nav>

    <div class="detail-grid">
      <div class="detail-main">
        <div class="detail-photo">
          ${listingImage(listing, { sizes: "(min-width: 1024px) 60vw, 100vw", eager: true })}
          <div class="detail-photo-actions">
            <button class="icon-btn heart-btn ${saved ? "is-saved" : ""}" type="button" data-favourite-id="${escapeHtml(listing.id)}"
              aria-pressed="${saved}" aria-label="Save ${escapeHtml(listing.title)} to favourites">${ICONS.heart}</button>
            <button class="icon-btn heart-btn" type="button" data-share aria-label="Share">
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M12 15V3M7 8l5-5 5 5M5 13v6a2 2 0 002 2h10a2 2 0 002-2v-6"/></svg>
            </button>
          </div>
        </div>

        <header class="detail-header">
          <p class="detail-chips">
            <a class="chip" href="search.html?category=${categorySlug}">${escapeHtml(category)}</a>
            ${listing.subcategory ? `<a class="chip" href="search.html?sub=${encodeURIComponent(listing.subcategory)}">${escapeHtml(listing.subcategory)}</a>` : ""}
          </p>
          <h1>${escapeHtml(listing.title)}</h1>
          <p class="detail-meta">
            ${listing.rating ? `<span class="card-rating"><span aria-hidden="true">★</span> ${listing.rating.toFixed(1)}<span class="visually-hidden"> out of 5</span>${listing.reviewCount ? ` (${listing.reviewCount})` : ""}</span>` : ""}
            ${listing.priceLabel ? `<span>From ${escapeHtml(listing.priceLabel)}</span>` : ""}
            ${where ? `<span>${escapeHtml(where)}</span>` : ""}
            ${event && listing.date ? `<span>${escapeHtml(longDate(listing.date))}</span>` : ""}
          </p>
          ${event && listing.date && !isPast(listing) ? '<button class="btn btn-secondary" type="button" data-add-calendar>Add to calendar</button>' : ""}
        </header>

        <section class="detail-section" aria-labelledby="about-title">
          <h2 id="about-title">About</h2>
          <p>${escapeHtml(aboutText(listing))}</p>
          ${listing.tags.length ? `
            <p class="detail-tags"><span class="visually-hidden">Good for: </span>
              ${listing.tags.map((tag) => `<a class="chip" href="search.html?tag=${encodeURIComponent(tag)}">${escapeHtml(tag)}</a>`).join("")}
            </p>` : ""}
        </section>

        ${facts.length ? `
          <section class="detail-section" aria-labelledby="details-title">
            <h2 id="details-title">Details</h2>
            <dl class="facts">
              ${facts.map(([label, value]) => `<div><dt>${label}</dt><dd>${value}</dd></div>`).join("")}
            </dl>
          </section>` : ""}

        <section class="detail-section" aria-labelledby="map-title">
          <h2 id="map-title">Map</h2>
          <div class="map-placeholder">
            <button class="btn btn-secondary" type="button" data-show-map>Show map</button>
            <p class="small-print">The map is provided by Google.</p>
          </div>
        </section>

        <section class="detail-section" aria-labelledby="reviews-title">
          <h2 id="reviews-title">Ratings &amp; reviews</h2>
          ${listing.rating
            ? `<div class="rating-summary">
                 <p class="rating-big">${listing.rating.toFixed(1)}<span class="visually-hidden"> out of 5</span></p>
                 <div>
                   <p class="stars" aria-hidden="true">${"★".repeat(Math.round(listing.rating))}${"☆".repeat(5 - Math.round(listing.rating))}</p>
                   <p class="small-print">${listing.reviewCount ? `Based on ${listing.reviewCount} reviews` : "Chillingz rating"}</p>
                 </div>
               </div>`
            : '<p class="small-print">No ratings yet.</p>'}
          <p class="small-print">Written reviews from Chillingz members are coming soon.</p>
        </section>
      </div>

      <aside class="detail-side">
        ${bookingCardHtml(listing)}
      </aside>
    </div>

    ${similar.length ? `
      <section class="section" aria-labelledby="similar-title">
        <div class="section-head"><h2 id="similar-title">You might also like</h2></div>
        ${cardRow(similar, { id: "similar-title" })}
      </section>` : ""}

    <!-- Phones only: a bar at the bottom with the booking link -->
    <div class="book-bar">
      <div>
        ${listing.priceLabel ? `<strong>From ${escapeHtml(listing.priceLabel)}</strong>` : `<strong>${escapeHtml(listing.title)}</strong>`}
        ${listing.rating ? `<span class="small-print">★ ${listing.rating.toFixed(1)}</span>` : ""}
      </div>
      ${isPast(listing)
        ? '<a class="btn btn-primary" href="#book">Ended</a>'
        : link ? `<a class="btn btn-primary" href="${escapeHtml(link.href)}" target="_blank" rel="noopener">${link.label} ↗</a>` : ""}
    </div>`;

  setUpMap(listing);
  setUpShare(listing);
  setUpCalendar(listing);
  updateHeartButtons();
}

/* Shown when the link has a wrong or old id. */
function renderNotFound() {
  document.title = "Not found — Chillingz";
  page.innerHTML = `
    <div class="notice" style="margin-block:48px">
      <h1>We couldn't find that</h1>
      <p>It may have been removed, or the link might be incomplete.</p>
      <a class="btn btn-primary" href="search.html">Browse everything</a>
    </div>`;
}


/* --------------------------------------------------------------------------
   Start
   -------------------------------------------------------------------------- */
async function start() {
  try {
    const listing = await getListing(listingId);
    if (!listing) {
      renderNotFound();
      return;
    }

    // If someone opened an event with venue.html (or the other way round),
    // quietly switch to the right address
    const rightPage = detailUrl(listing).split("?")[0];
    if (!location.pathname.endsWith(rightPage)) {
      history.replaceState(null, "", detailUrl(listing));
    }

    // "You might also like": same kind of place first, then same category
    const city = await listingsForCity();
    const others = city.filter((item) => item.id !== listing.id);
    const sameSub = others.filter((item) => listing.subcategory && item.subcategory === listing.subcategory);
    const sameCategory = others.filter((item) => inCategory(item, isEvent(listing) ? "events" : listing.category) && !sameSub.includes(item));
    const similar = [...sameSub, ...sameCategory.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0))].slice(0, 4);

    setPageInfo(listing);
    render(listing, similar);
  } catch (error) {
    console.error(error);
    page.innerHTML = '<p class="notice" style="margin-block:48px">We couldn\'t load this page just now. Please refresh to try again.</p>';
  }
}

start();

