# terms AI — Chrome extension

Manifest V3 extension. Plain HTML/CSS/JS, no build step — same philosophy
as the Rails app (Hotwire, importmap).

Status: **Phase 2 (popup shell), Phase 4 (content script), and Phase 5
(badge + hardening + store listing prep) done.** The popup shows the idle
state (site name + "Analyze this page" button); the content script can
extract page text (with empty-page and oversized-page handling) and
highlight clauses on message, and the toolbar icon can show a risk-tone
badge — all tested against a bundled dev fixture (see `dev/README.md`)
since there's no real API to call yet. Phase 1 (backend API + auth token)
is being built separately — once it ships, Phase 3 wires the popup's
loading/done states to a real `POST /api/v1/scans` call and to the content
script's messages. See the Chrome extension task plan for the full
breakdown.

## Load it locally

1. Open `chrome://extensions`.
2. Toggle **Developer mode** on (top right).
3. Click **Load unpacked**, select this `extension/` folder.
4. Pin the terms AI icon from the extensions toolbar menu to see the popup.

Any time you change a file, click the refresh icon on the extension's card
in `chrome://extensions` to reload it (content scripts also need the page
itself reloaded).

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
