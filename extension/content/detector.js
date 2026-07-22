// Heuristic: does this page look like a Terms & Conditions / Privacy Policy
// page? Runs once when the content script loads (see banner.js). Two tiers,
// combined with OR:
//
// - URL tokens: a dedicated path segment (e.g. /terms, /privacy-policy) is a
//   strong, deliberate signal on its own, so single words are trusted here.
// - Title/heading phrases: only matched as full phrases (e.g. "terms of
//   service"), never single words — a lone "terms" in a <title> is more
//   accident-prone, and this tier never scans body/nav text, which is what
//   would otherwise catch an unrelated nav link mentioning "terms".

const URL_TOKEN_PATTERNS = [
  /\bterms-of-service\b/,
  /\bterms-and-conditions\b/,
  /\bterms\b/,
  /\btos\b/,
  /\bprivacy\b/,
  /\blegal\b/,
  /\beula\b/,
  /\bcookie-policy\b/,
  /\buser-agreement\b/,
  /\bdata-policy\b/,
];

const TITLE_PHRASES = [
  "terms of service",
  "terms and conditions",
  "privacy policy",
  "cookie policy",
  "user agreement",
  "end user license agreement",
];

function looksLikeTermsPage() {
  const url = `${location.hostname}${location.pathname}`.toLowerCase();
  if (URL_TOKEN_PATTERNS.some((pattern) => pattern.test(url))) return true;

  const heading = document.querySelector("h1")?.innerText || "";
  const text = `${document.title} ${heading}`.toLowerCase();
  return TITLE_PHRASES.some((phrase) => text.includes(phrase));
}
