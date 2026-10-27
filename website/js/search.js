/* ==========================================================================
   search.js — the search page: filters, sorting and results
   --------------------------------------------------------------------------
   How it works:
   1. Everything the visitor picks is kept in the web address, for example
        search.html?q=brunch&category=food-drinks&price=0-15
      so a search can be bookmarked, shared, or reached with the Back button.
   2. Whenever a filter changes, the address is updated and the results are
      worked out again from the listings (content.js). No page reload needed.
   3. Results show 24 at a time, with a "Show more" button.
   ========================================================================== */

import { CATEGORIES, CITIES } from "./data.js";
import { escapeHtml } from "./utils.js";
import { getCity } from "./site.js";
import { addRecentSearch, updateHeartButtons } from "./favourites.js";
import { loadContent, listingsForCity, inCategory, isEvent, isPast } from "./content.js";
import { listingCard } from "./cards.js";

const PAGE_SIZE = 24;

const $ = (selector) => document.querySelector(selector);
const form = $("[data-filters-form]");
const sortSelect = $("[data-sort-select]");

let allListings = [];      // every listing in the chosen city
let allTags = [];          // the app's interest tags, for the "Vibe" filter
let shownCount = PAGE_SIZE;


/* --------------------------------------------------------------------------
   Reading and writing the filters
   -------------------------------------------------------------------------- */

/* Reads the filters from the web address into a simple object. */
function filtersFromAddress() {
  const params = new URLSearchParams(location.search);
  return {
    q: params.get("q") ?? "",
    type: params.get("type") ?? "",
    category: params.get("category") ?? "",
    sub: params.get("sub") ?? "",
    area: params.get("area") ?? "",
    date: params.get("date") ?? "",
    price: params.get("price") ?? "",
    rated: params.get("rated") ?? "",
    tags: params.getAll("tag"),
    sort: params.get("sort") ?? "",
  };
}

/* Reads the filters from the form on screen. */
function filtersFromForm() {
  const data = new FormData(form);
  return {
    q: (data.get("q") ?? "").trim(),
    type: data.get("type") ?? "",
    category: data.get("category") ?? "",
    sub: data.get("sub") ?? "",
    area: data.get("area") ?? "",
    date: data.get("date") ?? "",
    price: data.get("price") ?? "",
    rated: data.get("rated") ?? "",
    tags: data.getAll("tag"),
    sort: sortSelect.value,
  };
}

/* Puts the filters into the web address (without reloading the page). */
function saveFiltersToAddress(filters) {
  const params = new URLSearchParams();
  Object.entries(filters).forEach(([key, value]) => {
    if (key === "tags") value.forEach((tag) => params.append("tag", tag));
    else if (value) params.set(key, value);
  });
  const query = params.toString();
  history.replaceState(null, "", query ? `?${query}` : location.pathname);
}

/* Sets the form on screen to match the filters. */
function fillForm(filters) {
  form.elements.q.value = filters.q;
  (form.querySelector(`[name="type"][value="${filters.type}"]`) ?? form.querySelector('[name="type"][value=""]')).checked = true;
  form.elements.category.value = filters.category;
  fillSubcategoryOptions(filters.category);
  form.elements.sub.value = filters.sub;
  form.elements.area.value = filters.area;
  form.elements.date.value = filters.date;
  (form.querySelector(`[name="price"][value="${filters.price}"]`) ?? form.querySelector('[name="price"][value=""]')).checked = true;
  form.elements.rated.checked = Boolean(filters.rated);
  form.querySelectorAll('[name="tag"]').forEach((box) => {
    box.checked = filters.tags.includes(box.value);
  });
  sortSelect.value = filters.sort;
}


/* --------------------------------------------------------------------------
   Building the filter choices from the real listings
   -------------------------------------------------------------------------- */

/* Adds "(12)" counts so people can see how many listings each choice has. */
function optionHtml(value, label, count) {
  return `<option value="${escapeHtml(value)}">${escapeHtml(label)}${count !== undefined ? ` (${count})` : ""}</option>`;
}

