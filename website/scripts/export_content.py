"""
export_content.py — copies the app's content from Firebase into the website
-----------------------------------------------------------------------------
What it does, in order:
  1. Reads the public collections from your app's Firebase database
     (categories, subcategories, listings, tags…). These are the same
     collections the app reads, and anyone is allowed to read them, so no
     password or secret key is needed.
  2. Tidies each record into a simple "listing" with the same ID the app uses.
     That is what makes favourites match between the website and the app.
  3. Turns every photo into small, fast WebP files in two sizes.
  4. Writes everything into  website/data/content.json  for the pages to use.

How to run it (from the Chillingz folder):
    python -m pip install pillow        (only the first time)
    python website/scripts/export_content.py

GitHub runs it automatically before every deploy and every few hours, so
new listings added in Firebase appear on the website without you doing
anything. The output files are not saved in Git; they are made fresh each time.

The sorting rules below copy the app's own rules in
Chillingz-main/lib/features/home/services/home_firestore_service.dart.
If the app's rules change, change them here too.
"""

import base64
import hashlib
import io
import json
import os
import re
import shutil
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

# The app's public Firebase settings (the same as website/js/firebase.js)
PROJECT_ID = "chillingz-dca92"
API_KEY = "AIzaSyBo3d9_sMFWuOd-mkyTV91DSPe4puM2dOk"
FIRESTORE_URL = (
    f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
    "/databases/(default)/documents"
)

# Where the results go
WEBSITE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = WEBSITE_DIR / "data" / "content.json"
IMAGE_DIR = WEBSITE_DIR / "images" / "content"

# The website's public address, used in sitemap.xml and robots.txt.
# GitHub sets SITE_URL automatically when it deploys (see the workflow);
# change this default if you move the site to your own domain.
SITE_URL = os.environ.get("SITE_URL", "https://caseydev99.github.io/Chillingz/").rstrip("/") + "/"

# Pages that should appear in search engines (account, 404 and offline don't)
SITEMAP_PAGES = [
    "", "search.html", "guides.html", "offers.html", "vouchers.html", "rewards.html",
    "about.html", "contact.html", "faqs.html", "terms.html", "privacy.html", "cookies.html",
]

# Photo widths to make. Phones use the small one, big screens the large one.
IMAGE_WIDTHS = [480, 960]
WEBP_QUALITY = 72

# The website's category for each of the app's "buckets"
CATEGORY_SLUGS = {
    "food": "food-drinks",
    "health": "health-wellbeing",
    "networking": "networking",
    "music": "music",
    "events": "events",
    "activities": "activities",
}

# London areas for the "Area" filter on the search page. Firebase has no
# addresses yet, so a listing gets an area when one of these names appears in
# its name, venue or address (e.g. "Avalon Pilates Clapham" -> Clapham).
# Add more names here if you like; longer names are checked first.
LONDON_AREAS = [
    "Soho", "Covent Garden", "Leicester Square", "Oxford Street", "Mayfair", "Marylebone",
    "Fitzrovia", "Holborn", "Bloomsbury", "King's Cross", "Kings Cross", "Euston", "Camden",
    "Islington", "Angel", "Shoreditch", "Hoxton", "Dalston", "Hackney", "Bethnal Green",
    "Whitechapel", "Aldgate", "Spitalfields", "Barbican", "City of London", "Farringdon",
    "Clerkenwell", "Canary Wharf", "Greenwich", "The O2", "North Greenwich", "Stratford",
    "Bermondsey", "Borough", "London Bridge", "Southbank", "South Bank", "Waterloo",
    "Elephant and Castle", "Peckham", "Brixton", "Clapham", "Battersea", "Vauxhall",
    "Tooting", "Balham", "Wandsworth", "Putney", "Fulham", "Chelsea", "Kensington",
    "Notting Hill", "Shepherd's Bush", "White City", "Hammersmith", "Chiswick", "Paddington",
    "Victoria", "Westminster", "Wimbledon", "Croydon", "Bromley", "Eltham", "Lewisham",
    "Deptford", "Crofton Park", "Beckton", "Walthamstow", "Wembley", "Richmond", "Bluewater",
]

CURRENCY_SYMBOLS = {
    "USD": "$", "EUR": "€", "GBP": "£", "POUND": "£",
    "INR": "₹", "JPY": "¥", "CAD": "CA$", "AUD": "AU$",
}


# ---------------------------------------------------------------------------
# Reading from Firebase
# ---------------------------------------------------------------------------

