-- GiftBox Pro V2 - Supabase migration / fresh setup
-- Safe to run on top of V1. Uses email + password authentication.

create extension if not exists pgcrypto;

-- =========================
-- 1. USER PROFILES
-- =========================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "users can read own profile" on public.profiles;
create policy "users can read own profile"
on public.profiles for select to authenticated
using (auth.uid() = id);

drop policy if exists "users can update own profile" on public.profiles;
create policy "users can update own profile"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Backfill profiles for existing V1 users.
insert into public.profiles (id, full_name)
select id, coalesce(raw_user_meta_data->>'full_name', split_part(email, '@', 1))
from auth.users
on conflict (id) do nothing;

-- =========================
-- 2. GIFTS
-- =========================
create table if not exists public.gifts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  recipient text not null check (char_length(recipient) between 1 and 100),
  occasion text not null default 'Happy Birthday' check (char_length(occasion) between 1 and 100),
  message text not null check (char_length(message) between 1 and 5000),
  photo_url text,
  music_url text,
  created_at timestamptz not null default now()
);

-- V2 columns. Safe for an existing V1 table.
alter table public.gifts add column if not exists sender_name text;
alter table public.gifts add column if not exists gift_title text;
alter table public.gifts add column if not exists theme text not null default 'rose';
alter table public.gifts add column if not exists open_at timestamptz;
alter table public.gifts add column if not exists status text not null default 'active';
alter table public.gifts add column if not exists view_count integer not null default 0;
alter table public.gifts add column if not exists first_opened_at timestamptz;
alter table public.gifts add column if not exists updated_at timestamptz not null default now();

-- Add constraints only when they do not already exist.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'gifts_theme_check') then
    alter table public.gifts add constraint gifts_theme_check
      check (theme in ('rose','midnight','gold','sky','violet'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'gifts_status_check') then
    alter table public.gifts add constraint gifts_status_check
      check (status in ('active','draft','archived'));
  end if;
end $$;

alter table public.gifts enable row level security;

drop policy if exists "owners can read their gifts" on public.gifts;
create policy "owners can read their gifts"
on public.gifts for select to authenticated
using (auth.uid() = owner_id);

drop policy if exists "owners can create gifts" on public.gifts;
create policy "owners can create gifts"
on public.gifts for insert to authenticated
with check (auth.uid() = owner_id);

drop policy if exists "owners can update their gifts" on public.gifts;
create policy "owners can update their gifts"
on public.gifts for update to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "owners can delete their gifts" on public.gifts;
create policy "owners can delete their gifts"
on public.gifts for delete to authenticated
using (auth.uid() = owner_id);

create index if not exists idx_gifts_owner_created
on public.gifts(owner_id, created_at desc);

-- Public gift API. It returns only fields needed by recipient page.
-- Draft/archived gifts are not exposed.
create or replace function public.get_gift_public(p_id uuid)
returns table (
  id uuid,
  recipient text,
  sender_name text,
  gift_title text,
  occasion text,
  message text,
  theme text,
  photo_url text,
  music_url text,
  open_at timestamptz,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.gifts g
  set view_count = g.view_count + 1,
      first_opened_at = coalesce(g.first_opened_at, now())
  where g.id = p_id
    and g.status = 'active'
    and (g.open_at is null or g.open_at <= now());

  return query
  select g.id, g.recipient, g.sender_name, g.gift_title, g.occasion,
         g.message, g.theme, g.photo_url, g.music_url, g.open_at, g.created_at
  from public.gifts g
  where g.id = p_id
    and g.status = 'active'
    and (g.open_at is null or g.open_at <= now())
  limit 1;
end;
$$;

-- Small public function so gift.html can distinguish "not found" from "not yet open".
create or replace function public.get_gift_gate(p_id uuid)
returns table (
  exists_public boolean,
  open_at timestamptz,
  status text,
  recipient text,
  occasion text,
  theme text
)
language sql
security definer
set search_path = public
as $$
  select true, g.open_at, g.status, g.recipient, g.occasion, g.theme
  from public.gifts g
  where g.id = p_id and g.status = 'active'
  limit 1;
$$;

revoke all on function public.get_gift_public(uuid) from public;
grant execute on function public.get_gift_public(uuid) to anon, authenticated;
revoke all on function public.get_gift_gate(uuid) from public;
grant execute on function public.get_gift_gate(uuid) to anon, authenticated;

-- =========================
-- 3. STORAGE
-- =========================
insert into storage.buckets (id, name, public)
values ('gift-media', 'gift-media', true)
on conflict (id) do update set public = true;

drop policy if exists "authenticated users upload gift media" on storage.objects;
create policy "authenticated users upload gift media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'gift-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "public can view gift media" on storage.objects;
create policy "public can view gift media"
on storage.objects for select to public
using (bucket_id = 'gift-media');

drop policy if exists "authenticated users delete gift media" on storage.objects;
create policy "authenticated users delete gift media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'gift-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
