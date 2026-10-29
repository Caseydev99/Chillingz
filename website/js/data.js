/* ==========================================================================
   data.js — website-only text and settings
   --------------------------------------------------------------------------
   Edit this file to change words, links and lists on the website without
   touching any HTML.

   Venues, events and categories do NOT live here. They come from your app's
   Firebase database, so the website and the app always show the same places.
   ========================================================================== */

/* The cities in the header switcher. Only London has real listings today;
   the others are placeholders so you can see the switcher working. */
export const CITIES = [
  { id: "london", name: "London" },
  { id: "manchester", name: "Manchester" },
  { id: "birmingham", name: "Birmingham" },
];

/* The categories used in menus. "slug" must match the category's "slug"
   field in Firebase (collection: categories). */
export const CATEGORIES = [
  { slug: "food-drinks", name: "Food & Drink", blurb: "Restaurants, cafés, bars and street food" },
  { slug: "activities", name: "Things To Do", blurb: "Days out, games and new experiences" },
  { slug: "events", name: "Events", blurb: "Live happenings and curated experiences" },
  { slug: "music", name: "Music", blurb: "Gigs, DJs and live performances" },
  { slug: "health-wellbeing", name: "Health & Wellbeing", blurb: "Fitness, wellness and mindful living" },
  { slug: "networking", name: "Networking", blurb: "Meetups and community connections" },
];

/* Main menu at the top of every page. A menu item with "megaMenu: true"
   opens a big panel listing all the CATEGORIES above. Items with "children"
   open a small drop-down. */
export const MAIN_MENU = [
  { label: "Explore", megaMenu: true },
  { label: "Food & Drink", href: "search.html?category=food-drinks" },
  { label: "Events", href: "search.html?category=events" },
  { label: "Guides", href: "guides.html" },
  {
    label: "Offers",
    children: [
      { label: "Offers & deals", href: "offers.html" },
      { label: "Gift vouchers", href: "vouchers.html" },
      { label: "Rewards", href: "rewards.html" },
    ],
  },
];

/* Links in the footer, grouped into columns */
export const FOOTER_LINKS = [
  {
    heading: "Discover",
    links: [
      { label: "Things to do", href: "search.html?category=activities" },
      { label: "Food & drink", href: "search.html?category=food-drinks" },
      { label: "Events", href: "search.html?category=events" },
      { label: "Guides & blog", href: "guides.html" },
    ],
  },
  {
    heading: "Treat yourself",
    links: [
      { label: "Offers", href: "offers.html" },
      { label: "Gift vouchers", href: "vouchers.html" },
      { label: "Rewards", href: "rewards.html" },
      { label: "My account", href: "account.html" },
    ],
  },
  {
    heading: "Chillingz",
    links: [
      { label: "About us", href: "about.html" },
      { label: "Contact", href: "contact.html" },
      { label: "FAQs", href: "faqs.html" },
      { label: "List your venue", href: "contact.html?topic=list-venue" },
    ],
  },
];

/* Links in the very bottom row of the footer */
export const LEGAL_LINKS = [
  { label: "Terms", href: "terms.html" },
  { label: "Privacy", href: "privacy.html" },
  { label: "Cookie policy", href: "cookies.html" },
];

/* Trust signals in the footer. Only fill these in with REAL figures: your
   actual app-store rating and publications that have actually featured you.
   While they are empty, the trust strip is simply not shown.
   Example: { rating: 4.7, reviewCount: "350", pressMentions: ["Time Out"] } */
export const TRUST = {
  rating: null,
  reviewCount: "",
  pressMentions: [],
};

/* The words at the top of the homepage */
export const HOME = {
  heroTitle: "Find your next favourite night out",
  heroText: "Restaurants, games, gigs, wellness and meetups across London. Browse and save your favourites — no sign-up needed.",
  // Little shortcut buttons under the search box
  quickSearches: ["Brunch", "Competitive socialising", "Rooftop", "Sauna", "R&B", "Coworking"],
};

/* Guides: themed "best of" lists. Each guide picks real listings from
   Firebase using the rules in "pick":
     category      – only this category (see CATEGORIES above)
     subcategories – listings whose subcategory is one of these
     tag           – listings with this interest tag
   Add, remove or reword guides here; the listings update by themselves. */
export const GUIDES = [
  {
    slug: "competitive-socialising",
    title: "Game on: London's best competitive socialising",
    intro: "Crazy golf, karting, bowling and escape rooms — the places to go when dinner and drinks needs a scoreboard.",
    pick: { subcategories: ["Competitive Socialising", "Bowling & Arcade", "Go Karting", "Escape Rooms", "Adventure Golf"] },
  },
  {
    slug: "pan-asian",
    title: "Pan-Asian plates worth crossing town for",
    intro: "From dumplings to ramen, our pick of the Pan-Asian spots on Chillingz.",
    pick: { category: "food-drinks", subcategories: ["Pan Asian"] },
  },
  {
    slug: "recharge",
    title: "Recharge: saunas, spas and cold plunges",
    intro: "Sweat, plunge, repeat. The best places in London to switch off and reset.",
    pick: { subcategories: ["Sauna & Cold Plunge", "Bathhouse & Spa", "Massage & Spa"] },
  },
  {
    slug: "creative-workshops",
    title: "Get creative: workshops to try this month",
    intro: "Paint, sip, throw a pot or learn something new — hands-on sessions for curious minds.",
    pick: { subcategories: ["Creative Workshop"] },
  },
  {
    slug: "coworking",
    title: "Work from somewhere new",
    intro: "Coworking spaces with good coffee, good wifi and good people.",
    pick: { category: "networking", subcategories: ["Coworking Space"] },
  },
  {
    slug: "night-owls",
    title: "For night owls",
    intro: "Late finishes, live music and somewhere to go after the last orders bell.",
    pick: { tag: "Night Owl" },
  },
];

