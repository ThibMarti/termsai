// Content script — text extraction + in-page clause highlighting.
// Talks to the popup via chrome.runtime.onMessage; the popup sends
// messages through chrome.tabs.sendMessage(tabId, message) since it knows
// the active tab's id (see popup/popup.js).
//
// Phase 1 (backend) isn't wired up yet, so nothing here calls the API —
// this only handles the page-side half: pulling text out, and drawing
// highlights once a full_report comes back from wherever the popup got it.

const HIGHLIGHT_TONES = ["risk", "caution", "safe"];

// A T&C/Privacy Policy is realistically a few thousand words; this caps
// what we send to the API to keep requests small and predictable rather
// than shipping an entire single-page-app's worth of text on outlier pages.
const MAX_EXTRACT_LENGTH = 20000;
const MIN_EXTRACT_LENGTH = 40; // below this, treat the page as "nothing to scan"

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  switch (message?.type) {
    case "terms-ai:extract-text":
      sendResponse(extractText());
      return false; // synchronous response

    case "terms-ai:highlight-clauses":
      highlightClauses(message.clauses || []);
      sendResponse({ highlighted: true });
      return false;

    case "terms-ai:clear-highlights":
      clearHighlights();
      sendResponse({ cleared: true });
      return false;

    case "terms-ai:scroll-to-clause":
      scrollToClause(message.index);
      sendResponse({ scrolled: true });
      return false;

    default:
      return false;
  }
});

// Returns { text, empty, truncated } rather than a bare string so Phase 3's
// popup can show "nothing to scan here" / "page was long, we trimmed it"
// instead of silently sending a blank or oversized request.
function extractText() {
  const raw = document.body.innerText.trim();

  if (raw.length < MIN_EXTRACT_LENGTH) {
    return { text: raw, empty: true, truncated: false };
  }

  if (raw.length > MAX_EXTRACT_LENGTH) {
    return { text: raw.slice(0, MAX_EXTRACT_LENGTH), empty: false, truncated: true };
  }

  return { text: raw, empty: false, truncated: false };
}

function clearHighlights() {
  document.querySelectorAll("mark.terms-ai-highlight").forEach((mark) => {
    const parent = mark.parentNode;
    if (!parent) return;
    parent.replaceChild(document.createTextNode(mark.textContent), mark);
    parent.normalize();
  });
}

// Wraps the first occurrence of each clause's exact quote text in a
// tone-colored <mark>. Plain string search only (per the task plan's v1
// scope) — good enough when the quote sits inside a single text node;
// quotes that straddle inline markup (e.g. "<b>waive</b> your right") are a
// known gap, left for a follow-up rather than pulling in a fuzzy matcher.
function highlightClauses(clauses) {
  clearHighlights();

  clauses.forEach(({ quote, tone }, index) => {
    if (!quote) return;
    const range = findTextRange(document.body, quote);
    if (!range) return;

    const mark = document.createElement("mark");
    const safeTone = HIGHLIGHT_TONES.includes(tone) ? tone : "caution";
    mark.className = `terms-ai-highlight terms-ai-highlight--${safeTone}`;
    mark.dataset.termsAiIndex = String(index);
    range.surroundContents(mark);
  });
}

function scrollToClause(index) {
  const mark = document.querySelector(`mark.terms-ai-highlight[data-terms-ai-index="${index}"]`);
  mark?.scrollIntoView({ behavior: "smooth", block: "center" });
}

// Walks text nodes (skipping <script>/<style> and already-highlighted
// marks) to find a Range spanning the given substring. Range.surroundContents
// needs a range fully inside one text node, so cross-node quotes are
// skipped rather than mis-highlighted.
function findTextRange(root, needle) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const parent = node.parentElement;
      if (!parent || parent.closest("script, style, mark.terms-ai-highlight")) {
        return NodeFilter.FILTER_REJECT;
      }
      return NodeFilter.FILTER_ACCEPT;
    },
  });

  let node;
  while ((node = walker.nextNode())) {
    const index = node.textContent.indexOf(needle);
    if (index === -1) continue;

    const range = document.createRange();
    range.setStart(node, index);
    range.setEnd(node, index + needle.length);
    return range;
  }

  return null;
}
