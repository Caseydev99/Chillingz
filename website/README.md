# Chillingz website

The Chillingz website: a London guide to food & drink, things to do, events,
music, wellbeing and networking. It uses the same Firebase project as the
Chillingz app (`chillingz-dca92`), so accounts, favourites and interests are
shared between the two.

Plain HTML, CSS and JavaScript, with no build tools. Login is handled by
Firebase Authentication.

---

## Folder structure

```
website/
  index.html, search.html, venue.html, event.html, guides.html, article.html,
  account.html, offers.html, vouchers.html, rewards.html, about.html,
  contact.html, faqs.html, terms.html, privacy.html, cookies.html,
  404.html, offline.html        ← one file per page
  css/styles.css                ← all the styles (numbered sections inside)
  js/data.js                    ← website words you can edit (menus, guides, FAQs, offers…)
  js/site.js                    ← header, footer, menus, cookie banner (every page)
  js/auth.js                    ← login / sign-up pop-up
  js/favourites.js              ← hearts and recent searches
  js/newsletter.js              ← "Sign up for updates & newsletters" in the footer
  js/firebase.js                ← connection to Firebase
  js/content.js, cards.js       ← listings and listing cards
  js/home.js, search.js, detail.js, account.js, guides.js, pages.js  ← one per page type
  js/utils.js                   ← small shared helpers
  images/                       ← logo, icons, homepage photo
  manifest.json, sw.js          ← lets people install the site, and use it offline
  scripts/export_content.py     ← copies listings from Firebase (see below)
  scripts/serve.py              ← runs the site on your computer

  Made by the export script (not saved in Git):
  data/content.json, images/content/, sitemap.xml, robots.txt
```

## How it fits together

1. **Content** (venues, events, categories, photos) lives in Firebase, the same
   place the app reads it from. `scripts/export_content.py` copies it into
   `data/content.json` and makes small WebP photos. GitHub runs the script on
   every deploy and every 3 hours, so new listings appear by themselves.
2. **Pages** load `js/site.js` (header, footer, login) and their own script,
   which reads `data/content.json`.
3. **People's data** (accounts, favourites, messages, newsletter
   sign-ups) is read and written in Firebase directly, so it's always live.
   Access is controlled by `Chillingz-main/firestore.rules`.

## Run it on your computer

From the `Chillingz` folder (the first two commands only once, or whenever you
want fresh listings):

```bash
python -m pip install pillow
python website/scripts/export_content.py
python website/scripts/serve.py
```

Then open <http://localhost:8090>. Press Ctrl+C in the terminal to stop.

## Changing things

| To change…                            | Edit…                                            |
|---------------------------------------|--------------------------------------------------|
| Venues, events, prices, photos        | Firebase (same as for the app). Appears within 3 hours, or run the deploy by hand |
| Menus, footer links, cities           | `js/data.js` → `MAIN_MENU`, `FOOTER_LINKS`, `CITIES` |
| Homepage words and quick searches     | `js/data.js` → `HOME`                            |
| Guides                                | `js/data.js` → `GUIDES`                          |
| Blog posts                            | `js/data.js` → `POSTS` (placeholders: replace them) |
| Offers                                | `js/data.js` → `OFFERS` (only real, agreed offers) |
| FAQs, contact topics, voucher amounts | `js/data.js` → `FAQS`, `CONTACT_TOPICS`, `VOUCHER_AMOUNTS` |
| Rewards wording                       | `js/data.js` → `REWARDS` (placeholder)           |
| Review score / press mentions         | `js/data.js` → `TRUST` (real figures only; hidden while empty) |
| Colours                               | `css/styles.css`, section 1                      |
| Terms, privacy                        | `terms.html`, `privacy.html`, **and** the app's copies in `Chillingz-main/public/` |
| London areas for the Area filter      | `scripts/export_content.py` → `LONDON_AREAS`     |

---

## Deploying (GitHub Pages)

The workflow `.github/workflows/deploy-web.yml` publishes:

- the website at `https://chillingzworldwide.com/` (the old
  `caseydev99.github.io/Chillingz/` address forwards there)
- the Flutter web app at `/app/`
- the app's legal pages (`/privacy-policy.html` and others) at the top level

It runs on every push to `main`, every 3 hours, and from **Actions → Deploy
website to GitHub Pages → Run workflow**.

**First time only:**

1. On GitHub, open the repository's **Settings → Pages** and set **Source** to
   **GitHub Actions**.
   - A private repository needs a paid GitHub plan for Pages. On a free plan,
     make the repository public first.
2. Push to `main`, or run the workflow by hand, and wait for the green tick
   under **Actions**.
3. Open the site address and check the homepage shows listings.

**The domain** (`chillingzworldwide.com`, registered with GoDaddy):

- GoDaddy DNS has four `A` records for `@` (185.199.108.153, .109.153,
  .110.153 and .111.153) and a `CNAME` for `www` → `caseydev99.github.io`.
- It's set under **Settings → Pages → Custom domain**, with **Enforce HTTPS**
  ticked.
- The workflow asks GitHub for the address, so the sitemap, robots.txt and
  the `/app/` version follow the domain by themselves. To change domain,
  change it under Settings → Pages and in DNS, and add it to Firebase's
  authorised domains (below).

