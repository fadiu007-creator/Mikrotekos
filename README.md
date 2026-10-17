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
- On-page custom-service request form (currently opens the user's email app; no server-side inbox yet).
- Bilingual business tools page (`business-tools.html`): local FAQ-assistant prototype and basic local-SEO checklist/suggestion generator.
- Three customer-facing test packages: Starter Website (€149–€299), Social Media Content (€99–€249/month), and Business Automation Starter (€199–€499 setup). These are proposed test prices, not verified market averages.

## Important current limitations

- **Browser-local storage only:** projects, budget transactions, CV details and service requests remain in the current browser on this device. They are not uploaded to a server and will not sync across devices.
- **No real account/authentication yet:** do not use local browser storage as a secure account system.
- **Service requests are not delivered to MikroTekos:** the request tracker stores them locally; there is no server inbox or admin dashboard yet.
- **No real website publishing/hosting yet:** the builder previews a site and can export HTML, but does not deploy it to a public URL.
- **No live AI model connection:** content drafts use local templates; the FAQ assistant uses keyword matching, not an AI model. A secure backend and model/API configuration are needed for real AI generation.
- **Business tools are prototypes:** FAQ configurations and SEO checks stay in the current browser. The SEO tool does not inspect a live website, Google rankings, or Google Business Profile.
- No checkout or payment flow. Prices shown for custom services are illustrative starting prices, not binding quotes.
- Review privacy, consumer, tax, and business requirements for the countries served before launch.

## Backend preparation (not deployed)

- `docs/supabase-schema-draft.sql` is a **review draft only** for profiles, cloud projects, business profiles, automation configurations, customer service requests, configurable service packages, published websites, and deployment metadata, including row-level security policies.
- The SQL has **not** been run against a database. Before applying it, create or explicitly select a dedicated MikroTekos Supabase project; do not reuse the shared `zikos` project used by other apps.
- Real service-request delivery needs a server/Edge Function with validation and rate limiting. Anonymous visitors must not receive direct database insert access. Admin permissions must be assigned server-side through trusted app metadata.
- Website publishing still needs a controlled Cloudflare publishing service/hosting integration. Saving HTML in a database alone does not publish a secure website. Deployment metadata is not a deployment implementation.
- The pricing cards and service request form are frontend-only at this stage; prices are edited in `index.html`, and requests are not yet saved to a server or shown in an admin inbox.