/* Blog posts. PLACEHOLDER articles to show how the blog works — replace
   them with your own. Each paragraph in "body" is one string. A line that
   starts with "## " becomes a sub-heading. "related" links the post to a
   guide (its slug) so readers see real places at the end. */
export const POSTS = [
  {
    slug: "plan-a-group-night-out",
    title: "How to plan a group night out without the group-chat chaos",
    intro: "Ten people, ten opinions. A few simple steps to get everyone out of the chat and into the same place.",
    date: "2026-10-01",
    author: "The Chillingz team",
    related: "competitive-socialising",
    body: [
      "## Pick the vibe before the venue",
      "Start by agreeing on the kind of night: something active, a long dinner, or live music. It's much easier to choose between three places than thirty.",
      "## Set a budget everyone's happy with",
      "Share a rough price per person up front. Most Chillingz listings show a \"from\" price, so you can filter by budget before anyone falls in love with somewhere expensive.",
      "## Book early for bigger groups",
      "Groups of six or more fill up fast, especially on Fridays and Saturdays. Book with the venue as soon as you have a rough headcount — you can usually adjust numbers later.",
      "## Save a shortlist",
      "Tap the heart on a few options and share the links. Your favourites follow you between the website and the Chillingz app.",
    ],
  },
  {
    slug: "reset-your-week",
    title: "Five ways to reset your week in London",
    intro: "When the week's been a lot: a sauna, a stretch or a new skill can do more than another night in.",
    date: "2026-09-15",
    author: "The Chillingz team",
    related: "recharge",
    body: [
      "## Sweat it out",
      "Saunas and cold plunges have become a London favourite for a reason: an hour of heat and cold leaves you feeling brand new.",
      "## Move with other people",
      "Group classes — from reformer pilates to boxing — are a good way to switch off your brain and meet people at the same time.",
      "## Make something",
      "Creative workshops give you something to show for your evening. No experience needed for most.",
      "## Get outside",
      "Even a short walk along the river or a round of padel resets your head after a day at a screen.",
      "## Plan something to look forward to",
      "Book one thing for the weekend before Monday is over. Having a plan makes the week go faster.",
    ],
  },
];

/* My Account → Rewards. PLACEHOLDER: the rewards scheme isn't running yet,
   so the page explains how it will work. Change the wording to match your
   real scheme before launching it. */
export const REWARDS = {
  intro: "Chillingz Rewards is coming soon. Here's how it will work:",
  steps: [
    "Earn points as you discover, save and share places on Chillingz.",
    "Unlock perks like members-only offers.",
    "Your points will appear here and in the app.",
  ],
};

/* The "Offers, vouchers and rewards" tiles on the homepage.
   PLACEHOLDER wording: make sure it matches what you really offer. */
export const PROMOS = [
  { title: "Offers & deals", text: "Members-only perks and seasonal deals at places we love.", href: "offers.html", cta: "See offers" },
  { title: "Gift vouchers", text: "Give someone a great night out.", href: "vouchers.html", cta: "Buy a voucher" },
  { title: "Chillingz Rewards", text: "Earn points as you explore and unlock treats.", href: "rewards.html", cta: "How it works" },
];

/* Short text about the company, shown in the footer */
export const SITE = {
  name: "Chillingz",
  tagline: "Find fun things to do, places to eat and events near you.",
  email: "chillingzworldwide@gmail.com",   // from the existing privacy policy and terms
  appStoreUrl: "https://apps.apple.com/gb/app/chillingz/id6766254665",
  playStoreUrl: "https://play.google.com/store/apps/details?id=com.chillingz.app",
};

/* Offers & deals page. Only add REAL offers that the venue has agreed to.
   While this list is empty, the page says there are no offers right now.
   Example:
     { title: "2-for-1 cocktails before 7pm", venue: "Venue name",
       listingId: "the listing's Firebase ID", ends: "2026-12-31",
       details: "Mon–Thu only. Show this page at the bar." },          */
export const OFFERS = [];

/* Gift voucher amounts (in pounds) offered on the vouchers page */
export const VOUCHER_AMOUNTS = [25, 50, 75, 100];

/* Questions and answers for the FAQs page. Keep these matching your terms. */
export const FAQS = [
  {
    question: "Do I need an account to use Chillingz?",
    answer: "No. You can browse, search and save favourites on your device as a guest. An account keeps your favourites in one place across the website and the app.",
  },
  {
    question: "Can I book through Chillingz?",
    answer: "No. Chillingz helps you find great places and events. Each venue or event page links to the venue's own booking site or the organiser's ticket site, and you book with them directly.",
  },
  {
    question: "Can I change or cancel a booking?",
    answer: "Contact the venue or organiser directly. Your booking is with them, not with Chillingz.",
  },
  {
    question: "Are my favourites the same on the app and the website?",
    answer: "Yes. Log in with the same account and your favourites and interests are shared between the Chillingz website and app.",
  },
  {
    question: "How do I list my venue or event?",
    answer: "Use the contact form and choose \"List my venue\". Tell us a little about your place and we'll be in touch.",
  },
  {
    question: "How do I delete my account?",
    answer: "Go to My Account → My details and choose \"Delete my account\", or use the delete account page. This permanently removes your profile and sign-in.",
  },
];

/* Topics in the contact form drop-down. "list-venue" is used by the
   "List your venue" link in the footer. */
export const CONTACT_TOPICS = [
  { id: "general", label: "General question" },
  { id: "vouchers", label: "Gift vouchers" },
  { id: "list-venue", label: "List my venue or event" },
  { id: "press", label: "Press & partnerships" },
  { id: "privacy", label: "My data & privacy" },
];
