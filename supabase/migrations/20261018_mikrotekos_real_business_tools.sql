-- MikroTekos production tools: isolated persistence for campaigns, invoices, analysis reports and CRM leads.
create table if not exists public.mikrotekos_campaigns (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 1 and 200),
 platform text not null check (platform in ('facebook','instagram','tiktok','linkedin')),
 language text not null default 'sq' check (language in ('sq','en','sr')),
 input jsonb not null default '{}'::jsonb,
 output jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check (status in ('draft','ready','archived')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists mikrotekos_campaigns_owner_updated_idx on public.mikrotekos_campaigns(user_id, updated_at desc);
create table if not exists public.mikrotekos_invoices (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 document_type text not null default 'invoice' check (document_type in ('invoice','quote')),
 document_number text not null check (char_length(document_number) between 1 and 80),
 issue_date date not null,
 due_date date,
 currency text not null default 'EUR' check (currency in ('EUR','ALL','USD','CHF','GBP')),
 seller jsonb not null default '{}'::jsonb,
 customer jsonb not null default '{}'::jsonb,
 items jsonb not null default '[]'::jsonb,
 discount numeric(14,2) not null default 0 check (discount >= 0),
 tax_rate numeric(7,4) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
 notes text not null default '' check (char_length(notes) <= 5000),
 status text not null default 'unpaid' check (status in ('unpaid','paid','cancelled')),
 subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
 total numeric(14,2) not null default 0 check (total >= 0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(user_id, document_number)
);
create index if not exists mikrotekos_invoices_owner_date_idx on public.mikrotekos_invoices(user_id, issue_date desc);
create table if not exists public.mikrotekos_analysis_reports (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 filename text not null check (char_length(filename) between 1 and 255),
 source_format text not null check (source_format in ('csv','xlsx','json')),
 row_count integer not null default 0 check (row_count >= 0 and row_count <= 100000),
 column_names jsonb not null default '[]'::jsonb,
 summary jsonb not null default '{}'::jsonb,
 findings jsonb not null default '[]'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists mikrotekos_analysis_owner_created_idx on public.mikrotekos_analysis_reports(user_id, created_at desc);
create table if not exists public.mikrotekos_leads (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 name text not null check (char_length(name) between 1 and 200),
 email text not null default '' check (char_length(email) <= 320),
 phone text not null default '' check (char_length(phone) <= 80),
 company text not null default '' check (char_length(company) <= 200),
 source text not null default '' check (char_length(source) <= 120),
 status text not null default 'new' check (status in ('new','contacted','qualified','proposal','won','lost')),
 follow_up date,
 notes text not null default '' check (char_length(notes) <= 10000),
 archived boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists mikrotekos_leads_owner_status_idx on public.mikrotekos_leads(user_id,status,archived,updated_at desc);
create index if not exists mikrotekos_leads_owner_followup_idx on public.mikrotekos_leads(user_id,follow_up) where archived = false;
alter table public.mikrotekos_campaigns enable row level security;
alter table public.mikrotekos_invoices enable row level security;
alter table public.mikrotekos_analysis_reports enable row level security;
alter table public.mikrotekos_leads enable row level security;
drop policy if exists mikrotekos_campaigns_owner_all on public.mikrotekos_campaigns;
create policy mikrotekos_campaigns_owner_all on public.mikrotekos_campaigns for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_invoices_owner_all on public.mikrotekos_invoices;
create policy mikrotekos_invoices_owner_all on public.mikrotekos_invoices for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_analysis_owner_all on public.mikrotekos_analysis_reports;
create policy mikrotekos_analysis_owner_all on public.mikrotekos_analysis_reports for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_leads_owner_all on public.mikrotekos_leads;
create policy mikrotekos_leads_owner_all on public.mikrotekos_leads for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