**Netlify or Vercel instead:** run `export_content.py` as the build command,
publish the `website/` folder, and set the `SITE_URL` environment variable.

---

## Before launch: what the Firebase owner must do

Only an owner of the `chillingz-dca92` Firebase project can make these changes.

- [ ] **Authorised domains:** Authentication → Settings → Authorised domains →
      add `chillingzworldwide.com`, `www.chillingzworldwide.com` and
      `caseydev99.github.io`. Login doesn't work on the live site until this
      is done.
- [ ] **Google sign-in in the app (optional).** The website only offers
      email and password. The app has a "Continue with Google" button, which
      stays hidden on each platform until it's set up. To turn it on, first go
      to Authentication → Sign-in method and turn on **Google**, then:
  1. **Android:** in Project settings → Your apps → Android, add the SHA-1
     fingerprints of the debug key, the upload key and Google Play's app
     signing key (Play Console → App integrity). Download the new
     `google-services.json` into `Chillingz-main/android/app/`. Copy the
     **Web client ID** from the Google provider page into
     `GoogleSignInConfig.webClientId`
     (`Chillingz-main/lib/core/constants/google_sign_in_config.dart`).
  2. **iOS:** download the new `GoogleService-Info.plist`. Copy its
     `CLIENT_ID` into `GoogleSignInConfig.iosClientId`. Copy its
     `REVERSED_CLIENT_ID` over the placeholder URL scheme in
     `Chillingz-main/ios/Runner/Info.plist`.
  3. Release a new app version to Google Play and the App Store.
- [ ] **Publish the database rules:** publish `Chillingz-main/firestore.rules`
      (`firebase deploy --only firestore:rules`, or paste them into Firestore →
      Rules). This turns on:
  - `enquiries`: contact form and gift voucher requests
  - `newsletterSignups`: the footer sign-up
- [ ] **Someone handles requests:** nothing sends emails automatically yet.
      Check the `enquiries` and `newsletterSignups` collections, reply to
      messages, and import sign-ups into MailerLite.

## Before launch: content and legal

- [ ] **Update the terms and privacy policy.** They say an account is
      required, which isn't true on the website. They also don't mention
      contact messages, newsletter sign-ups or Firebase. Update both the
      website and app copies.
- [ ] Replace the placeholder blog posts (`POSTS`) and rewards wording (`REWARDS`).
- [ ] Add real offers (`OFFERS`) and trust figures (`TRUST`) when you have them.
- [ ] In Firebase: add descriptions, addresses and opening hours to listings.
      Give listings their own photos (many share one), add ratings outside
      Things To Do, and mark some as featured or new.

---

## Test checklist

**Tested while building:**

- [x] **Screen sizes:** every page at 320, 375, 768, 1024, 1440 and 1920 px.
      No sideways scrolling, and no script errors.
- [x] **Light and dark mode** (follows the device setting).
- [x] **Guests:** every page opens without logging in, and no pop-up appears
      by itself. Search, filters, favourites and recent searches work.
      Contact, voucher and newsletter forms check every field.
- [x] **Login pop-up:** opens from the header and stays on the same page.
      Log in, sign up and forgot-password tabs; sign-up checks.
- [x] **My Account:** "Log in to see this" for guests, and all four sections
      (checked with a pretend user).
- [x] **Accessibility:** one main heading per page, labels on every field,
      named buttons, unique ids, a "Skip to content" link, a visible focus
      outline, keyboard access to menus (Escape closes them), 44px tap targets,
      and colour contrast of at least 4.5:1 for text.
- [x] **Offline:** visited pages open with no connection; other pages show
      the offline page.
- [x] **Search engines:** a title and description on each page, Open Graph
      tags, schema.org data (Organization, WebSite, LocalBusiness, Event,
      ItemList, BlogPosting, FAQPage), sitemap.xml with 139 pages, and
      robots.txt.

**Still to check:**

- [ ] **Real accounts:** logging in, signing up, forgot
      password, favourites shared with the app, and sending real messages. These need the live site and the Firebase owner's changes above.
- [ ] **Lighthouse scores** (aim: 90+). After deploying, open the site in
      Chrome → DevTools → Lighthouse, or use
      <https://pagespeed.web.dev>. Test the homepage, search and a venue page,
      on mobile.
- [ ] **Real devices:** an iPhone (Safari) and an Android phone (Chrome), plus
      Firefox and Edge on a computer. Testing so far used a Chromium browser
      at different sizes.
- [ ] **Installing:** "Add to Home Screen" on a phone.

## Known limits

- Listing pages are filled in by JavaScript. Google reads these, but some
  other sites and link previews only see the general page title and photo.
- Social media previews need a full web address for their images. Until
  there's a final domain, previews may not show a photo.
- Only Things To Do listings have ratings, so "Best of" lists and the Top 10
  only use those.
- Written reviews and opening hours aren't shown, because Firebase doesn't
  store them yet.
- Chillingz doesn't take bookings. Venue and event pages link to the
  venue's own booking site or the organiser's ticket site (from the listing's
  ticket or website link in Firebase).
- Online payment isn't set up. The voucher form sends a request, and
  payment links are sent by email.
- The website has no Google sign-in. Anyone who signed up in the app with
  Google can use **Forgot password** on the website to add a password to the
  same account, then log in with their email.
