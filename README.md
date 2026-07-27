# TermsAI

AI-powered browser extension that scans Terms & Conditions and privacy policies while you browse, and turns them into a plain-language summary — so you know what you're actually agreeing to before you click "accept."

Built during Le Wagon's AI Software Development Bootcamp (2026), in a team of 4, over 2 weeks.

**Live**: [termsai.eu](https://termsai.eu)

## How it works

A Chrome extension detects T&Cs and privacy policy pages and sends the text to the backend, where GPT-4o (via the `ruby_llm` gem) summarizes it and flags what matters. Users authenticate through a personal extension token generated from their profile, and can review scan history from a dashboard. Premium usage is unlocked through Stripe-billed subscription plans.

## Stack

Ruby on Rails 8 · PostgreSQL · GPT-4o (ruby_llm) · Stripe · Devise · Hotwire (Turbo/Stimulus) · Chrome extension · Deployed on Heroku

## Status

Le Wagon AI Software Development Bootcamp capstone project — team of 4, built in 2 weeks.
