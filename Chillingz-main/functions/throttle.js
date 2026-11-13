// Limits how often one email address can be sent a password reset email:
// at most one a minute and five a day.
const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * MINUTE_MS;
const MAX_PER_DAY = 5;

// Given the times (ms) of earlier emails, returns the updated list if another
// email may be sent now, or null if it may not.
function nextSentTimes(sentAt, now) {
  const recent = (Array.isArray(sentAt) ? sentAt : [])
    .filter((time) => now - time < DAY_MS);
  const last = recent[recent.length - 1];
  if (recent.length >= MAX_PER_DAY || now - last < MINUTE_MS) {
    return null;
  }
  return [...recent, now];
}

module.exports = { nextSentTimes };
