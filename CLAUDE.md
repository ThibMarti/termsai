# CLAUDE.md

## Project

TermsAI — "a nutrition label for legal text". Users paste a Terms & Conditions
text, an AI analyzes it and returns a risk report (score A–E, GDPR / EU AI Act
flags). Le Wagon bootcamp final project, team of 4, demo day ~July 24, 2026.
Production: https://termsai.eu (Heroku).

## Stack

- Rails 8.1, PostgreSQL, generated from lewagon/rails-templates
- Hotwire (Turbo + Stimulus) with importmap — no React, no build step
- Bootstrap 5.3 + Sass, simple_form, font-awesome
- Devise (authentication), Pundit (authorization — installed early, every
  controller action must be covered by a policy)
- Tests: Minitest (Rails default)

## Commands

- `bin/rails server` — run locally
- `bin/rails db:migrate` / `bin/rails db:seed` — schema & seed data
- `bin/rails console` — interactive console
- `bin/rubocop` — lint (rubocop-rails-omakase)

## Domain model

- `User` — Devise auth. Gets 1 free token at signup (after_create callback).
- `Scan` — one analyzed T&C document: `content` (the pasted text), `url`,
  `site_name`, `risk_score` (integer 1–10, 10 = safe, shown as a colored
  badge — see contract below), `full_report` (jsonb — see contract below).
- `UserScan` — join table: users ↔ scans is many-to-many, so a scan of the
  same site can be reused across users.
- `Token` — free scan allowance. 1 row = 1 token. Balance =
  `user.tokens.count`. Consuming a token = destroying a row. No amount column
  on purpose.
- `Credit` — paid balance (`credits_amount`), one row per user, topped up via
  offers/orders (Stripe Checkout planned).
- `Offer` / `Order` — credit packs and purchases (`checkout_session_id`,
  `state`).

Business rule: creating a scan consumes 1 token first; if the user has no
tokens, it decrements credits; if neither, block the scan and point to the
buy-credits page.

## full_report JSON contract

Every `full_report` — AI output, seeds, and views — follows exactly this
structure. The AI prompt must request it, seeds must fake it, views render it.

```json
{
  "summary": "One-paragraph plain-language summary of the document.",
  "risk_score": 5,
  "categories": [
    { "name": "data_sharing", "level": "high",   "finding": "Data resold to third-party ad partners." },
    { "name": "ai_training",  "level": "medium", "finding": "User content may be used to train AI models." },
    { "name": "tracking",     "level": "low",    "finding": "Standard analytics cookies only." },
    { "name": "cancellation", "level": "high",   "finding": "Auto-renew with a hard-to-cancel process." }
  ],
  "gdpr_flags": ["Cross-border data transfer outside the EU"],
  "ai_act_flags": ["Content used for AI training without explicit consent"]
}
```

Levels: `"low" | "medium" | "high"`. `risk_score`: integer 1–10 — 10 = safe,
1 = very risky. Badges: 8–10 green, 5–7 yellow, 1–4 red. Category names are
fixed: `data_sharing`, `ai_training`, `tracking`, `cancellation` (extend only
by team decision).

## Conventions

- Schema changes ONLY via migrations. Never edit `db/schema.rb` by hand.
- One kanban card = one branch = one small PR. Merge to master daily; master
  stays deployable.
- Views: data first — ugly HTML is fine. Design/CSS comes from Samuel's Figma
  design system later. Use Bootstrap classes and simple_form.
- AI calls live in `app/services/` (e.g. `ScanAnalyzer`); the service writes
  the JSON contract above into `scan.full_report`.
- English UI copy, English code (models, variables, comments).

## Team

Thibault, Samuel, Sarah and Stefano
