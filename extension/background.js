// Manifest V3 service worker — currently a no-op placeholder.
// Phase 1/4 of the extension task plan will add message routing here
// (content script <-> popup <-> POST /api/v1/scans).

chrome.runtime.onInstalled.addListener(() => {
  console.log("terms AI extension installed");
});