def plain_value(value):
    """Firebase's web API wraps every value in a label such as
    {"stringValue": "Padel"}. This unwraps it into a normal Python value."""
    kind, inner = next(iter(value.items()))
    if kind == "mapValue":
        return {key: plain_value(item) for key, item in inner.get("fields", {}).items()}
    if kind == "arrayValue":
        return [plain_value(item) for item in inner.get("values", [])]
    if kind == "integerValue":
        return int(inner)
    if kind == "nullValue":
        return None
    return inner  # strings, numbers, true/false, dates


def read_collection(name):
    """Downloads every record in one collection, page by page.
    Gives back a list of (record id, record data) pairs."""
    records = []
    page_token = ""
    while True:
        query = {"key": API_KEY, "pageSize": 300}
        if page_token:
            query["pageToken"] = page_token
        url = f"{FIRESTORE_URL}/{name}?{urllib.parse.urlencode(query)}"
        with urllib.request.urlopen(url, timeout=60) as response:
            page = json.load(response)
        for document in page.get("documents", []):
            record_id = document["name"].rsplit("/", 1)[-1]
            data = {key: plain_value(item) for key, item in document.get("fields", {}).items()}
            records.append((record_id, data))
        page_token = page.get("nextPageToken")
        if not page_token:
            return records


# ---------------------------------------------------------------------------
# Small helpers (copies of the app's helpers with the same names)
# ---------------------------------------------------------------------------

def text(value):
    """Any value as trimmed text ("" for nothing)."""
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value).strip()


def first_text(values):
    """The first value in the list that isn't empty."""
    for value in values:
        if text(value):
            return text(value)
    return ""


def as_map(value):
    """A map (dictionary), or the first map in a list, or {}."""
    if isinstance(value, list):
        return as_map(value[0]) if value else {}
    return value if isinstance(value, dict) else {}


def as_maps(value):
    """A list of maps."""
    if isinstance(value, list):
        return [item for item in (as_map(entry) for entry in value) if item]
    single = as_map(value)
    return [single] if single else []


def humanize(value):
    """"food-drinks" -> "Food Drinks", like the app's _humanizedLabel."""
    words = re.sub(r"[-_]+", " ", value).split()
    return " ".join(
        word if len(word) <= 2 and word == word.upper() else word[0].upper() + word[1:]
        for word in words
    )


def label_from(values):
    """The first non-empty value, tidied up for display."""
    found = first_text(values)
    return humanize(found) if found else ""


def first_from_list(value):
    if isinstance(value, list):
        return first_text(value)
    return ""


def displayable_id(record_id):
    """Firebase's random IDs (like "00KXUtAV2cdNIha4fsoP") are not shown as names."""
    return "" if re.fullmatch(r"[A-Za-z0-9]{16,}", record_id) else record_id


def lookup_key(value):
    return re.sub(r"[^a-z0-9]+", "", text(value).lower())


def first_number(values):
    for value in values:
        if isinstance(value, bool):
            continue
        if isinstance(value, (int, float)):
            return float(value)
        try:
            return float(text(value))
        except ValueError:
            continue
    return None


def is_active(data, default=True):
    """Hidden records (status other than "active", or is_active false) are skipped."""
    status = text(data.get("status")).lower()
    if status:
        return status == "active"
    active = data.get("is_active")
    return active if isinstance(active, bool) else default


def bucket_from_text(value):
    """Which category a record belongs to, worked out from its text."""
    value = value.lower()
    if "food" in value or "drink" in value:
        return "food"
    if "health" in value or "wellbeing" in value:
        return "health"
    if "network" in value:
        return "networking"
    if "music" in value:
        return "music"
    if "event" in value:
        return "events"
    return "activities"


def canonical_subcategory(label):
    if lookup_key(label) in ("panasian", "asianpanasian"):
        return "Pan Asian"
    return "" if label.strip() in ("111", "1111") else label


def image_source(data, fallback=None):
    """The record's photo: a web address or a photo stored inside the record."""
    names = [
        "imageUrl", "image_url", "imageURL", "image", "coverImageUrl",
        "cover_image_url", "coverImage", "cover_image", "bannerUrl", "banner_url",
        "posterUrl", "poster_url", "logoUrl", "logo_url", "photoUrl", "photo_url",
        "thumbnailUrl", "thumbnail_url", "thumbnail",
    ]
    fallback = fallback or {}
    return first_text([data.get(name) for name in names] + [fallback.get(name) for name in names])