function fillCategoryOptions() {
  $("[data-category-select]").innerHTML = optionHtml("", "All categories") +
    CATEGORIES.map((category) =>
      optionHtml(category.slug, category.name, allListings.filter((listing) => inCategory(listing, category.slug)).length),
    ).join("");

  // The tabs at the top of the page do the same job as the drop-down
  $("[data-category-tabs]").innerHTML = [{ slug: "", name: "All" }, ...CATEGORIES]
    .map((category) => `<button class="category-tab" type="button" data-category-tab="${category.slug}">${escapeHtml(category.name)}</button>`)
    .join("");
}

/* The "Kind of place" list only shows subcategories in the chosen category. */
function fillSubcategoryOptions(category) {
  const counts = new Map();
  allListings
    .filter((listing) => listing.subcategory && (!category || inCategory(listing, category)))
    .forEach((listing) => counts.set(listing.subcategory, (counts.get(listing.subcategory) ?? 0) + 1));
  const names = [...counts.keys()].sort((a, b) => a.localeCompare(b));
  const select = $("[data-sub-select]");
  const previous = select.value;
  select.innerHTML = optionHtml("", "Any") + names.map((name) => optionHtml(name, name, counts.get(name))).join("");
  select.value = names.includes(previous) ? previous : "";
}

function fillAreaOptions() {
  const counts = new Map();
  allListings.filter((listing) => listing.area).forEach((listing) => counts.set(listing.area, (counts.get(listing.area) ?? 0) + 1));
  const names = [...counts.keys()].sort((a, b) => a.localeCompare(b));
  $("[data-area-select]").innerHTML = optionHtml("", "Anywhere") + names.map((name) => optionHtml(name, name, counts.get(name))).join("");
  // No areas known at all (e.g. a new city): hide the filter
  $("[data-area-field]").hidden = names.length === 0;
}

function fillTagOptions() {
  $("[data-tag-options]").innerHTML = allTags
    .map((tag) => `<label><input type="checkbox" name="tag" value="${escapeHtml(tag)}"><span>${escapeHtml(tag)}</span></label>`)
    .join("");
}


/* --------------------------------------------------------------------------
   Working out the results
   -------------------------------------------------------------------------- */

/* The start and end of a "When" choice, as dates. */
function dateRange(choice) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  if (choice === "today") {
    end.setDate(end.getDate() + 1);
  } else if (choice === "weekend") {
    // Friday to Sunday night. If it's already the weekend, start today.
    const day = start.getDay(); // 0 = Sunday, 1 = Monday … 6 = Saturday
    const isWeekend = day === 0 || day >= 5;
    const daysUntilMonday = day === 0 ? 1 : 8 - day;
    if (!isWeekend) start.setDate(start.getDate() + (5 - day));
    end.setDate(end.getDate() + daysUntilMonday);
  } else if (choice === "week") {
    end.setDate(end.getDate() + 7);
  } else if (choice === "month") {
    end.setDate(end.getDate() + 30);
  }
  return { start, end };
}

/* All the words a listing can be found by. */
function searchableText(listing) {
  return [listing.title, listing.venueName, listing.subcategory, listing.type, listing.categoryName, listing.area, listing.description, ...listing.tags]
    .join(" ")
    .toLowerCase();
}

/* How well a listing matches the keywords. 0 means "not a match".
   Every word typed must appear somewhere; matches in the name count most. */
function matchScore(listing, words) {
  if (!words.length) return 1;
  const text = searchableText(listing);
  const title = listing.title.toLowerCase();
  let score = 0;
  for (const word of words) {
    if (!text.includes(word)) return 0;
    score += title.includes(word) ? 3 : 1;
  }
  return score;
}

