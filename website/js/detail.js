/* ==========================================================================
   detail.js — the venue page and the event page
   --------------------------------------------------------------------------
   venue.html?id=…  and  event.html?id=…  both use this file. The id is the
   listing's Firebase ID (the same one the app uses).

   The page shows:
     • the photo, name, rating, price and a heart to save it
     • "About", the details (where, phone, website), a map and the rating
     • a booking form: "Book a table" for venues, "Request tickets" for events
     • "You might also like" — similar listings
   Guests can book with just their name, email and phone number.
   ========================================================================== */

import { CATEGORIES } from "./data.js";
import { escapeHtml, showToast, ICONS, storage } from "./utils.js";
import { isFavourite, updateHeartButtons } from "./favourites.js";
import { getListing, listingsForCity, isEvent, isPast, detailUrl, inCategory } from "./content.js";
import { listingImage, cardRow } from "./cards.js";
import { getCurrentUser, openAuthModal } from "./auth.js";
import { loadFirestore } from "./firebase.js";

const page = document.querySelector("[data-detail]");
const listingId = new URLSearchParams(location.search).get("id") ?? "";

// Bookings this browser has made, so guests can see them again later
const GUEST_BOOKINGS_KEY = "chillingz.guestBookings";


/* --------------------------------------------------------------------------
   Small helpers
   -------------------------------------------------------------------------- */

/* "Saturday 8 November 2026" */
function longDate(isoDate) {
  return new Date(isoDate).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
}