def price_value(data, posts, events):
    for source in (events, posts, data):
        for name in ("price", "price_from", "priceFrom", "price_range", "priceRange"):
            if source.get(name) is not None:
                return source.get(name)
    return None


def currency(data, posts, events):
    names = ["priceCurrency", "price_currency", "currency", "currencyCode"]
    return first_text([events.get(n) for n in names] + [data.get(n) for n in names] + [posts.get(n) for n in names])


def price_label(value, currency_code):
    """"45" + "GBP" -> "£45", "free" -> "Free" (same as the app)."""
    label = text(value)
    if not label:
        return ""
    label = re.sub(r"^price\s*:\s*", "", label, flags=re.IGNORECASE)
    if label.lower() == "free":
        return "Free"
    label = re.sub(r"^[$€£¥₹]\s*", "", label)
    label = re.sub(r"^(USD|EUR|EURO|GBP|POUND|PKR|AED|INR)\s*", "", label, flags=re.IGNORECASE)
    code = text(currency_code)
    if not code:
        symbol = "£"
    elif not re.fullmatch(r"[A-Za-z]+", code):
        symbol = code
    else:
        symbol = CURRENCY_SYMBOLS.get(code.upper(), code.upper() + " ")
    return symbol + label


def links(data, posts, events):
    """Website, map and ticket links, found the same way as the app."""
    link_list = as_maps(data.get("links")) + as_maps(posts.get("links")) + as_maps(events.get("links"))

    def looks_like_map(value):
        return any(word in value for word in ("map", "maps.google", "google.com/maps", "place_id:")) or value.startswith("geo:")

    def looks_like_ticket(value):
        return any(word in value for word in ("ticket", "booking", "book now", "reservation", "reserve"))

    def matches(label, url, kind):
        value = f"{label} {url}".lower()
        if kind == "map":
            return looks_like_map(value)
        if kind == "ticket":
            return looks_like_ticket(value)
        return not looks_like_map(value) and not looks_like_ticket(value)

    def from_list(kind):
        for link in link_list:
            label = first_text([link.get("name"), link.get("label"), link.get("title"), link.get("type")])
            url = first_text([link.get("url"), link.get("href"), link.get("link"), link.get("value")])
            if url and matches(label, url, kind):
                return url
        return ""

    def direct(kind):
        for url in (text(data.get("url")), text(posts.get("url")), text(events.get("url"))):
            if url and matches("", url, kind):
                return url
        return ""

    def named(*names):
        return first_text([source.get(name) for source in (data, posts, events) for name in names])

    return {
        "website": first_text([from_list("website"), named("websiteLink", "websiteUrl", "website"), direct("website")]),
        "map": first_text([from_list("map"), named("mapLink", "googleMapLink", "googleMapsLink", "googleMapsUrl", "mapsUrl", "google_maps_url"), direct("map")]),
        "ticket": first_text([from_list("ticket"), named("ticketLink", "ticketUrl", "bookingLink", "bookingUrl"), direct("ticket")]),
    }


def iso_date(value):
    """A date as "2026-11-05T19:00:00Z" text, or "" if there isn't one."""
    raw = text(value)
    if not raw:
        return ""
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00")).astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    except ValueError:
        return ""


def as_bool(value):
    return value is True or text(value).lower() in ("true", "yes", "1")


def find_area(*texts):
    """The London area named in any of these texts, or "" if none is."""
    combined = " ".join(texts).lower()
    for area in sorted(LONDON_AREAS, key=len, reverse=True):
        pattern = r"\b" + re.escape(area.lower()) + r"\b"   # whole words only
        if re.search(pattern, combined):
            return {"Kings Cross": "King's Cross", "South Bank": "Southbank", "North Greenwich": "Greenwich", "The O2": "Greenwich"}.get(area, area)
    return ""


def tag_labels(values):
    labels = []

    def add(raw):
        if raw is None:
            return
        if isinstance(raw, list):
            for item in raw:
                add(item)
            return
        if isinstance(raw, dict):
            add([raw.get(n) for n in ("tagName", "tag_name", "name", "title", "label", "value", "id", "tagId", "tag_id")])
            return
        label = label_from([raw])
        if label and label not in labels:
            labels.append(label)

    add(values)
    return labels


# ---------------------------------------------------------------------------
# Photos
# ---------------------------------------------------------------------------

# Photos already made during this run, so a photo used by several listings
# is only saved once (many listings in Firebase share the same photo).
made_images = {}


