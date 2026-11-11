/* ==========================================================================
   motion.js — smooth scrolling (Lenis) and scroll animations (GSAP)
   --------------------------------------------------------------------------
   site.js starts this on every page. Both libraries load from a CDN after
   the page is ready, so if they fail to load the site still works normally.
   Visitors whose device asks for less animation get neither.

   To animate something, wait for the libraries:
     import { motionReady } from "./motion.js";
     motionReady.then((motion) => {
       if (!motion) return; // reduced motion, or the CDN didn't load
       motion.gsap.from(".hero h1", { y: 40, opacity: 0, scrollTrigger: ".hero" });
     });
   ========================================================================== */

const GSAP_CDN = "https://cdn.jsdelivr.net/npm/gsap@3.15.0";
const LENIS_CDN = "https://cdn.jsdelivr.net/npm/lenis@1.3.27/dist/lenis.mjs";

async function startMotion() {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return null;

  const [{ gsap }, { ScrollTrigger }, { default: Lenis }] = await Promise.all([
    import(`${GSAP_CDN}/index.js`),
    import(`${GSAP_CDN}/ScrollTrigger.js`),
    import(LENIS_CDN),
  ]);
  gsap.registerPlugin(ScrollTrigger);

  // Scroll areas inside pop-ups and the mobile menu keep scrolling normally.
  const lenis = new Lenis({ autoRaf: false, allowNestedScroll: true });
  // One animation clock for both, so scroll effects never lag behind the scroll.
  lenis.on("scroll", ScrollTrigger.update);
  gsap.ticker.add((time) => lenis.raf(time * 1000));
  gsap.ticker.lagSmoothing(0);

  return { gsap, ScrollTrigger, lenis };
}

export const motionReady = startMotion().catch((error) => {
  console.error("Animations not available", error);
  return null;
});