/* Applies every filter and the sort order. Gives back the matching listings. */
function findResults(filters) {
  const words = filters.q.toLowerCase().split(/\s+/).filter(Boolean);
  const [priceMin, priceMax] = filters.price ? filters.price.split("-").map((value) => (value === "" ? Infinity : Number(value))) : [];
  const range = filters.date ? dateRange(filters.date) : null;

  const results = allListings
    .map((listing) => ({ listing, score: matchScore(listing, words) }))
    .filter(({ listing, score }) => {
      if (!score) return false;
      if (filters.type === "events" && !isEvent(listing)) return false;
      if (filters.type === "places" && isEvent(listing)) return false;
      if (filters.category && !inCategory(listing, filters.category)) return false;
      if (filters.sub && listing.subcategory !== filters.sub) return false;
      if (filters.area && listing.area !== filters.area) return false;
      if (filters.rated && !(listing.rating >= Number(filters.rated))) return false;
      if (filters.tags.length && !filters.tags.some((tag) => listing.tags.includes(tag))) return false;
      if (filters.price) {
        if (listing.priceFrom === null) return false;
        if (listing.priceFrom < priceMin || (priceMax !== Infinity && listing.priceFrom >= priceMax)) return false;
      }
      if (range) {
        if (!listing.date) return false;
        const date = new Date(listing.date);
        if (date < range.start || date >= range.end) return false;
      }
      return true;
    });

  const byRating = (a, b) => (b.listing.rating ?? 0) - (a.listing.rating ?? 0);
  const sorters = {
    "": (a, b) => b.score - a.score || byRating(a, b),
    rating: byRating,
    newest: (a, b) => (b.listing.createdAt ?? "").localeCompare(a.listing.createdAt ?? ""),
    // Upcoming events first (soonest at the top), then places, then events that have ended
    soonest: (a, b) => Number(isPast(a.listing)) - Number(isPast(b.listing))
      || (a.listing.date || "9999").localeCompare(b.listing.date || "9999"),
    "price-low": (a, b) => (a.listing.priceFrom ?? Infinity) - (b.listing.priceFrom ?? Infinity),
    "price-high": (a, b) => (b.listing.priceFrom ?? -1) - (a.listing.priceFrom ?? -1),
  };
  return results.sort(sorters[filters.sort] ?? sorters[""]).map(({ listing }) => listing);
}


/* --------------------------------------------------------------------------
   Showing the results
   -------------------------------------------------------------------------- */

/* The heading and browser tab title, e.g. "Food & Drink in London". */
function updateTitle(filters) {
  const city = CITIES.find((item) => item.id === getCity()).name;
  const category = CATEGORIES.find((item) => item.slug === filters.category);
  let heading = category ? `${category.name} in ${city}` : `Things to do in ${city}`;
  if (filters.sub) heading = `${filters.sub} in ${city}`;
  if (filters.q) heading = `“${filters.q}” in ${city}`;
  $("[data-search-title]").textContent = heading;
  document.title = `${heading} — Chillingz`;

  document.querySelectorAll("[data-category-tab]").forEach((tab) => {
    tab.setAttribute("aria-pressed", String(tab.dataset.categoryTab === filters.category));
  });
}

/* The little "× Under £15" buttons above the results. */
function renderActiveFilters(filters) {
  const labels = [];
  const add = (key, text, value) => labels.push({ key, text, value });
  if (filters.q) add("q", `“${filters.q}”`);
  if (filters.type) add("type", filters.type === "events" ? "Events" : "Places");
  if (filters.category) add("category", CATEGORIES.find((item) => item.slug === filters.category)?.name ?? filters.category);
  if (filters.sub) add("sub", filters.sub);
  if (filters.area) add("area", filters.area);
  if (filters.date) add("date", form.elements.date.selectedOptions[0]?.textContent ?? filters.date);
  if (filters.price) add("price", form.querySelector(`[name="price"][value="${filters.price}"]`)?.nextElementSibling.textContent ?? filters.price);
  if (filters.rated) add("rated", "4★ or more");
  filters.tags.forEach((tag) => add("tag", tag, tag));

  $("[data-active-filters]").innerHTML = labels
    .map(({ key, text, value }) => `
      <li><button class="active-filter" type="button" data-remove-filter="${key}" data-value="${escapeHtml(value ?? "")}">
        <span class="visually-hidden">Remove filter: </span>${escapeHtml(text)} <span aria-hidden="true">×</span>
      </button></li>`)
    .join("");

  // Number on the "Filters" button (search words and categories don't count)
  const count = labels.filter(({ key }) => !["q", "category"].includes(key)).length;
  const badge = $("[data-filter-count]");
  badge.textContent = count;
  badge.hidden = count === 0;
}