def save_image(source, label):
    """Turns one photo into WebP files (one per width in IMAGE_WIDTHS) and
    gives back what the pages need: the file names, the photo's shape and a
    short "fingerprint" that is the same for identical photos.
    "label" is only used in error messages.
    Gives back None if there is no photo or it can't be read."""
    if not source:
        return None
    try:
        if source.startswith("data:"):
            raw = base64.b64decode(source.split(",", 1)[1])
        elif source.startswith("http"):
            request = urllib.request.Request(source, headers={"User-Agent": "Chillingz website export"})
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
        else:
            return None
        fingerprint = hashlib.sha1(raw).hexdigest()[:12]
        if fingerprint in made_images:
            return made_images[fingerprint]
        picture = Image.open(io.BytesIO(raw))
        picture = picture.convert("RGBA" if picture.mode in ("RGBA", "LA", "P") else "RGB")
    except Exception as error:  # a broken photo shouldn't stop the whole export
        print(f"  ! could not read photo for {label}: {error}", file=sys.stderr)
        return None

    files = {}
    for width in IMAGE_WIDTHS:
        # Never make a photo bigger than it really is (it would look blurry):
        # a 720px photo gives a 480px and a 720px version.
        target_width = min(width, picture.width)
        if target_width in files:
            continue
        target_height = round(picture.height * target_width / picture.width)
        resized = picture.resize((target_width, target_height), Image.LANCZOS)
        name = f"{fingerprint}-{target_width}.webp"
        resized.save(IMAGE_DIR / name, "WEBP", quality=WEBP_QUALITY, method=6)
        files[target_width] = f"images/content/{name}"

    smallest = min(files)
    made_images[fingerprint] = {
        "src": files[smallest],
        "srcset": ", ".join(f"{path} {width}w" for width, path in sorted(files.items())),
        "width": picture.width,
        "height": picture.height,
        "fingerprint": fingerprint,
    }
    return made_images[fingerprint]


# ---------------------------------------------------------------------------
# Turning records into listings
# ---------------------------------------------------------------------------

def make_listing(record_id, data, source, bucket, title, category_name, posts=None, events=None):
    """Builds one tidy listing. "record_id" is kept exactly as it is in
    Firebase, because the app saves favourites using that ID."""
    posts = posts or {}
    events = events or {}
    venue = as_map(data.get("venue"))
    venue_name = label_from([
        data.get("venueName"), data.get("venue_name"), venue.get("name"), venue.get("title"),
        venue.get("venue"), as_map(data.get("location")).get("name"),
        posts.get("venueName"), posts.get("venue_name"), as_map(posts.get("venue")).get("name"),
        events.get("venueName"), events.get("venue_name"), as_map(events.get("venue")).get("name"),
    ])
    subcategory = canonical_subcategory(label_from([
        first_from_list(data.get("subcategory_names")), first_from_list(data.get("subcategories")),
        data.get("subcategoryName"), data.get("subCategoryName"), data.get("subcategory"),
        data.get("subCategory"), data.get("parentSubcategory"),
        posts.get("subcategoryName"), posts.get("subcategory"),
    ]))
    price = price_value(data, posts, events)
    rating = first_number([posts.get("review"), events.get("review"), data.get("review"), data.get("avg_rating"), data.get("rating")])
    address = ", ".join(part for part in (
        text(venue.get("addressLine1")), text(venue.get("addressLine2")),
        text(venue.get("address")), text(venue.get("postcode")),
    ) if part)

    return {
        "id": record_id,
        "source": source,
        "category": CATEGORY_SLUGS[bucket],
        "categoryName": category_name,
        "title": title,
        "subtitle": text(data.get("subtitle")),
        "description": first_text([data.get("description"), posts.get("description"), events.get("description"), venue.get("description")]),
        "subcategory": subcategory,
        "type": label_from([data.get("activity_type"), data.get("activityType"), data.get("type"), data.get("venueType")]),
        "tags": tag_labels([data.get("tags"), data.get("tagNames"), data.get("interestTags"), posts.get("tags"), events.get("tags")]),
        "venueName": venue_name,
        "address": address,
        "city": first_text([data.get("city"), venue.get("city"), as_map(data.get("location")).get("city"), posts.get("city"), events.get("city")]) or "London",
        "lat": first_number([data.get("latitude"), data.get("lat"), venue.get("latitude"), venue.get("lat"), posts.get("latitude"), events.get("latitude")]),
        "lng": first_number([data.get("longitude"), data.get("lng"), venue.get("longitude"), venue.get("lng"), posts.get("longitude"), events.get("longitude")]),
        "area": find_area(title, venue_name, address),
        "phone": text(venue.get("phone")),
        "priceLabel": price_label(price, currency(data, posts, events)),
        "priceFrom": first_number([price]),
        "priceRange": text(data.get("price_range")),
        "rating": rating if rating else None,
        "reviewCount": int(first_number([data.get("review_count"), venue.get("reviews")]) or 0),
        "isFeatured": as_bool(data.get("is_featured")),
        "isNew": as_bool(data.get("is_new")),
        "date": iso_date(first_text([events.get("date"), data.get("date"), data.get("startDate"), data.get("eventDate"), data.get("available_from"), posts.get("date")])),
        "time": first_text([data.get("start_time"), data.get("time"), data.get("eventTime"), data.get("startTime"), events.get("time"), posts.get("time")]),
        "links": links(data, posts, events),
        "createdAt": iso_date(data.get("createdAt")),
        "_image": image_source(events) or image_source(data, posts),
    }


