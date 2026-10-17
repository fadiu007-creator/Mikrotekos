-- MikroTekos backend schema DRAFT.
-- Review and apply only to a dedicated MikroTekos Supabase project.
-- This file has NOT been applied to any database.
-- Admin authorization must be assigned server-side in app_metadata.role; never trust user_metadata.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_type text not null check (project_type in ('content', 'social_content', 'budget', 'cv', 'website', 'automation', 'seo')),
  title text not null default 'Untitled project' check (char_length(title) <= 200),
  content jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists projects_user_updated_idx
  on public.projects (user_id, updated_at desc);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null check (char_length(customer_name) between 1 and 200),
  customer_email text not null check (char_length(customer_email) <= 320),
  service_type text not null check (char_length(service_type) between 1 and 120),
  details text not null check (char_length(details) between 1 and 10000),
  status text not null default 'received' check (status in ('received', 'reviewing', 'quoted', 'accepted', 'in_progress', 'completed', 'declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists service_requests_user_created_idx
  on public.service_requests (user_id, created_at desc);
create index if not exists service_requests_status_created_idx
  on public.service_requests (status, created_at desc);

create table if not exists public.published_sites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
  title text not null default 'Untitled website' check (char_length(title) <= 200),
  html text not null default '',
  status text not null default 'draft' check (status in ('draft', 'published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);
create index if not exists published_sites_user_updated_idx
  on public.published_sites (user_id, updated_at desc);


-- Reusable business profiles for content, FAQ and SEO workflows.
create table if not exists public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 200),
  category text not null default 'general' check (char_length(category) <= 100),
  city text not null default '' check (char_length(city) <= 120),
  language text not null default 'sq' check (language in ('sq', 'en')),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists business_profiles_user_updated_idx
  on public.business_profiles (user_id, updated_at desc);

-- Owner-controlled automation configuration. "active" is a desired state only;
-- an integration must still be configured and verified by a trusted server.
create table if not exists public.automation_configs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_profile_id uuid references public.business_profiles(id) on delete set null,
  name text not null default 'FAQ assistant' check (char_length(name) <= 200),
  config jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft', 'disabled', 'active')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists automation_configs_user_updated_idx
  on public.automation_configs (user_id, updated_at desc);

-- Configurable customer-facing packages. Prices are editable by trusted admins.
create table if not exists public.service_packages (
  id text primary key check (id ~ '^[a-z0-9]+(-[a-z0-9]+)*
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at before update on public.projects
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists service_requests_set_updated_at on public.service_requests;
create trigger service_requests_set_updated_at before update on public.service_requests
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists published_sites_set_updated_at on public.published_sites;
create trigger published_sites_set_updated_at before update on public.published_sites
for each row execute function public.mikrotekos_set_updated_at();


drop trigger if exists business_profiles_set_updated_at on public.business_profiles;
create trigger business_profiles_set_updated_at before update on public.business_profiles
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists automation_configs_set_updated_at on public.automation_configs;
create trigger automation_configs_set_updated_at before update on public.automation_configs
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists service_packages_set_updated_at on public.service_packages;
create trigger service_packages_set_updated_at before update on public.service_packages
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists website_deployments_set_updated_at on public.website_deployments;
create trigger website_deployments_set_updated_at before update on public.website_deployments
for each row execute function public.mikrotekos_set_updated_at();

alter table public.profiles enable row level security;
alter table public.website_deployments enable row level security;
alter table public.service_packages enable row level security;
alter table public.automation_configs enable row level security;
alter table public.business_profiles enable row level security;
alter table public.projects enable row level security;
alter table public.service_requests enable row level security;
alter table public.published_sites enable row level security;


create policy "Users can manage their own business profiles"
  on public.business_profiles for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can manage their own automation configs"
  on public.automation_configs for all to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      business_profile_id is null
      or exists (
        select 1 from public.business_profiles b
        where b.id = business_profile_id and b.user_id = (select auth.uid())
      )
    )
  );
create policy "Anyone can read active service packages"
  on public.service_packages for select to anon, authenticated
  using (active = true);
create policy "Admins can manage service packages"
  on public.service_packages for all to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Users can read their own deployment records"
  on public.website_deployments for select to authenticated
  using ((select auth.uid()) = user_id or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can manage deployment records"
  on public.website_deployments for all to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can read their own projects"
  on public.projects for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own projects"
  on public.projects for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own projects"
  on public.projects for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own projects"
  on public.projects for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Signed-in customers can submit and view their own requests.
-- Anonymous submissions should go through a rate-limited server/Edge Function,
-- not a public table INSERT policy. Admins are trusted via server-managed app_metadata.
create policy "Customers can submit their own service requests"
  on public.service_requests for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Customers and admins can read service requests"
  on public.service_requests for select to authenticated
  using (
    (select auth.uid()) = user_id
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );
create policy "Admins can update service requests"
  on public.service_requests for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can delete service requests"
  on public.service_requests for delete to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Published pages are publicly readable; drafts remain owner-only.
-- Only a trusted publishing backend or server-assigned admin may mark a site public.
create or replace function public.mikrotekos_guard_site_publish()
returns trigger
language plpgsql
set search_path = ''
as $
begin
  if new.status = 'published'
     and (tg_op = 'INSERT' or old.status is distinct from 'published')
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') <> 'admin' then
    raise exception 'Publishing must be performed by the trusted publishing service';
  end if;
  return new;
end;
$;
drop trigger if exists published_sites_guard_publish on public.published_sites;
create trigger published_sites_guard_publish before insert or update on public.published_sites
for each row execute function public.mikrotekos_guard_site_publish();

create policy "Published sites are public and drafts are owner-only"
  on public.published_sites for select to anon, authenticated
  using (
    status = 'published'
    or ((select auth.uid()) = user_id)
  );
create policy "Users can create their own websites"
  on public.published_sites for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own websites"
  on public.published_sites for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own websites"
  on public.published_sites for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Do not add a service-role key to any browser HTML/JavaScript.
-- Configure only a publishable/anon key in the frontend after the project is reviewed.
),
  title_sq text not null check (char_length(title_sq) <= 200),
  title_en text not null check (char_length(title_en) <= 200),
  description_sq text not null default '',
  description_en text not null default '',
  min_price_eur numeric(10,2) not null default 0 check (min_price_eur >= 0),
  max_price_eur numeric(10,2) not null default 0 check (max_price_eur >= min_price_eur),
  billing_period text not null default 'one_time' check (billing_period in ('one_time', 'monthly', 'custom')),
  active boolean not null default true,
  display_order integer not null default 0,
  updated_at timestamptz not null default now()
);

-- Deployment metadata only; the publishing service must create and verify the
-- actual public site. Never store provider secrets in this table.
create table if not exists public.website_deployments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  site_id uuid references public.published_sites(id) on delete cascade,
  provider text not null default 'cloudflare_pages',
  status text not null default 'pending' check (status in ('pending', 'deploying', 'published', 'failed', 'disabled')),
  public_url text,
  error_message text check (error_message is null or char_length(error_message) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deployed_at timestamptz
);
create index if not exists website_deployments_user_updated_idx
  on public.website_deployments (user_id, updated_at desc);

create or replace function public.mikrotekos_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at before update on public.projects
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists service_requests_set_updated_at on public.service_requests;
create trigger service_requests_set_updated_at before update on public.service_requests
for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists published_sites_set_updated_at on public.published_sites;
create trigger published_sites_set_updated_at before update on public.published_sites
for each row execute function public.mikrotekos_set_updated_at();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.service_requests enable row level security;
alter table public.published_sites enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can read their own projects"
  on public.projects for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own projects"
  on public.projects for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own projects"
  on public.projects for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own projects"
  on public.projects for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Signed-in customers can submit and view their own requests.
-- Anonymous submissions should go through a rate-limited server/Edge Function,
-- not a public table INSERT policy. Admins are trusted via server-managed app_metadata.
create policy "Customers can submit their own service requests"
  on public.service_requests for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Customers and admins can read service requests"
  on public.service_requests for select to authenticated
  using (
    (select auth.uid()) = user_id
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );
create policy "Admins can update service requests"
  on public.service_requests for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can delete service requests"
  on public.service_requests for delete to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Published pages are publicly readable; drafts remain owner-only.
create policy "Published sites are public and drafts are owner-only"
  on public.published_sites for select to anon, authenticated
  using (
    status = 'published'
    or ((select auth.uid()) = user_id)
  );
create policy "Users can create their own websites"
  on public.published_sites for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own websites"
  on public.published_sites for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own websites"
  on public.published_sites for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Do not add a service-role key to any browser HTML/JavaScript.
-- Configure only a publishable/anon key in the frontend after the project is reviewed.
