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

const APP_ORIGIN = "http://localhost:3000"; // TODO(team): keep in sync with popup/popup.js's APP_ORIGIN

chrome.runtime.onInstalled.addListener(() => {
  console.log("terms AI extension installed");
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message?.type) {
    case "terms-ai:set-badge":
      setBadge(message.tabId, message.tone, message.score);
      sendResponse({ set: true });
      return false;

    case "terms-ai:clear-badge":
      clearBadge(message.tabId);
      sendResponse({ cleared: true });
      return false;

    case "terms-ai:run-scan":
      runScan(message, sender.tab?.id).then(sendResponse);
      return true; // keep the message channel open for the async response

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

// Runs the same scan request popup.js's analyze() makes, but from the
// service worker so the fetch isn't subject to the visited page's CSP
// (unlike a fetch made directly from a content script/banner).
async function runScan({ url, title, content }, tabId) {
  const { termsAiToken } = await chrome.storage.local.get("termsAiToken");
  if (!termsAiToken) {
    return { ok: false, code: "no-token", message: "Add your terms AI token first — click the toolbar icon." };
  }

  let res;
  try {
    res = await fetch(`${APP_ORIGIN}/api/v1/scans`, {
      method: "POST",
      headers: { Authorization: `Bearer ${termsAiToken}`, Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({ scan: { site_name: title, url, content } }),
    });
  } catch {
    return { ok: false, code: "network", message: "Can't reach the terms AI server. Is it running?" };
  }

  if (res.status === 401) {
    await chrome.storage.local.remove("termsAiToken");
    return { ok: false, code: "unauth", message: "Your token isn't valid anymore — add a new one via the toolbar icon." };
  }
  if (res.status === 402) {
    return { ok: false, code: "no-tokens", message: "You're out of scan tokens — click the toolbar icon to top up." };
  }
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    return { ok: false, code: "error", message: body.error || "The analysis failed — please try again." };
  }

  const scan = await res.json();
  setBadge(tabId, riskToneForScore(scan.risk_score), scan.risk_score);
  return { ok: true, scan };
}

function riskToneForScore(score) {
  if (score >= 8) return "safe";
  if (score >= 5) return "caution";
  return "risk";
}