def listings_from_content(records):
    """The "subcategoriesContent" collection: most of the app's listings."""
    listings = []
    for record_id, data in records:
        if not is_active(data):
            continue
        bucket = bucket_from_text(" ".join(text(data.get(n)) for n in ("content_type", "category_id", "category_name", "parentCategory")))
        title = label_from([
            data.get("singerName"), data.get("artistName"), data.get("userName"), data.get("name"),
            data.get("title"), data.get("description"), data.get("slug"), displayable_id(record_id),
        ])
        if not title:
            continue
        category_name = first_text([data.get("activity_type"), data.get("category_name"), data.get("content_type")])
        listings.append(make_listing(record_id, data, "content", bucket, title, category_name))
    return listings


def listings_from_listing_categories(records):
    """The "listingCategories" collection (not used yet, but the app reads it)."""
    listings = []
    for record_id, data in records:
        posts = as_map(data.get("posts"))
        if not is_active(data) or not is_active(posts):
            continue
        bucket = bucket_from_text(" ".join(text(data.get(n)) for n in ("categoryName", "categoryId", "listingName")))
        title = label_from([posts.get("title"), posts.get("name"), data.get("title"), data.get("name"), data.get("listingName"), data.get("slug"), displayable_id(record_id)])
        if not title:
            continue
        category_name = label_from([data.get("listingName"), data.get("categoryName")])
        listings.append(make_listing(record_id, data, "listing", bucket, title, category_name, posts=posts))
    return listings


def listings_from_genres(records):
    """The "genres" collection: music and event listings."""
    listings = []
    for record_id, data in records:
        posts = as_map(data.get("posts"))
        events = as_map(data.get("events"))
        if not is_active(data) or not is_active(posts):
            continue
        genre = label_from([posts.get("singerName"), posts.get("name"), posts.get("title"), events.get("name"), events.get("title"), data.get("name"), data.get("title"), data.get("displayName"), displayable_id(record_id)])
        title = label_from([events.get("name"), events.get("title"), genre, displayable_id(record_id)]) or "Music"
        feature = text(events.get("feature")).lower()
        bucket = "music" if "feature" in feature or "music" in text(data.get("category_id")) else "events"
        listings.append(make_listing(record_id, data, "genre", bucket, title, genre, posts=posts, events=events))
    return listings


def categories_from(records):
    categories = []
    for record_id, data in records:
        slug = first_text([data.get("slug"), data.get("id"), record_id])
        categories.append({
            "slug": slug,
            "name": label_from([data.get("name"), slug]),
            "tagline": text(data.get("tagline")),
            "active": is_active(data),
            "_image": image_source(data),
        })
    return sorted(categories, key=lambda item: item["name"])


def subcategories_from(records):
    subcategories = []
    seen = set()
    for record_id, data in records:
        if not is_active(data):
            continue
        name = canonical_subcategory(label_from([
            data.get("subcategoryName"), data.get("subcategory_name"), data.get("subCategoryName"),
            data.get("name"), data.get("title"), data.get("displayName"), data.get("slug"), displayable_id(record_id),
        ]))
        parent = label_from([data.get("parentCategory"), data.get("category_name"), data.get("categoryName"), data.get("category"), data.get("category_id"), data.get("categoryId"), data.get("content_type")])
        category = CATEGORY_SLUGS[bucket_from_text(parent)]
        key = (category, lookup_key(name))
        if not name or key in seen:
            continue
        seen.add(key)
        subcategories.append({
            "id": first_text([data.get("slug"), record_id]),
            "name": name,
            "category": category,
            "_image": image_source(data),
        })
    return sorted(subcategories, key=lambda item: (item["category"], item["name"].lower()))


