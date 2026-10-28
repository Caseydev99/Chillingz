/* ==========================================================================
   guides.js — the guides page and the article page
   --------------------------------------------------------------------------
   There are three kinds of "article", all shown by article.html:
     article.html?guide=pan-asian      a themed guide from GUIDES in data.js
     article.html?best=food-drinks     the top-rated places in a category
     article.html?post=reset-your-week a blog post from POSTS in data.js
   guides.html lists all three kinds as cards.
   ========================================================================== */

import { GUIDES, POSTS, CATEGORIES, CITIES } from "./data.js";
import { escapeHtml, ICONS } from "./utils.js";
import { getCity } from "./site.js";
import { updateHeartButtons, isFavourite } from "./favourites.js";
import { listingsForCity, guideListings, topRated, detailUrl, inCategory } from "./content.js";
import { listingImage } from "./cards.js";

const $ = (selector) => document.querySelector(selector);
const cityName = () => CITIES.find((city) => city.id === getCity()).name;


/* --------------------------------------------------------------------------
   Working out each article's content
   -------------------------------------------------------------------------- */

/* Every article we can show, each with its listings and a cover photo. */
function allArticles(listings) {
  const themed = GUIDES.map((guide) => ({
    kind: "guide",
    slug: guide.slug,
    url: `article.html?guide=${guide.slug}`,
    title: guide.title,
    intro: guide.intro,
    picks: guideListings(guide, listings).slice(0, 10),
  }));

  const best = CATEGORIES.map((category) => {
    const inThisCategory = listings.filter((listing) => inCategory(listing, category.slug));
    const picks = topRated(inThisCategory, { count: 10 });
    return {
      kind: "best",
      slug: category.slug,
      url: `article.html?best=${category.slug}`,
      title: `The best ${category.name.toLowerCase()} in ${cityName()}`,
      intro: `The ${picks.length} highest-rated ${category.name.toLowerCase()} spots on Chillingz right now, ranked by rating.`,
      picks,
    };
  });

  const posts = POSTS.map((post) => {
    const guide = GUIDES.find((item) => item.slug === post.related);
    return {
      kind: "post",
      slug: post.slug,
      url: `article.html?post=${post.slug}`,
      title: post.title,
      intro: post.intro,
      post,
      picks: guide ? guideListings(guide, listings).slice(0, 4) : [],
    };
  });

  // Lists need at least two places to be worth showing
  return {
    themed: themed.filter((article) => article.picks.length >= 2),
    best: best.filter((article) => article.picks.length >= 2),
    posts,
  };
}

/* A cover photo for each article, avoiding repeats where possible. */
function pickCovers(articles) {
  const used = new Set();
  articles.forEach((article) => {
    const cover = article.picks.find((item) => item.image && !used.has(item.image.fingerprint)) ?? article.picks.find((item) => item.image);
    if (cover) used.add(cover.image.fingerprint);
    article.cover = cover;
  });
}


/* --------------------------------------------------------------------------
   guides.html
   -------------------------------------------------------------------------- */
function articleCard(article) {
  const label = article.kind === "post"
    ? new Date(article.post.date).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })
    : `${article.picks.length} picks`;
  return `
    <li>
      <article class="guide-card">
        ${listingImage(article.cover ?? {}, { sizes: "(min-width: 1024px) 33vw, 90vw" })}
        <div class="card-body">
          <p class="chip">${escapeHtml(label)}</p>
          <h3 class="card-title"><a href="${article.url}">${escapeHtml(article.title)}</a></h3>
          <p class="card-details">${escapeHtml(article.intro)}</p>
        </div>
      </article>
    </li>`;
}

async function renderGuidesPage() {
  const listings = await listingsForCity();
  const { themed, best, posts } = allArticles(listings);
  pickCovers([...themed, ...best, ...posts]);
  $("[data-themed-guides]").innerHTML = themed.map(articleCard).join("") || '<li class="empty-note">Guides for this city are coming soon.</li>';
  $("[data-best-of]").innerHTML = best.map(articleCard).join("") || '<li class="empty-note">Coming soon.</li>';
  $("[data-posts]").innerHTML = posts.map(articleCard).join("");
}


/* --------------------------------------------------------------------------
   article.html
   -------------------------------------------------------------------------- */

/* One numbered place in a list: photo, name, details and a link. */
function pickHtml(listing, number) {
  const saved = isFavourite(listing.id);
  const details = [listing.subcategory || listing.type, listing.area, listing.priceLabel ? `From ${listing.priceLabel}` : ""].filter(Boolean).join(" · ");
  return `
    <li class="pick">
      <div class="pick-media">
        ${listingImage(listing, { sizes: "(min-width: 768px) 280px, 100vw" })}
        <button class="icon-btn heart-btn ${saved ? "is-saved" : ""}" type="button" data-favourite-id="${escapeHtml(listing.id)}"
          aria-pressed="${saved}" aria-label="Save ${escapeHtml(listing.title)} to favourites">${ICONS.heart}</button>
      </div>
      <div class="pick-body">
        <h2><span class="pick-number">${number}</span> ${escapeHtml(listing.title)}</h2>
        ${details ? `<p class="card-details">${escapeHtml(details)}</p>` : ""}
        ${listing.rating ? `<p class="card-rating"><span aria-hidden="true">★</span> ${listing.rating.toFixed(1)}<span class="visually-hidden"> out of 5</span></p>` : ""}
        ${listing.description ? `<p>${escapeHtml(listing.description)}</p>` : ""}
        <a class="btn btn-secondary" href="${detailUrl(listing)}">See details</a>
      </div>
    </li>`;
}