/* Works out and shows the results for whatever is in the form. */
function update({ resetPaging = true } = {}) {
  const filters = filtersFromForm();
  saveFiltersToAddress(filters);
  if (resetPaging) shownCount = PAGE_SIZE;

  const results = findResults(filters);
  updateTitle(filters);
  renderActiveFilters(filters);

  const countText = `${results.length} ${results.length === 1 ? "result" : "results"}`;
  $("[data-results-count]").textContent = countText;
  $("[data-result-count-button]").textContent = countText;

  if (!results.length) {
    $("[data-results]").innerHTML = `
      <li class="no-results">
        <h2>No matches</h2>
        <p>Try removing a filter or searching for something broader.</p>
        <button class="btn btn-primary" type="button" data-clear-filters>Clear all filters</button>
      </li>`;
  } else {
    $("[data-results]").innerHTML = results
      .slice(0, shownCount)
      .map((listing) => `<li>${listingCard(listing)}</li>`)
      .join("");
  }
  $("[data-load-more]").hidden = results.length <= shownCount;
  updateHeartButtons();
}


/* --------------------------------------------------------------------------
   The filter panel on phones
   -------------------------------------------------------------------------- */
function openFilters() {
  $("[data-filters-panel]").classList.add("is-open");
  $("[data-filters-backdrop]").hidden = false;
  $("[data-filters-open]").setAttribute("aria-expanded", "true");
  document.body.classList.add("no-scroll");
  $("[data-filters-panel] .filters-close").focus();
}

function closeFilters() {
  if (!$("[data-filters-panel]").classList.contains("is-open")) return;
  $("[data-filters-panel]").classList.remove("is-open");
  $("[data-filters-backdrop]").hidden = true;
  $("[data-filters-open]").setAttribute("aria-expanded", "false");
  document.body.classList.remove("no-scroll");
  $("[data-filters-open]").focus();
}


/* --------------------------------------------------------------------------
   Start
   -------------------------------------------------------------------------- */
async function start() {
  try {
    const content = await loadContent();
    allTags = content.tags;
    allListings = await listingsForCity();
  } catch (error) {
    console.error(error);
    $("[data-results-count]").textContent = "We couldn't load listings just now. Please refresh the page.";
    return;
  }

  fillCategoryOptions();
  fillAreaOptions();
  fillTagOptions();

  const filters = filtersFromAddress();
  if (filters.q) addRecentSearch(filters.q);
  fillForm(filters);
  update();
}

// Any change in the filters updates the results straight away.
// Typing waits a moment so results don't flicker on every letter.
let typingTimer = null;
form.addEventListener("input", (event) => {
  if (event.target.name === "q") {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(update, 250);
    return;
  }
  if (event.target.name === "category") fillSubcategoryOptions(event.target.value);
  update();
});
form.addEventListener("submit", (event) => event.preventDefault());
sortSelect.addEventListener("change", () => update());

// Category tabs at the top
$("[data-category-tabs]").addEventListener("click", (event) => {
  const tab = event.target.closest("[data-category-tab]");
  if (!tab) return;
  form.elements.category.value = tab.dataset.categoryTab;
  fillSubcategoryOptions(tab.dataset.categoryTab);
  update();
});

// "×" on an active filter, "Clear all", "Show more", and the phone panel
document.addEventListener("click", (event) => {
  const remove = event.target.closest("[data-remove-filter]");
  if (remove) {
    const key = remove.dataset.removeFilter;
    if (key === "tag") form.querySelector(`[name="tag"][value="${CSS.escape(remove.dataset.value)}"]`).checked = false;
    else if (key === "type" || key === "price") form.querySelector(`[name="${key}"][value=""]`).checked = true;
    else if (key === "rated") form.elements.rated.checked = false;
    else form.elements[key].value = "";
    if (key === "category") fillSubcategoryOptions("");
    update();
    return;
  }
  if (event.target.closest("[data-clear-filters]")) {
    fillForm({ q: "", type: "", category: "", sub: "", area: "", date: "", price: "", rated: "", tags: [], sort: sortSelect.value });
    update();
    return;
  }
  if (event.target.closest("[data-load-more]")) {
    shownCount += PAGE_SIZE;
    update({ resetPaging: false });
    return;
  }
  if (event.target.closest("[data-filters-open]")) openFilters();
  if (event.target.closest("[data-filters-close], [data-filters-backdrop]")) closeFilters();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeFilters();
});

// The header search box on this page searches without reloading
document.querySelector(".site-header [data-search-form]")?.addEventListener("submit", (event) => {
  event.preventDefault();
  form.elements.q.value = event.currentTarget.elements.q.value.trim();
  if (form.elements.q.value) addRecentSearch(form.elements.q.value);
  update();
});

// A different city in the header: reload the listings for that city
document.addEventListener("chillingz:city", start);

start();
