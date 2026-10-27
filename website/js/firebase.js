/* ==========================================================================
   firebase.js — connects the website to your app's Firebase project
   --------------------------------------------------------------------------
   The settings below are the app's public "web" settings (the same ones in
   Chillingz-main/lib/firebase_options.dart). They are safe to put in website
   code: they only say WHICH project to talk to. What people are allowed to
   read or change is controlled by the rules in firestore.rules.

   To keep pages fast, the Firebase code is only downloaded the first time
   something needs it (for example when checking whether someone is logged in).
   ========================================================================== */

const FIREBASE_VERSION = "12.4.0";
const FIREBASE_CDN = `https://www.gstatic.com/firebasejs/${FIREBASE_VERSION}`;

const firebaseConfig = {
  apiKey: "AIzaSyBo3d9_sMFWuOd-mkyTV91DSPe4puM2dOk",
  appId: "1:695269406899:web:dfeffb9177d1d847ad18c6",
  messagingSenderId: "695269406899",
  projectId: "chillingz-dca92",
  authDomain: "chillingz-dca92.firebaseapp.com",
  storageBucket: "chillingz-dca92.firebasestorage.app",
};

// Remember the loaded pieces so they are only downloaded once per page.
let appPromise = null;
let authPromise = null;
let firestorePromise = null;
let functionsPromise = null;

/* Starts the Firebase app (only once). */
function loadApp() {
  if (!appPromise) {
    appPromise = import(`${FIREBASE_CDN}/firebase-app.js`).then((module) =>
      module.initializeApp(firebaseConfig),
    );
  }
  return appPromise;
}

/* Gives back the login tools: the "auth" object plus every login function
   the site uses (sign in, sign up, sign out…). */
export function loadAuth() {
  if (!authPromise) {
    authPromise = Promise.all([
      loadApp(),
      import(`${FIREBASE_CDN}/firebase-auth.js`),
    ]).then(([app, authModule]) => ({
      ...authModule,
      auth: authModule.getAuth(app),
    }));
  }
  return authPromise;
}

/* Gives back the database tools: the "db" object plus functions such as
   doc(), getDoc(), setDoc() and arrayUnion(). */
export function loadFirestore() {
  if (!firestorePromise) {
    firestorePromise = Promise.all([
      loadApp(),
      import(`${FIREBASE_CDN}/firebase-firestore.js`),
    ]).then(([app, firestoreModule]) => ({
      ...firestoreModule,
      db: firestoreModule.getFirestore(app),
    }));
  }
  return firestorePromise;
}

/* Gives back a way to call the app's Cloud Functions (used for the
   "forgot password" email, exactly like the app does). */
export function loadFunctions() {
  if (!functionsPromise) {
    functionsPromise = Promise.all([
      loadApp(),
      import(`${FIREBASE_CDN}/firebase-functions.js`),
    ]).then(([app, functionsModule]) => ({
      ...functionsModule,
      functions: functionsModule.getFunctions(app),
    }));
  }
  return functionsPromise;
}