/* Today's date as "2026-10-26", the format date boxes use. */
function todayIso() {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
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
   The booking form
   -------------------------------------------------------------------------- */

/* Times people can pick for a table: 12:00 to 22:30, every half hour. */
function timeOptions() {
  const options = [];
  for (let minutes = 12 * 60; minutes <= 22 * 60 + 30; minutes += 30) {
    const time = `${String(Math.floor(minutes / 60)).padStart(2, "0")}:${String(minutes % 60).padStart(2, "0")}`;
    options.push(`<option value="${time}" ${time === "19:00" ? "selected" : ""}>${time}</option>`);
  }
  return options.join("");
}

/* The HTML for the booking card on the right (or at the bottom on phones). */
function bookingFormHtml(listing) {
  const forTickets = isEvent(listing);

  // An event that has already happened can't be booked
  if (isPast(listing)) {
    return `
      <section class="booking-card" id="book" aria-labelledby="booking-title">
        <h2 id="booking-title">This event has ended</h2>
        <p>It took place on ${escapeHtml(longDate(listing.date))}. Have a look at what's coming up instead.</p>
        <a class="btn btn-primary btn-block" href="search.html?category=events&amp;sort=soonest">See upcoming events</a>
      </section>`;
  }

  const user = getCurrentUser();
  const peopleOptions = Array.from({ length: forTickets ? 10 : 20 }, (_, index) => {
    const number = index + 1;
    return `<option value="${number}" ${number === 2 ? "selected" : ""}>${number} ${forTickets ? (number === 1 ? "ticket" : "tickets") : (number === 1 ? "person" : "people")}</option>`;
  }).join("");

  // Events with a fixed date don't ask for one
  const whenFields = forTickets && listing.date
    ? `<p class="booking-when"><strong>${escapeHtml(longDate(listing.date))}</strong>${listing.time ? ` · ${escapeHtml(listing.time)}` : ""}</p>
       <input type="hidden" name="date" value="${listing.date.slice(0, 10)}">
       <input type="hidden" name="time" value="${escapeHtml((listing.time || "").slice(0, 5))}">`
    : `<div class="field-row">
         <div class="field">
           <label for="book-date">Date</label>
           <input class="input" id="book-date" name="date" type="date" min="${todayIso()}" value="${todayIso()}" required>
           <p class="field-error" id="book-date-error"></p>
         </div>
         <div class="field">
           <label for="book-time">Time</label>
           <select class="input" id="book-time" name="time">${timeOptions()}</select>
         </div>
       </div>`;

  return `
    <section class="booking-card" id="book" aria-labelledby="booking-title">
      <h2 id="booking-title">${forTickets ? "Request tickets" : "Book a table"}</h2>
      ${listing.priceLabel ? `<p class="booking-price">From <strong>${escapeHtml(listing.priceLabel)}</strong>${forTickets ? " per ticket" : " per person"}</p>` : ""}

      <form novalidate data-booking-form>
        ${whenFields}
        <div class="field">
          <label for="book-people">${forTickets ? "Tickets" : "Guests"}</label>
          <select class="input" id="book-people" name="people">${peopleOptions}</select>
        </div>
        <div class="field">
          <label for="book-name">Your name</label>
          <input class="input" id="book-name" name="name" type="text" autocomplete="name" required value="${escapeHtml(user?.displayName ?? "")}">
          <p class="field-error" id="book-name-error"></p>
        </div>
        <div class="field">
          <label for="book-email">Email</label>
          <input class="input" id="book-email" name="email" type="email" autocomplete="email" required value="${escapeHtml(user?.email ?? "")}">
          <p class="field-error" id="book-email-error"></p>
        </div>
        <div class="field">
          <label for="book-phone">Mobile number</label>
          <input class="input" id="book-phone" name="phone" type="tel" autocomplete="tel" inputmode="tel" required placeholder="07123 456789">
          <p class="field-error" id="book-phone-error"></p>
        </div>
        <div class="field">
          <label for="book-notes">Anything we should know? <span class="small-print">(optional)</span></label>
          <textarea class="input" id="book-notes" name="notes" rows="2" maxlength="500" placeholder="Birthday, dietary needs, accessibility…"></textarea>
        </div>
        <label class="checkbox-row">
          <input type="checkbox" name="consent" required>
          <span>I agree to Chillingz sharing these details with the ${forTickets ? "organiser" : "venue"} to arrange this. <a href="privacy.html" target="_blank" rel="noopener">Privacy policy</a></span>
        </label>
        <p class="field-error" id="book-consent-error"></p>
        <p class="form-message" role="alert" data-form-message></p>
        <button class="btn btn-primary btn-block" type="submit">${forTickets ? "Request tickets" : "Request booking"}</button>
        <p class="small-print booking-note">No account needed. ${forTickets ? "The organiser" : "The venue"} will confirm by email.</p>
      </form>

      ${listing.links.ticket || listing.links.website ? `
        <div class="booking-alt">
          <p class="small-print">Prefer to book directly?</p>
          ${listing.links.ticket ? `<a class="btn btn-secondary btn-block" href="${escapeHtml(listing.links.ticket)}" target="_blank" rel="noopener">${forTickets ? "Buy on the ticket site" : "Book on their site"} ↗</a>` : ""}
          ${!listing.links.ticket && listing.links.website ? `<a class="btn btn-secondary btn-block" href="${escapeHtml(listing.links.website)}" target="_blank" rel="noopener">Visit their website ↗</a>` : ""}
        </div>` : ""}
    </section>`;
}

/* Checks the booking form. Shows a red message under any box that needs
   fixing and gives back true when everything is fine. */
function checkBookingForm(form) {
  const values = Object.fromEntries(new FormData(form));
  const digits = (values.phone ?? "").replace(/[^\d]/g, "");
  // In the same order as the form, so the first problem gets the focus
  const errors = {
    date: !form.elements.date || form.elements.date.type === "hidden" || (values.date && values.date >= todayIso()) ? "" : "Please choose today or a later date.",
    name: values.name?.trim() ? "" : "Please enter your name.",
    email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email?.trim() ?? "") ? "" : "Please enter a valid email address.",
    phone: digits.length >= 7 && digits.length <= 15 && /^[\d\s+()-]+$/.test(values.phone) ? "" : "Please enter a valid phone number.",
    consent: values.consent ? "" : "Please tick to agree so we can pass on your request.",
  };

  Object.entries(errors).forEach(([field, message]) => {
    const box = form.querySelector(`#book-${field}-error`);
    if (box) box.textContent = message;
    const input = form.elements[field];
    if (input && input.type !== "hidden") {
      input.setAttribute("aria-invalid", message ? "true" : "false");
      if (message) input.setAttribute("aria-describedby", `book-${field}-error`);
    }
  });

  const firstProblem = Object.keys(errors).find((field) => errors[field]);
  if (firstProblem) form.elements[firstProblem]?.focus();
  return !firstProblem;
}

/* Saves the booking request in Firebase ("bookings" collection).
   Gives back the new booking's reference. */
async function saveBooking(listing, form) {
  const values = Object.fromEntries(new FormData(form));
  const user = getCurrentUser();
  const { db, collection, addDoc, serverTimestamp } = await loadFirestore();
  const booking = {
    listingId: listing.id,
    listingTitle: listing.title.slice(0, 200),
    kind: isEvent(listing) ? "tickets" : "table",
    name: values.name.trim().slice(0, 100),
    email: values.email.trim().toLowerCase(),
    phone: values.phone.trim(),
    date: values.date ?? "",
    time: values.time ?? "",
    people: Number(values.people),
    notes: (values.notes ?? "").trim().slice(0, 500),
    userId: user?.uid ?? null,
    status: "requested",
    source: "web",
    createdAt: serverTimestamp(),
  };
  const saved = await addDoc(collection(db, "bookings"), booking);

  // Remember it in this browser too, so a guest can find it again
  const remembered = storage.get(GUEST_BOOKINGS_KEY, []);
  remembered.unshift({ id: saved.id, listingId: listing.id, listingTitle: listing.title, date: booking.date, time: booking.time, people: booking.people, kind: booking.kind });
  storage.set(GUEST_BOOKINGS_KEY, remembered.slice(0, 20));
  return { reference: saved.id.slice(0, 8).toUpperCase(), booking };
}

