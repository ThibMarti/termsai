# Dev fixture

`fixture.html` is a fake Terms of Service page (same sample clauses as the
design system's Extension Flow data) used to test the content script
(`content/content.js`) without needing the real backend or a live website.

## Test it manually

1. Load the extension unpacked (see the main `extension/README.md`).
2. Serve this folder over HTTP (content scripts don't reliably run on
   `file://` URLs without extra permissions):
   ```
   cd extension/dev
   python3 -m http.server 8842
   ```
3. Open http://localhost:8842/fixture.html in the same Chrome profile the
   extension is loaded in.
4. Open the service worker console from `chrome://extensions` (the
   extension's card → "service worker" link) and run:
   ```js
   const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
   await chrome.tabs.sendMessage(tab.id, {
     type: "terms-ai:highlight-clauses",
     clauses: [
       { quote: "You hereby waive your right to participate in a class action", tone: "risk" },
       { quote: "change these terms at any time, without notice", tone: "caution" },
       { quote: "worldwide, irrevocable and transferable license", tone: "risk" },
     ],
   });
   ```
   You should see 3 highlighted clauses on the fixture page, colored by
   tone. `{ type: "terms-ai:clear-highlights" }` removes them again.

This is the same message shape Phase 3's popup will send once it has a real
`full_report` from the API — the popup just calls
`chrome.tabs.sendMessage(tabId, ...)` the same way.

## Testing the badge (background.js)

Same service worker console, same tab:

```js
const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
await chrome.runtime.sendMessage({ type: "terms-ai:set-badge", tabId: tab.id, tone: "risk", score: 3 });
```

The toolbar icon should show a red "3" badge. Reload the page (or navigate
anywhere) and it clears itself automatically.
