# terms AI — Chrome extension

Manifest V3 extension. Plain HTML/CSS/JS, no build step — same philosophy
as the Rails app (Hotwire, importmap).

Status: **All phases (1–5) done.** Phase 1 added a bearer-token backend
(`Api::V1::ScansController`/`Api::V1::MeController`, authenticated with a
per-user `extension_token` — see `User#extension_token` and the "Chrome
extension" section on `/profile`). Phase 3 wires the popup through its
full state machine — token entry, idle, scanning, empty-page, out-of-tokens,
result (with in-page highlighting + toolbar badge via Phases 4/5), and
error — against that real API.

## Load it locally

1. Start the Rails app (`bin/rails server`) and sign in at
   `http://localhost:3000` in a normal tab.
2. Get your extension token from the "Chrome extension" section on your
   `/profile` page.
3. Open `chrome://extensions`.
4. Toggle **Developer mode** on (top right).
5. Click **Load unpacked**, select this `extension/` folder.
6. Pin the terms AI icon from the extensions toolbar menu, open it, and
   paste your token when prompted.

Any time you change a file, click the refresh icon on the extension's card
in `chrome://extensions` to reload it (content scripts also need the page
itself reloaded).

## Talking to the backend

`popup/popup.js` stores the pasted token in `chrome.storage.local` and
sends it as `Authorization: Bearer <token>` on every request:

- `GET /api/v1/me` → `{ can_scan }` — checked on popup open, and again
  after saving a new token.
- `POST /api/v1/scans` with `{ scan: { site_name, url, content } }` →
  `{ id, site_name, url, risk_score, full_report }` on success (200 if an
  existing scan for that URL was reused, 201 if new), `401` if the token
  is missing/invalid (the popup clears it and re-prompts), `402` if the
  user is out of tokens, `502` if the AI analysis itself failed.

`APP_ORIGIN` at the top of `popup.js` is the one line to change between
local dev (`http://localhost:3000`) and production (`https://termsai.eu`).

## Structure

```
extension/
  manifest.json           Manifest V3 config
  background.js            Service worker — badge state (chrome.action) for now
  content/content.js       Text extraction + clause highlighting (chrome.runtime.onMessage)
  content/highlight.css    Tone-colored <mark> styles for highlighted clauses
  popup/                    Toolbar popup UI (idle state only for now)
  icons/                    16/32/48/128px, generated from public/icon.png
  dev/                      Fixture page + instructions for testing content.js/background.js in isolation
  store-listing.md          Draft Chrome Web Store copy — not submitted anywhere yet
```

## Messages the content script understands

Sent via `chrome.tabs.sendMessage(tabId, message)` from the popup/background:

- `{ type: "terms-ai:extract-text" }` → `{ text, empty, truncated }`
  (`empty` if the page had under ~40 chars of visible text; `truncated` if
  it was capped at 20,000 chars)
- `{ type: "terms-ai:highlight-clauses", clauses: [{ quote, tone }] }` → `{ highlighted: true }`
- `{ type: "terms-ai:clear-highlights" }` → `{ cleared: true }`
- `{ type: "terms-ai:scroll-to-clause", index }` → `{ scrolled: true }`

## Messages the background service worker understands

Sent via `chrome.runtime.sendMessage(message)` — include the target
`tabId` explicitly (the popup already has it from `chrome.tabs.query`;
`sender.tab` isn't set for messages sent from the popup):

- `{ type: "terms-ai:set-badge", tabId, tone, score }` → `{ set: true }`
  (colors the toolbar icon's badge; `tone` is `risk` / `caution` / `safe`)
- `{ type: "terms-ai:clear-badge", tabId }` → `{ cleared: true }`

The badge also auto-clears when the tab navigates to a new page.

`tone` is one of `risk` / `caution` / `safe` (same vocabulary as the rest of
the app). See `dev/README.md` to try all of the above against the bundled
fixture.

## Design reference

Popup layout/states mirror the `ExtensionPanel` component and the
"Extension Flow" prototype in the **terms AI Design System** Claude Design
project — check there before changing the popup UI.
