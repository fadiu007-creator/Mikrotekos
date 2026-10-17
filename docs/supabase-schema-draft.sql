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
  project_type text not null check (project_type in ('content', 'budget', 'cv', 'website')),
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
  status text not null default 'new' check (status in ('new', 'in_review', 'in_progress', 'completed', 'cancelled')),
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