/* A blog post's paragraphs. Lines starting "## " become sub-headings. */
function postBodyHtml(post) {
  return post.body
    .map((paragraph) => paragraph.startsWith("## ")
      ? `<h2>${escapeHtml(paragraph.slice(3))}</h2>`
      : `<p>${escapeHtml(paragraph)}</p>`)
    .join("");
}

/* Tells search engines what the article is: a list of places, or a post. */
function addStructuredData(article) {
  const data = article.kind === "post"
    ? {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        headline: article.title,
        description: article.intro,
        datePublished: article.post.date,
        author: { "@type": "Organization", name: article.post.author },
      }
    : {
        "@context": "https://schema.org",
        "@type": "ItemList",
        name: article.title,
        description: article.intro,
        itemListElement: article.picks.map((listing, index) => ({
          "@type": "ListItem",
          position: index + 1,
          url: new URL(detailUrl(listing), location.href).href,
          name: listing.title,
        })),
      };
  const script = document.createElement("script");
  script.type = "application/ld+json";
  script.textContent = JSON.stringify(data);
  document.head.append(script);
}

async function renderArticlePage() {
  const page = $("[data-article]");
  const params = new URLSearchParams(location.search);
  const listings = await listingsForCity();
  const { themed, best, posts } = allArticles(listings);
  const all = [...themed, ...best, ...posts];

  const article =
    (params.get("guide") && themed.find((item) => item.slug === params.get("guide"))) ||
    (params.get("best") && best.find((item) => item.slug === params.get("best"))) ||
    (params.get("post") && posts.find((item) => item.slug === params.get("post")));

  if (!article) {
    document.title = "Guide not found — Chillingz";
    page.innerHTML = `
      <div class="notice" style="margin-block:48px">
        <h1>We couldn't find that guide</h1>
        <p>It may have been renamed or removed.</p>
        <a class="btn btn-primary" href="guides.html">See all guides</a>
      </div>`;
    return;
  }

  pickCovers([article]);
  document.title = `${article.title} — Chillingz`;
  document.querySelector('meta[name="description"]').setAttribute("content", article.intro);
  document.querySelector('meta[property="og:title"]').setAttribute("content", article.title);
  if (article.cover) document.querySelector('meta[property="og:image"]').setAttribute("content", article.cover.image.src);
  addStructuredData(article);

  // Three other articles to read next
  const more = all.filter((item) => item !== article).slice(0, 3);
  pickCovers(more);

  const isPost = article.kind === "post";
  page.innerHTML = `
    <nav class="breadcrumb" aria-label="Breadcrumb">
      <ol>
        <li><a href="index.html">Home</a></li>
        <li><a href="guides.html">Guides</a></li>
        <li aria-current="page">${escapeHtml(article.title)}</li>
      </ol>
    </nav>

    <article>
      <header class="article-header">
        ${article.cover ? `<div class="article-cover">${listingImage(article.cover, { sizes: "(min-width: 1024px) 900px, 100vw", eager: true })}</div>` : ""}
        <h1>${escapeHtml(article.title)}</h1>
        <p class="article-intro">${escapeHtml(article.intro)}</p>
        ${isPost ? `<p class="small-print">${escapeHtml(article.post.author)} · ${new Date(article.post.date).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</p>` : ""}
      </header>

      ${isPost ? `<div class="article-body">${postBodyHtml(article.post)}</div>` : ""}

      ${article.picks.length ? `
        ${isPost ? '<h2 class="article-subhead">Places to try</h2>' : ""}
        <ol class="pick-list">${article.picks.map((listing, index) => pickHtml(listing, index + 1)).join("")}</ol>` : ""}
    </article>

    ${more.length ? `
      <section class="section" aria-labelledby="more-title">
        <div class="section-head"><h2 id="more-title">More guides</h2><a href="guides.html">All guides</a></div>
        <ul class="guide-grid">${more.map(articleCard).join("")}</ul>
      </section>` : ""}`;
  updateHeartButtons();
}


/* --------------------------------------------------------------------------
   Start (and redraw when the city changes)
   -------------------------------------------------------------------------- */
function start() {
  const run = $("[data-article]") ? renderArticlePage : renderGuidesPage;
  run().catch((error) => {
    console.error(error);
    ($("[data-article]") ?? $("main")).insertAdjacentHTML("beforeend", '<p class="notice">We couldn\'t load this just now. Please refresh the page.</p>');
  });
}

start();
document.addEventListener("chillingz:city", start);