def tags_from(records):
    labels = {label_from([data.get("tagName"), data.get("name"), data.get("title"), data.get("slug")]) for _, data in records if is_active(data)}
    return sorted(label for label in labels if label)


# ---------------------------------------------------------------------------
# Sitemap and robots.txt (help search engines find every page)
# ---------------------------------------------------------------------------

def slugs_from_data_js(list_name):
    """Reads the guide or blog post slugs from js/data.js (e.g. GUIDES)."""
    source = (WEBSITE_DIR / "js" / "data.js").read_text(encoding="utf-8")
    match = re.search(r"export const " + list_name + r" = \[(.*?)\n\];", source, re.S)
    return re.findall(r'slug: "([^"]+)"', match.group(1)) if match else []


def write_sitemap(listings, categories):
    """Writes sitemap.xml: every public page, listing and guide."""
    today = datetime.now(timezone.utc).date().isoformat()
    addresses = [SITE_URL + page for page in SITEMAP_PAGES]
    addresses += [f"{SITE_URL}search.html?category={c['slug']}" for c in categories if c["active"]]
    for item in listings:
        page = "event.html" if item["date"] or item["category"] == "events" else "venue.html"
        addresses.append(f"{SITE_URL}{page}?id={urllib.parse.quote(item['id'])}")
    addresses += [f"{SITE_URL}article.html?guide={slug}" for slug in slugs_from_data_js("GUIDES")]
    addresses += [f"{SITE_URL}article.html?post={slug}" for slug in slugs_from_data_js("POSTS")]

    entries = "\n".join(
        f"  <url><loc>{address.replace('&', '&amp;')}</loc><lastmod>{today}</lastmod></url>"
        for address in addresses
    )
    (WEBSITE_DIR / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        f"{entries}\n</urlset>\n",
        encoding="utf-8",
    )
    (WEBSITE_DIR / "robots.txt").write_text(
        "# Search engines may visit every page except personal ones\n"
        "User-agent: *\n"
        f"Disallow: {urllib.parse.urlparse(SITE_URL).path}account.html\n"
        f"\nSitemap: {SITE_URL}sitemap.xml\n",
        encoding="utf-8",
    )
    return len(addresses)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("Reading from Firebase...")
    collections = {
        name: read_collection(name)
        for name in ("categories", "subcategories", "subcategoriesContent", "listingCategories", "genres", "tags")
    }
    for name, records in collections.items():
        print(f"  {name}: {len(records)}")

    listings = (
        listings_from_content(collections["subcategoriesContent"])
        + listings_from_listing_categories(collections["listingCategories"])
        + listings_from_genres(collections["genres"])
    )
    categories = categories_from(collections["categories"])
    subcategories = subcategories_from(collections["subcategories"])

    # Start with an empty photo folder so deleted listings don't leave old photos
    shutil.rmtree(IMAGE_DIR, ignore_errors=True)
    IMAGE_DIR.mkdir(parents=True)

    print("Making photos...")
    for item in listings:
        item["image"] = save_image(item.pop("_image"), item["title"])
    for item in categories:
        item["image"] = save_image(item.pop("_image"), item["name"])
    for item in subcategories:
        item["image"] = save_image(item.pop("_image"), item["name"])

    output = {
        "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "categories": categories,
        "subcategories": subcategories,
        "tags": tags_from(collections["tags"]),
        "listings": listings,
    }
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    DATA_FILE.write_text(json.dumps(output, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    photo_bytes = sum(path.stat().st_size for path in IMAGE_DIR.glob("*.webp"))
    pages = write_sitemap(listings, categories)
    print(f"  sitemap.xml: {pages} pages (site address {SITE_URL})")
    print(f"Done: {len(listings)} listings, {len(categories)} categories, {len(subcategories)} subcategories")
    print(f"  {DATA_FILE.relative_to(WEBSITE_DIR.parent)}: {DATA_FILE.stat().st_size // 1024} KB")
    print(f"  photos: {len(list(IMAGE_DIR.glob('*.webp')))} files, {photo_bytes // 1024} KB")


if __name__ == "__main__":
    main()
