# MikroTekos

Bilingual (Albanian / English) static website for AI, automation, web and other tech microservices aimed at Kosovo and the Balkans.

## Deploy on Cloudflare Pages

1. Import this GitHub repository into Cloudflare Pages.
2. Framework preset: **None**.
3. Build command: leave empty.
4. Build output directory: `/` (repository root).
5. Deploy.

This project is plain HTML, CSS and JavaScript; no build step or package installation is required.

## Online workspace MVP

- Responsive landing page and custom service catalog.
- Instant-product cards open the relevant on-site tool instead of downloading starter files.
- Content studio: locally generated social/ad/idea drafts and AI prompts, editable text, copy, and saved drafts.
- Text cleaner.
- Budget planner with income/expense entries, live totals, goal percentage, and transaction deletion.
- CV editor with live preview, cover-letter drafting, copy, and print / Save as PDF.
- Website builder with editable content, color selection, live preview, project saving, and optional HTML export.
- Local project list and JSON backup export.
- On-page custom-service request tracker.

## Important current limitations

- **Browser-local storage only:** projects, budget transactions, CV details and service requests remain in the current browser on this device. They are not uploaded to a server and will not sync across devices.
- **No real account/authentication yet:** do not use local browser storage as a secure account system.
- **Service requests are not delivered to MikroTekos:** the request tracker stores them locally; there is no server inbox or admin dashboard yet.
- **No real website publishing/hosting yet:** the builder previews a site and can export HTML, but does not deploy it to a public URL.
- **No live AI model connection:** content drafts are generated with local templates. A secure backend and model/API configuration are needed for real AI generation.
- No checkout or payment flow. Prices shown for custom services are illustrative starting prices, not binding quotes.
- Review privacy, consumer, tax, and business requirements for the countries served before launch.

## Backend preparation (not deployed)

- `docs/supabase-schema-draft.sql` is a **review draft only** for profiles, cloud projects, customer service requests, and published websites, including row-level security policies.
- The SQL has **not** been run against a database. Before applying it, create or explicitly select a dedicated MikroTekos Supabase project; do not reuse the shared `zikos` project used by other apps.
- Real service-request delivery needs a server/Edge Function with validation and rate limiting. Anonymous visitors must not receive direct database insert access. Admin permissions must be assigned server-side through trusted app metadata.
- Website publishing still needs a controlled publishing service/hosting integration. Saving HTML in a database alone does not publish a secure website.
