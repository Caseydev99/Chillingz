/* ==========================================================================
   favourites.js — the heart buttons and recent searches
   --------------------------------------------------------------------------
   How it works:
   • Guests: favourites and recent searches are kept in this browser only.
   • Logged-in people: favourites are saved in their account in Firebase, in
     the SAME list the app uses (users/{id}.savedItemIds). So a heart tapped
     on the website shows up in the app, and the other way round.
   • When a guest logs in or signs up, everything they saved as a guest is
     moved into their account, then the browser copy is cleared.

   Any button on any page becomes a heart button if it has
     data-favourite-id="<listing id>"
   This file keeps those buttons up to date and handles the clicks.
   ========================================================================== */

import { storage, showToast } from "./utils.js";
import { loadFirestore } from "./firebase.js";

const GUEST_FAVOURITES_KEY = "chillingz.guestFavourites";
const RECENT_SEARCHES_KEY = "chillingz.recentSearches";
const MAX_RECENT_SEARCHES = 8;

// The favourites currently shown on the page (a Set is a list with no repeats)
let favouriteIds = new Set(storage.get(GUEST_FAVOURITES_KEY, []));

// The logged-in person, or null for a guest. auth.js keeps this up to date.
let currentUser = null;


/* --------------------------------------------------------------------------
   Reading favourites
   -------------------------------------------------------------------------- */

/* Is this listing one of the visitor's favourites? */
export function isFavourite(id) {
  return favouriteIds.has(id);
}

/* All favourite listing ids, e.g. for the "My Favourites" page. */
export function getFavouriteIds() {
  return [...favouriteIds];
}


/* --------------------------------------------------------------------------
   Changing favourites
   -------------------------------------------------------------------------- */

/* Adds or removes one favourite. For logged-in people it is saved to their
   account straight away; if that fails, the change is undone on screen. */
export async function toggleFavourite(id) {
  const wasFavourite = favouriteIds.has(id);
  if (wasFavourite) {
    favouriteIds.delete(id);
  } else {
    favouriteIds.add(id);
  }
  updateHeartButtons();
  showToast(wasFavourite ? "Removed from favourites" : "Saved to favourites");

  // Guest: just remember it in this browser
  if (!currentUser) {
    storage.set(GUEST_FAVOURITES_KEY, [...favouriteIds]);
    return;
  }

  // Logged in: save to the account, in the same way the app does
  try {
    const { db, doc, setDoc, arrayUnion, arrayRemove } = await loadFirestore();
    await setDoc(
      doc(db, "users", currentUser.uid),
      {
        savedItemIds: wasFavourite ? arrayRemove(id) : arrayUnion(id),
        lastActive: new Date().toISOString(),
      },
      { merge: true },
    );
  } catch (error) {
    console.error("Could not save favourite", error);
    // Put it back how it was, so the screen matches what is really saved
    if (wasFavourite) {
      favouriteIds.add(id);
    } else {
      favouriteIds.delete(id);
    }
    updateHeartButtons();
    showToast("Sorry, that didn't save. Please try again.");
  }
}


/* --------------------------------------------------------------------------
   Logging in and out (called by auth.js)
   -------------------------------------------------------------------------- */

/* Called whenever someone logs in or out.
   On log in: load their saved favourites from their account, and move any
   guest favourites and recent searches into the account. */
export async function onUserChanged(user) {
  currentUser = user;

  // Logged out: go back to whatever is saved in this browser
  if (!user) {
    favouriteIds = new Set(storage.get(GUEST_FAVOURITES_KEY, []));
    updateHeartButtons();
    return;
  }

  try {
    const { db, doc, getDoc, setDoc, arrayUnion } = await loadFirestore();
    const userRef = doc(db, "users", user.uid);
    const snapshot = await getDoc(userRef);
    const saved = snapshot.exists() ? snapshot.data().savedItemIds ?? [] : [];

    const guestFavourites = storage.get(GUEST_FAVOURITES_KEY, []);
    const guestSearches = storage.get(RECENT_SEARCHES_KEY, []);

    // Move guest items into the account (arrayUnion skips any already there)
    if (guestFavourites.length || guestSearches.length) {
      const update = {};
      if (guestFavourites.length) update.savedItemIds = arrayUnion(...guestFavourites);
      if (guestSearches.length) update.webRecentSearches = arrayUnion(...guestSearches);
      await setDoc(userRef, update, { merge: true });
      storage.remove(GUEST_FAVOURITES_KEY);
      if (guestFavourites.length) {
        showToast(`${guestFavourites.length} saved ${guestFavourites.length === 1 ? "favourite" : "favourites"} added to your account`);
      }
    }

    favouriteIds = new Set([...saved, ...guestFavourites]);
    updateHeartButtons();
    document.dispatchEvent(new CustomEvent("chillingz:favourites"));
  } catch (error) {
    console.error("Could not load favourites", error);
  }
}


/* --------------------------------------------------------------------------
   Recent searches (kept in the browser; copied into the account on login)
   -------------------------------------------------------------------------- */

/* Remembers a search, newest first, without repeats. */
export function addRecentSearch(text) {
  const searches = storage
    .get(RECENT_SEARCHES_KEY, [])
    .filter((item) => item.toLowerCase() !== text.toLowerCase());
  searches.unshift(text);
  storage.set(RECENT_SEARCHES_KEY, searches.slice(0, MAX_RECENT_SEARCHES));
}

/* The visitor's recent searches, newest first. */
export function getRecentSearches() {
  return storage.get(RECENT_SEARCHES_KEY, []);
}


/* --------------------------------------------------------------------------
   Heart buttons on the page
   -------------------------------------------------------------------------- */

/* Makes every heart button show the right state (filled = saved). */
export function updateHeartButtons() {
  document.querySelectorAll("[data-favourite-id]").forEach((button) => {
    const saved = favouriteIds.has(button.dataset.favouriteId);
    button.setAttribute("aria-pressed", String(saved));
    button.classList.toggle("is-saved", saved);
  });
}

/* Sets up the heart buttons. One click listener on the page handles every
   heart, including ones added later when listings load. */
export function initFavourites() {
  document.addEventListener("click", (event) => {
    const button = event.target.closest("[data-favourite-id]");
    if (!button) return;
    event.preventDefault();
    toggleFavourite(button.dataset.favouriteId);
  });
  updateHeartButtons();
}