/* What people see after sending a request. Guests get a gentle offer to
   create an account — never required. */
function confirmationHtml(listing, { reference, booking }) {
  const forTickets = booking.kind === "tickets";
  const when = booking.date ? `${longDate(booking.date)}${booking.time ? ` at ${booking.time}` : ""}` : "";
  const isGuest = !getCurrentUser();
  return `
    <div class="booking-done" tabindex="-1" data-booking-done>
      <p class="booking-done-icon" aria-hidden="true">✓</p>
      <h2>Request sent!</h2>
      <p>${forTickets ? `${booking.people} ${booking.people === 1 ? "ticket" : "tickets"}` : `Table for ${booking.people}`} at <strong>${escapeHtml(listing.title)}</strong>${when ? `, ${escapeHtml(when)}` : ""}.</p>
      <p>We'll email <strong>${escapeHtml(booking.email)}</strong> once it's confirmed. Your reference is <strong>${reference}</strong>.</p>
      ${isGuest ? `
        <div class="booking-upsell">
          <p><strong>Want to keep track of it?</strong> Create a free account with the same email to see this booking in My Bookings, save favourites and use the app.</p>
          <button class="btn btn-secondary btn-block" type="button" data-signup-after-booking>Create an account</button>
          <p class="small-print">Totally optional — your booking is already sent.</p>
        </div>` : '<p><a href="account.html#bookings">See it in My Bookings</a></p>'}
    </div>`;
}

function setUpBookingForm(listing) {
  const form = page.querySelector("[data-booking-form]");
  const message = form.querySelector("[data-form-message]");

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    message.textContent = "";
    if (!checkBookingForm(form)) return;

    const button = form.querySelector('[type="submit"]');
    const label = button.textContent;
    button.disabled = true;
    button.textContent = "Sending…";
    try {
      const result = await saveBooking(listing, form);
      const card = page.querySelector(".booking-card");
      card.innerHTML = confirmationHtml(listing, result);
      card.querySelector("[data-booking-done]").focus();
      card.querySelector("[data-signup-after-booking]")?.addEventListener("click", () => {
        openAuthModal("signup", {
          message: "Use the same email as your booking and it'll appear in My Bookings.",
          prefill: { name: result.booking.name, email: result.booking.email },
        });
      });
    } catch (error) {
      console.error("Booking failed", error);
      message.dataset.type = "error";
      // "permission-denied" means online booking isn't switched on in Firebase yet
      message.textContent = error.code === "permission-denied"
        ? "Sorry — online booking isn't available just yet. Please use the venue's own website or email us and we'll sort it out."
        : "Sorry, we couldn't send that. Please check your connection and try again.";
      button.disabled = false;
      button.textContent = label;
    }
  });
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
        ${bookingFormHtml(listing)}
      </aside>
    </div>

    ${similar.length ? `
      <section class="section" aria-labelledby="similar-title">
        <div class="section-head"><h2 id="similar-title">You might also like</h2></div>
        ${cardRow(similar, { id: "similar-title" })}
      </section>` : ""}

    <!-- Phones only: a bar at the bottom that jumps to the booking form -->
    <div class="book-bar">
      <div>
        ${listing.priceLabel ? `<strong>From ${escapeHtml(listing.priceLabel)}</strong>` : `<strong>${escapeHtml(listing.title)}</strong>`}
        ${listing.rating ? `<span class="small-print">★ ${listing.rating.toFixed(1)}</span>` : ""}
      </div>
      <a class="btn btn-primary" href="#book">${isPast(listing) ? "Ended" : event ? "Get tickets" : "Book a table"}</a>
    </div>`;

  if (!isPast(listing)) setUpBookingForm(listing);
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

// Logging in while on the page fills in the name and email in the form
document.addEventListener("chillingz:auth", ({ detail: { user } }) => {
  const form = page.querySelector("[data-booking-form]");
  if (!form || !user) return;
  if (!form.elements.name.value) form.elements.name.value = user.displayName ?? "";
  if (!form.elements.email.value) form.elements.email.value = user.email ?? "";
});
