# MikroTekos

Bilingual (Albanian / English) static website for AI, automation, web and other tech microservices aimed at Kosovo and the Balkans.

## Deploy on Cloudflare Pages

1. Import this GitHub repository into Cloudflare Pages.
2. Framework preset: **None**.
3. Build command: leave empty.
4. Build output directory: `/` (repository root).
5. Deploy.

This project is plain HTML, CSS and JavaScript; no build step or package installation is required.

## Included

- Responsive landing page and service catalog
- Search and category filters
- Indicative euro starting prices
- Service request form that opens the visitor's email application
- Albanian / English language toggle
- Browser-only AI prompt builder and text cleaner
- Privacy notice

## Before launch

- Replace `hello@mikrotekos.com` in `index.html` and `privacy.html` with a real monitored business email.
- Prices are illustrative starting prices, not binding quotes.
- No online payments are enabled. Add a supported payment provider and server-side order verification before taking payments.
- The prompt builder creates a prompt locally; it does not call an AI model. Connect a model through a secure backend before advertising AI generation.
- Review privacy, consumer, tax, and business requirements for the countries you serve.
