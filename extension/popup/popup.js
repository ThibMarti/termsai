// Phase 2 scaffold — idle state only. Wiring this up to POST /api/v1/scans
// (Phase 1, in progress by a teammate) and the loading/done/error states
// (Phase 3) is tracked in the Chrome extension task plan.

const APP_ORIGIN = "http://localhost:3000"; // TODO(team): swap for https://termsai.eu once the API auth flow (Phase 1) ships

document.addEventListener("DOMContentLoaded", async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const siteEl = document.getElementById("site");
  if (tab?.url) {
    try {
      siteEl.textContent = new URL(tab.url).hostname;
    } catch {
      siteEl.textContent = "this page";
    }
  }

  document.getElementById("report-link").href = `${APP_ORIGIN}/scan_history`;

  document.getElementById("analyze-btn").addEventListener("click", () => {
    alert("Analyzing isn't wired up yet — see the Chrome extension task plan (Phase 1: backend API + auth).");
  });
});
