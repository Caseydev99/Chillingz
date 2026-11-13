// Run with: node --test
const assert = require("node:assert");
const { test } = require("node:test");
const { nextSentTimes } = require("./throttle");

const MIN = 60 * 1000;
const now = 10 * 24 * 60 * MIN;

test("first email is allowed", () => {
  assert.deepStrictEqual(nextSentTimes(undefined, now), [now]);
});

test("a second email inside a minute is refused", () => {
  assert.strictEqual(nextSentTimes([now - MIN + 1], now), null);
  assert.deepStrictEqual(nextSentTimes([now - MIN], now), [now - MIN, now]);
});

test("a sixth email inside a day is refused", () => {
  const five = [50, 40, 30, 20, 10].map((minutes) => now - minutes * MIN);
  assert.strictEqual(nextSentTimes(five, now), null);
});

test("emails older than a day are forgotten", () => {
  const old = [1, 2, 3, 4, 5].map((n) => now - 25 * 60 * MIN - n);
  assert.deepStrictEqual(nextSentTimes(old, now), [now]);
});
