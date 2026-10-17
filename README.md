# MikroTekos

Bilingual (Albanian / English) digital-services website and browser workspace for Kosovo and the Balkans. The frontend is static HTML/CSS/JavaScript and is intended for GitHub Pages or Cloudflare Pages (no Vercel dependency).

## Deploy the website

### Cloudflare Pages
1. Import this GitHub repository into Cloudflare Pages.
2. Framework preset: **None**.
3. Build command: leave empty.
4. Build output directory: **/** (repository root).
5. Deploy.

### GitHub Pages
Enable Pages for the main branch and repository root. The site uses relative links, so it can run under the repository subpath.

## Supabase connection

The frontend uses the public publishable key in backend-config.js. This key is intended for browser use; it is **not** a service-role key. Never put a service-role key or an AI-provider secret in frontend files.

The existing Supabase project zikos is shared with other apps. MikroTekos uses isolated mikrotekos_* tables and RLS policies; the migration does not change existing zikos_*, dhuroje_*, kafja, or other application tables.

### Backend now connected
- Supabase Auth account creation, email confirmation, sign-in, sign-out and password reset (account.html).
- User-owned cloud workspace snapshot (mikrotekos_workspaces) and user-owned project rows (mikrotekos_projects).
- Service request form writes to mikrotekos_service_requests; admin inbox is at admin.html.
- FAQ/automation configuration can be saved to mikrotekos_automation_configs.
- Website draft records and a controlled, text-only public website route (sites.html, view-site.html). Published pages render structured text fields, not arbitrary stored HTML, reducing script-injection risk.
- Active service packages stored in mikrotekos_service_packages.
- Authenticated Supabase Edge Function mikrotekos-ai is deployed for content/FAQ/SEO/automation prompts and uses Cloudflare Workers AI (open-weight Meta Llama 3.1 8B) instead of OpenAI.

### Required launch setup
1. **Configure free-tier AI:** create a Cloudflare API token with Workers AI Read and Workers AI Edit permissions, and copy your Cloudflare Account ID. In Supabase Dashboard → Edge Functions → Secrets, set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_AI_TOKEN. Optional: set CLOUDFLARE_AI_MODEL; the default is @cf/meta/llama-3.1-8b-instruct-fp8-fast. Never put the token in GitHub or backend-config.js. Cloudflare Workers AI currently includes 10,000 Neurons/day on its Free plan; quota/model limits apply and requests may fail when the allocation is exhausted. Do not enable paid usage unless you choose to.
2. **Assign the admin role securely:** create your account in account.html, then use the SQL Editor with the exact account email (see docs/admin-setup.md). This writes app_metadata, not user-editable metadata. Do not grant admin to an email you do not control.
3. **Auth URL and email delivery:** in Supabase Authentication → URL Configuration, set the Site URL to the real deployed site origin and allowlist the account page URL (for example, the GitHub Pages or Cloudflare Pages origin plus /account.html). Configure working email/SMTP settings for production confirmation and password reset; default test email limits may apply.
4. **Abuse prevention:** the service-request table accepts only bounded insert payloads from anonymous visitors and exposes no anonymous read access. Before advertising the form widely, add CAPTCHA/rate limiting and operational monitoring.
5. **Hosting:** the website editor's hosted-page workflow serves safe structured pages at view-site.html?slug=... on the same static domain. It does not create custom domains or deploy independent files to a separate Cloudflare site.

## Current tools and features
- Responsive bilingual landing page and service packages.
- Content studio, text cleaner, budget planner, CV/cover-letter editor, website editor and JSON backup.
- Cloud workspace sync for signed-in users; local storage remains available for offline/guest use.
- Business FAQ assistant with cloud configuration; uses the AI Edge Function when signed in and configured, with a local keyword fallback.
- Basic local SEO checklist/suggestion generator. It does not query Google rankings or edit Google Business Profile.
- Website draft/publish workflow with a public text-only page.
- Customer service request submission and admin status workflow.

## Pricing note
Starter Website (€149–€299), Social Media Content (€99–€249/month), and Business Automation Starter (€199–€499 setup) are proposed starting prices, not verified market averages or binding quotes.

## Security notes
- Never expose Supabase service-role keys or Cloudflare AI tokens in client files.
- Admin checks use server-managed app_metadata.role, never user_metadata.
- All MikroTekos tables have RLS enabled; request visibility and updates are restricted.
- Review privacy, consumer, tax, and business requirements for the countries served before public launch.
