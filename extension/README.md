# terms AI — Chrome extension

Manifest V3 extension. Plain HTML/CSS/JS, no build step — same philosophy
as the Rails app (Hotwire, importmap).

Status: **Phase 2 scaffold only.** The popup shows the idle state (site
name + "Analyze this page" button) but isn't wired up to the backend yet.
Phase 1 (backend API + auth token) is being built separately — once it
ships, Phase 3/4 wire up the real analyze flow + in-page highlighting. See
the Chrome extension task plan for the full breakdown.

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
  manifest.json       Manifest V3 config
  background.js        Service worker (message routing — not wired up yet)
  content/content.js   Injected into every page (text extraction + highlighting — not wired up yet)
  popup/                Toolbar popup UI (idle state only for now)
  icons/                16/32/48/128px, generated from public/icon.png
```

## Design reference

Popup layout/states mirror the `ExtensionPanel` component and the
"Extension Flow" prototype in the **terms AI Design System** Claude Design
project — check there before changing the popup UI.
