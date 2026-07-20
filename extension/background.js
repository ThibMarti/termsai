// Manifest V3 service worker.
//
// Phase 5: badge/icon state — colors the toolbar icon with the last scan's
// risk tone for the tab it ran on, so the result is visible without opening
// the popup. Phase 3's popup will call this once a real scan comes back
// from POST /api/v1/scans; wired here ahead of time so that message shape
// is ready to use.

const BADGE_COLORS = {
  risk: "#B4231F",
  caution: "#A35A08",
  safe: "#1A6E3C",
};

chrome.runtime.onInstalled.addListener(() => {
  console.log("terms AI extension installed");
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  switch (message?.type) {
    case "terms-ai:set-badge":
      setBadge(message.tabId, message.tone, message.score);
      sendResponse({ set: true });
      return false;

    case "terms-ai:clear-badge":
      clearBadge(message.tabId);
      sendResponse({ cleared: true });
      return false;

    default:
      return false;
  }
});

// A scan result shouldn't linger once the user has moved to a new page.
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status === "loading") clearBadge(tabId);
});

function setBadge(tabId, tone, score) {
  if (!tabId) return;
  const color = BADGE_COLORS[tone] || BADGE_COLORS.caution;
  chrome.action.setBadgeText({ tabId, text: score != null ? String(score) : "•" });
  chrome.action.setBadgeBackgroundColor({ tabId, color });
}

function clearBadge(tabId) {
  if (!tabId) return;
  chrome.action.setBadgeText({ tabId, text: "" });
}
