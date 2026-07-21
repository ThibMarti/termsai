// Phase 3 — wires the popup shell (Phase 2), the content script's
// extract/highlight messages (Phase 4), and the background badge (Phase 5)
// to the real backend from Api::V1 (Phase 1). See ../README.md for the
// message contract this relies on.

const APP_ORIGIN = "http://localhost:3000"; // TODO(team): swap for https://termsai.eu once we deploy this branch

const LEVEL_TONES = { low: "safe", medium: "caution", high: "risk" };

document.addEventListener("DOMContentLoaded", () => {
  const states = {
    loading: document.getElementById("loading-state"),
    needToken: document.getElementById("need-token-state"),
    idle: document.getElementById("idle-state"),
    scanning: document.getElementById("scanning-state"),
    empty: document.getElementById("empty-state"),
    noTokens: document.getElementById("no-tokens-state"),
    result: document.getElementById("result-state"),
    error: document.getElementById("error-state")
  };

  function show(name) {
    Object.entries(states).forEach(([key, el]) => { el.hidden = key !== name; });
  }

  function riskToneForScore(score) {
    if (score >= 8) return "safe";
    if (score >= 5) return "caution";
    return "risk";
  }

  async function getStoredToken() {
    const { termsAiToken } = await chrome.storage.local.get("termsAiToken");
    return termsAiToken || null;
  }

  function setStoredToken(token) {
    return chrome.storage.local.set({ termsAiToken: token });
  }

  function clearStoredToken() {
    return chrome.storage.local.remove("termsAiToken");
  }

  function authedFetch(token, path, options = {}) {
    return fetch(`${APP_ORIGIN}${path}`, {
      ...options,
      headers: { Authorization: `Bearer ${token}`, Accept: "application/json", ...(options.headers || {}) }
    });
  }

  async function getActiveTab() {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    return tab;
  }

  function renderError(message) {
    document.getElementById("error-message").textContent = message;
    show("error");
  }

  function showNeedToken(errorMessage) {
    const errorEl = document.getElementById("token-error");
    errorEl.hidden = !errorMessage;
    if (errorMessage) errorEl.textContent = errorMessage;
    show("needToken");
  }

  function renderResult(scan, tab) {
    const tone = riskToneForScore(scan.risk_score);

    const badge = document.getElementById("result-badge");
    badge.textContent = `Score: ${scan.risk_score}/10`;
    badge.className = `panel__badge panel__badge--${tone}`;

    document.getElementById("result-summary").textContent = scan.full_report.summary;

    const list = document.getElementById("result-categories");
    list.innerHTML = "";
    (scan.full_report.categories || []).forEach((category) => {
      const li = document.createElement("li");
      li.textContent = `${category.name.replace(/_/g, " ")} — ${category.level}`;
      list.appendChild(li);
    });

    document.getElementById("result-link").href = `${APP_ORIGIN}/scans/${scan.id}`;
    show("result");

    const clauses = (scan.full_report.categories || [])
      .flatMap((category) => category.items || [])
      .filter((item) => item.quote)
      .map((item) => ({ quote: item.quote, tone: LEVEL_TONES[item.level] || "caution" }));

    if (tab?.id) {
      chrome.tabs.sendMessage(tab.id, { type: "terms-ai:highlight-clauses", clauses }).catch(() => {});
      chrome.runtime.sendMessage({ type: "terms-ai:set-badge", tabId: tab.id, tone, score: scan.risk_score }).catch(() => {});
    }
  }

  async function showIdleForTab(tab) {
    const siteEl = document.getElementById("site");
    try {
      siteEl.textContent = tab?.url ? new URL(tab.url).hostname : "this page";
    } catch {
      siteEl.textContent = "this page";
    }
    show("idle");
  }

  async function analyze() {
    const token = await getStoredToken();
    const tab = await getActiveTab();

    show("scanning");

    let extracted;
    try {
      extracted = await chrome.tabs.sendMessage(tab.id, { type: "terms-ai:extract-text" });
    } catch {
      return renderError("Can't read this page — try a different tab, or reload this one first.");
    }

    if (extracted.empty) return show("empty");

    let res;
    try {
      res = await authedFetch(token, "/api/v1/scans", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ scan: { site_name: tab.title, url: tab.url, content: extracted.text } })
      });
    } catch {
      return renderError("Can't reach the terms AI server. Is it running?");
    }

    if (res.status === 401) {
      await clearStoredToken();
      return showNeedToken("Your token isn't valid anymore — paste a current one.");
    }
    if (res.status === 402) return show("noTokens");
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      return renderError(body.error || "The analysis failed — please try again.");
    }

    renderResult(await res.json(), tab);
  }

  async function init() {
    show("loading");

    const tab = await getActiveTab();
    document.getElementById("report-link").href = `${APP_ORIGIN}/scan_history`;
    document.getElementById("profile-link").href = `${APP_ORIGIN}/profile`;
    document.getElementById("buy-tokens-link").href = `${APP_ORIGIN}/offers`;

    const token = await getStoredToken();
    if (!token) return showNeedToken();

    let res;
    try {
      res = await authedFetch(token, "/api/v1/me");
    } catch {
      return renderError("Can't reach the terms AI server. Is it running?");
    }

    if (res.status === 401) {
      await clearStoredToken();
      return showNeedToken("Your token isn't valid anymore — paste a current one.");
    }
    if (!res.ok) return renderError("Something went wrong checking your account — try again.");

    const { can_scan } = await res.json();
    if (!can_scan) return show("noTokens");

    await showIdleForTab(tab);
  }

  document.getElementById("save-token-btn").addEventListener("click", async () => {
    const value = document.getElementById("token-input").value.trim();
    if (!value) return showNeedToken("Paste your token first.");

    await setStoredToken(value);
    init();
  });

  document.getElementById("analyze-btn").addEventListener("click", analyze);
  document.getElementById("change-token-link").addEventListener("click", (e) => {
    e.preventDefault();
    showNeedToken();
  });
  document.getElementById("empty-back-btn").addEventListener("click", init);
  document.getElementById("retry-btn").addEventListener("click", init);

  init();
});
