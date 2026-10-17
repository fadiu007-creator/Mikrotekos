-- MikroTekos isolated schema for shared Supabase project zikos.
-- Applied to project ref saavqlbwffrwxingbnri on 2026-10-17.
-- All application tables are prefixed mikrotekos_; do not rename to generic names.
create extension if not exists pgcrypto;

create table if not exists public.mikrotekos_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.mikrotekos_workspaces (
 user_id uuid primary key references auth.users(id) on delete cascade,
 data jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.mikrotekos_projects (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 local_id text not null,
 project_type text not null check (project_type in ('content','social_content','budget','cv','website','automation','seo')),
 title text not null default 'Untitled project' check (char_length(title) <= 200),
 content jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(user_id, local_id)
);
create index if not exists mikrotekos_projects_user_updated_idx on public.mikrotekos_projects(user_id, updated_at desc);

create table if not exists public.mikrotekos_service_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id) on delete set null,
 customer_name text not null check (char_length(customer_name) between 1 and 200),
 customer_email text not null check (char_length(customer_email) between 3 and 320),
 service_type text not null check (char_length(service_type) between 1 and 160),
 details text not null check (char_length(details) between 1 and 10000),
 language text not null default 'sq' check (language in ('sq','en')),
 status text not null default 'received' check (status in ('received','reviewing','quoted','accepted','in_progress','completed','declined')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists mikrotekos_requests_user_created_idx on public.mikrotekos_service_requests(user_id, created_at desc);
create index if not exists mikrotekos_requests_status_created_idx on public.mikrotekos_service_requests(status, created_at desc);

create table if not exists public.mikrotekos_business_profiles (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 name text not null check (char_length(name) between 1 and 200),
 category text not null default 'general' check (char_length(category) <= 100),
 city text not null default '' check (char_length(city) <= 120),
 language text not null default 'sq' check (language in ('sq','en')),
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists mikrotekos_business_profiles_user_idx on public.mikrotekos_business_profiles(user_id, updated_at desc);

create table if not exists public.mikrotekos_automation_configs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 business_profile_id uuid references public.mikrotekos_business_profiles(id) on delete set null,
 name text not null default 'FAQ assistant' check (char_length(name) <= 200),
 config jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check (status in ('draft','disabled','active')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists mikrotekos_automation_user_idx on public.mikrotekos_automation_configs(user_id, updated_at desc);

create table if not exists public.mikrotekos_published_sites (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
 title text not null default 'Untitled website' check (char_length(title) <= 200),
 content jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check (status in ('draft','published')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 published_at timestamptz
);
create index if not exists mikrotekos_sites_user_idx on public.mikrotekos_published_sites(user_id, updated_at desc);

create table if not exists public.mikrotekos_service_packages (
 id text primary key,
 name_sq text not null,
 name_en text not null,
 description_sq text not null default '',
 description_en text not null default '',
 price_label text not null default '',
 active boolean not null default true,
 sort_order integer not null default 0,
 updated_at timestamptz not null default now()
);
insert into public.mikrotekos_service_packages(id,name_sq,name_en,description_sq,description_en,price_label,sort_order)
values
 ('starter-website','Uebsajt për biznes','Starter website','Faqe prezantuese e përshtatshme për telefon. Çmimi përfundimtar varet nga kërkesat.','Mobile-friendly business website. Final pricing depends on requirements.','€149–€299',1),
 ('social-content','Përmbajtje për rrjete sociale','Social media content','Planifikim dhe përmbajtje për rrjete sociale.','Planning and content for social media.','€99–€249 / month',2),
 ('business-automation','Automatizim fillestar','Business automation starter','Vlerësim fillestar për FAQ dhe procese të përsëritura.','Initial assessment for FAQs and repetitive workflows.','€199–€499 setup',3)
on conflict (id) do nothing;

create or replace function public.mikrotekos_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
create or replace function public.mikrotekos_create_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.mikrotekos_profiles(user_id, display_name)
 values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''))
 on conflict (user_id) do nothing;
 return new;
end;
$$;
drop trigger if exists mikrotekos_auth_user_created on auth.users;
create trigger mikrotekos_auth_user_created after insert on auth.users for each row execute function public.mikrotekos_create_profile();

alter table public.mikrotekos_profiles enable row level security;
alter table public.mikrotekos_workspaces enable row level security;
alter table public.mikrotekos_projects enable row level security;
alter table public.mikrotekos_service_requests enable row level security;
alter table public.mikrotekos_business_profiles enable row level security;
alter table public.mikrotekos_automation_configs enable row level security;
alter table public.mikrotekos_published_sites enable row level security;
alter table public.mikrotekos_service_packages enable row level security;

drop policy if exists mikrotekos_profile_read_self on public.mikrotekos_profiles;
create policy mikrotekos_profile_read_self on public.mikrotekos_profiles for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_profile_update_self on public.mikrotekos_profiles;
create policy mikrotekos_profile_update_self on public.mikrotekos_profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists mikrotekos_workspace_select_self on public.mikrotekos_workspaces;
create policy mikrotekos_workspace_select_self on public.mikrotekos_workspaces for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_workspace_insert_self on public.mikrotekos_workspaces;
create policy mikrotekos_workspace_insert_self on public.mikrotekos_workspaces for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_workspace_update_self on public.mikrotekos_workspaces;
create policy mikrotekos_workspace_update_self on public.mikrotekos_workspaces for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists mikrotekos_projects_read_self on public.mikrotekos_projects;
create policy mikrotekos_projects_read_self on public.mikrotekos_projects for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_projects_insert_self on public.mikrotekos_projects;
create policy mikrotekos_projects_insert_self on public.mikrotekos_projects for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_projects_update_self on public.mikrotekos_projects;
create policy mikrotekos_projects_update_self on public.mikrotekos_projects for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_projects_delete_self on public.mikrotekos_projects;
create policy mikrotekos_projects_delete_self on public.mikrotekos_projects for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists mikrotekos_requests_submit_public on public.mikrotekos_service_requests;
create policy mikrotekos_requests_submit_public on public.mikrotekos_service_requests for insert to anon, authenticated with check (
 char_length(customer_name) between 1 and 200 and char_length(customer_email) between 3 and 320 and
 char_length(service_type) between 1 and 160 and char_length(details) between 1 and 10000 and
 (user_id is null or user_id = (select auth.uid()))
);
drop policy if exists mikrotekos_requests_read_owner_or_admin on public.mikrotekos_service_requests;
create policy mikrotekos_requests_read_owner_or_admin on public.mikrotekos_service_requests for select to authenticated using (
 (select auth.uid()) = user_id or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);
drop policy if exists mikrotekos_requests_update_admin on public.mikrotekos_service_requests;
create policy mikrotekos_requests_update_admin on public.mikrotekos_service_requests for update to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists mikrotekos_business_self on public.mikrotekos_business_profiles;
create policy mikrotekos_business_self on public.mikrotekos_business_profiles for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists mikrotekos_automation_self on public.mikrotekos_automation_configs;
create policy mikrotekos_automation_self on public.mikrotekos_automation_configs for all to authenticated using ((select auth.uid()) = user_id and (business_profile_id is null or exists(select 1 from public.mikrotekos_business_profiles b where b.id = business_profile_id and b.user_id = (select auth.uid()))) ) with check ((select auth.uid()) = user_id and (business_profile_id is null or exists(select 1 from public.mikrotekos_business_profiles b where b.id = business_profile_id and b.user_id = (select auth.uid()))) );

drop policy if exists mikrotekos_sites_read_published on public.mikrotekos_published_sites;
create policy mikrotekos_sites_read_published on public.mikrotekos_published_sites for select to anon, authenticated using (status = 'published' or (select auth.uid()) = user_id or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
drop policy if exists mikrotekos_sites_insert_owner on public.mikrotekos_published_sites;
create policy mikrotekos_sites_insert_owner on public.mikrotekos_published_sites for insert to authenticated with check ((select auth.uid()) = user_id and status = 'draft');
drop policy if exists mikrotekos_sites_update_owner_draft on public.mikrotekos_published_sites;
create policy mikrotekos_sites_update_owner_draft on public.mikrotekos_published_sites for update to authenticated using ((select auth.uid()) = user_id and status = 'draft') with check ((select auth.uid()) = user_id and status = 'draft');
drop policy if exists mikrotekos_sites_admin_all on public.mikrotekos_published_sites;
create policy mikrotekos_sites_admin_all on public.mikrotekos_published_sites for all to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists mikrotekos_packages_read_active on public.mikrotekos_service_packages;
create policy mikrotekos_packages_read_active on public.mikrotekos_service_packages for select to anon, authenticated using (active = true);
drop policy if exists mikrotekos_packages_admin_manage on public.mikrotekos_service_packages;
create policy mikrotekos_packages_admin_manage on public.mikrotekos_service_packages for all to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop trigger if exists mikrotekos_workspace_updated on public.mikrotekos_workspaces;
create trigger mikrotekos_workspace_updated before update on public.mikrotekos_workspaces for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists mikrotekos_projects_updated on public.mikrotekos_projects;
create trigger mikrotekos_projects_updated before update on public.mikrotekos_projects for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists mikrotekos_requests_updated on public.mikrotekos_service_requests;
create trigger mikrotekos_requests_updated before update on public.mikrotekos_service_requests for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists mikrotekos_business_updated on public.mikrotekos_business_profiles;
create trigger mikrotekos_business_updated before update on public.mikrotekos_business_profiles for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists mikrotekos_automation_updated on public.mikrotekos_automation_configs;
create trigger mikrotekos_automation_updated before update on public.mikrotekos_automation_configs for each row execute function public.mikrotekos_set_updated_at();
drop trigger if exists mikrotekos_sites_updated on public.mikrotekos_published_sites;
create trigger mikrotekos_sites_updated before update on public.mikrotekos_published_sites for each row execute function public.mikrotekos_set_updated_at();

grant select on public.mikrotekos_service_packages to anon, authenticated;
grant insert on public.mikrotekos_service_requests to anon, authenticated;
grant select, update on public.mikrotekos_service_requests to authenticated;
grant select on public.mikrotekos_published_sites to anon, authenticated;
grant select, insert, update, delete on public.mikrotekos_profiles, public.mikrotekos_workspaces, public.mikrotekos_projects, public.mikrotekos_business_profiles, public.mikrotekos_automation_configs, public.mikrotekos_published_sites to authenticated;
revoke all on function public.mikrotekos_create_profile() from public, anon, authenticated;
revoke all on function public.mikrotekos_set_updated_at() from public, anon, authenticated;

create or replace function public.mikrotekos_publish_site(p_site_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_site public.mikrotekos_published_sites;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 update public.mikrotekos_published_sites set status='published', published_at=now(), updated_at=now()
 where id=p_site_id and user_id=auth.uid() and status='draft' returning * into v_site;
 if not found then raise exception 'Draft not found or not owned by current user'; end if;
 return jsonb_build_object('id',v_site.id,'slug',v_site.slug,'title',v_site.title,'status',v_site.status,'published_at',v_site.published_at);
end;
$$;
revoke all on function public.mikrotekos_publish_site(uuid) from public, anon;
grant execute on function public.mikrotekos_publish_site(uuid) to authenticated;
