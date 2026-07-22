// In-page banner: proactively offers a scan when detector.js decides this
// page looks like a T&C/Privacy Policy page. Rendered into a Shadow DOM host
// — deliberately different from content.js's `mark.terms-ai-highlight`
// elements, which stay in the light DOM so they inherit the surrounding
// text's inline flow/typography. The banner is a self-contained floating
// widget, so style isolation (no bleed either direction) is what's wanted
// here instead.
//
// The actual API call happens in background.js, not here: a fetch() from a
// content script is subject to the *visited page's* CSP connect-src and can
// be silently blocked on strict-CSP sites, while background.js (an
// extension context) isn't. extractText()/highlightClauses() are called
// directly, though — they're plain functions in content.js, loaded before
// this file, sharing the same isolated-world global scope.

const APP_ORIGIN = "http://localhost:3000"; // TODO(team): keep in sync with popup/popup.js's APP_ORIGIN

const BANNER_HOST_ID = "terms-ai-banner-host";
const LEVEL_TONES = { low: "safe", medium: "caution", high: "risk" };

const BANNER_STYLES = `
  :host { all: initial; }
  .banner {
    position: fixed;
    right: 20px;
    bottom: 20px;
    z-index: 2147483647;
    width: 280px;
    padding: 16px;
    border-radius: 10px;
    background: #FFFFFF;
    color: #101720;
    box-shadow: 0 4px 20px rgba(16, 23, 32, 0.2);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    font-size: 13px;
    line-height: 1.4;
  }
  .banner__close {
    position: absolute;
    top: 8px;
    right: 10px;
    background: none;
    border: none;
    color: #6B7684;
    font-size: 16px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
  }
  .banner__lead { margin: 0 24px 12px 0; }
  .banner__btn {
    display: inline-block;
    background: #2563EB;
    color: #FFFFFF;
    border: none;
    border-radius: 6px;
    padding: 8px 14px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    text-decoration: none;
  }
  .banner__btn:hover { background: #1D4ED8; }
  .banner__badge {
    display: inline-block;
    border-radius: 6px;
    padding: 2px 8px;
    font-weight: 600;
    margin-bottom: 8px;
  }
  .banner__badge--safe { background: #F0F8F2; color: #1A6E3C; }
  .banner__badge--caution { background: #FAEBD3; color: #A35A08; }
  .banner__badge--risk { background: #FBE3E0; color: #B4231F; }
  .banner__error { color: #B4231F; }
  .banner__link { display: block; margin-top: 8px; }
`;

if (looksLikeTermsPage() && !document.getElementById(BANNER_HOST_ID)) {
  mountBanner();
}

function mountBanner() {
  const host = document.createElement("div");
  host.id = BANNER_HOST_ID;
  document.body.appendChild(host);

  const shadow = host.attachShadow({ mode: "open" });
  shadow.innerHTML = `
    <style>${BANNER_STYLES}</style>
    <div class="banner">
      <button class="banner__close" data-action="close" aria-label="Dismiss">×</button>
      <div class="banner__body"></div>
    </div>
  `;

  shadow.querySelector(".banner__close").addEventListener("click", () => host.remove());
  shadow.querySelector(".banner__body").addEventListener("click", (event) => {
    const action = event.target.dataset.action;
    if (action === "scan") handleScanClick(shadow);
    if (action === "back") showIdleState(shadow);
    if (action === "retry") showIdleState(shadow);
  });

  showIdleState(shadow);
}

function escapeHtml(value) {
  const div = document.createElement("div");
  div.textContent = value ?? "";
  return div.innerHTML;
}

function bannerBody(shadow) {
  return shadow.querySelector(".banner__body");
}

function showIdleState(shadow) {
  bannerBody(shadow).innerHTML = `
    <p class="banner__lead">Since you are on a T&C page, let us do the job.</p>
    <button class="banner__btn" data-action="scan">Scan this page</button>
  `;
}

function showScanningState(shadow) {
  bannerBody(shadow).innerHTML = `
    <p class="banner__lead">Reading this page and analyzing it… this can take up to 30 seconds.</p>
  `;
}

function showEmptyState(shadow) {
  bannerBody(shadow).innerHTML = `
    <p class="banner__lead">Nothing to scan here — this page doesn't look like it has real Terms &amp; Conditions or Privacy Policy text.</p>
    <button class="banner__btn" data-action="back">Back</button>
  `;
}

function showErrorState(shadow, message) {
  bannerBody(shadow).innerHTML = `
    <p class="banner__lead banner__error">${escapeHtml(message || "The analysis failed — please try again.")}</p>
    <button class="banner__btn" data-action="retry">Try again</button>
  `;
}

function riskToneForScore(score) {
  if (score >= 8) return "safe";
  if (score >= 5) return "caution";
  return "risk";
}

function showResultState(shadow, scan) {
  const tone = riskToneForScore(scan.risk_score);
  bannerBody(shadow).innerHTML = `
    <span class="banner__badge banner__badge--${tone}">Score: ${scan.risk_score}/10</span>
    <p class="banner__lead">${escapeHtml(scan.full_report.summary)}</p>
    <a class="banner__btn banner__link" href="${APP_ORIGIN}/scans/${scan.id}" target="_blank" rel="noopener">View full report</a>
  `;
}

async function handleScanClick(shadow) {
  showScanningState(shadow);

  const extracted = extractText(); // content.js, same global scope
  if (extracted.empty) return showEmptyState(shadow);

  const response = await chrome.runtime
    .sendMessage({
      type: "terms-ai:run-scan",
      url: location.href,
      title: document.title,
      content: extracted.text,
    })
    .catch((err) => {
      console.log("terms-ai DEBUG sendMessage threw:", err && err.message);
      return null;
    });
  console.log("terms-ai DEBUG response:", JSON.stringify(response));

  if (!response?.ok) return showErrorState(shadow, response?.message);

  showResultState(shadow, response.scan);

  const clauses = (response.scan.full_report.categories || [])
    .flatMap((category) => category.items || [])
    .filter((item) => item.quote)
    .map((item) => ({ quote: item.quote, tone: LEVEL_TONES[item.level] || "caution" }));
  highlightClauses(clauses); // content.js, same global scope
}
