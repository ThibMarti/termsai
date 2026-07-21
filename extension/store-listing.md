# Chrome Web Store listing — draft

Prep only — nobody has a Developer Dashboard account yet, and this
shouldn't be submitted until Phase 1–4 are actually live (no point
publishing a store listing for a button that shows an alert). Fill in the
screenshots/promo images once the real popup states (Phase 3) exist.

## Name

terms AI — Terms & Privacy Scanner

## Summary (132 char max)

Scan the Terms & Conditions or Privacy Policy of any page for risky
clauses, right where you're reading it.

## Description

terms AI reads the Terms & Conditions or Privacy Policy you're looking at
and flags what actually matters: data sharing, AI training use, tracking,
and cancellation traps — with the exact clause highlighted on the page and
a trust score out of 10.

Click the icon on any page, hit "Analyze this page", and get a score plus
a short list of what's worth reading before you accept. Open the full
report any time from terms AI's Scan History.

Free to start — every account gets 1 free scan on signup.

## Single purpose (required by Chrome Web Store review)

This extension analyzes the Terms of Service / Privacy Policy text of the
page the user is currently viewing, at the user's request, and displays
the results in the extension popup and on the page itself.

## Permissions justification

- `activeTab` — read the current page's text only when the user clicks
  "Analyze this page"; never runs in the background on pages the user
  hasn't asked about.
- `scripting` — inject the clause highlights into the page after analysis.
- `storage` — store the user's terms AI API token locally so they don't
  have to paste it in every time.
- Host permission (API origin) — send the extracted text to terms AI's
  backend for analysis. **Not** sent anywhere else; never sent directly to
  a third-party AI provider from the browser.

## Privacy practices disclosure

- **What's collected**: the visible text of the page the user explicitly
  chooses to analyze, plus their terms AI account token (for
  authentication — stored locally, not part of this disclosure's "data
  collected" bucket).
- **Why**: sent to terms AI's own backend, which runs the analysis and
  returns a score + flagged clauses. Not sold, not shared with third
  parties beyond the AI provider that performs the analysis on our behalf.
- **Popup copy**: "Sent securely to terms AI for analysis" (agreed during
  planning — replaces an earlier mockup's inaccurate "runs locally, no
  data sent" line, which doesn't describe this architecture).

## Category

Productivity

## Screenshots (TODO once Phase 3 ships)

- [ ] Idle state on a real T&C page
- [ ] Done state — score + flagged clauses in the popup
- [ ] In-page highlighting with a clause tooltip/annotation
- [ ] Full report page (opened from "View full report")
