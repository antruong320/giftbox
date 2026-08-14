-- GiftBox V1 - run this entire script in Supabase SQL Editor.
-- This version uses Supabase Auth for the creator/admin and a public random gift ID
-- for recipients. Do NOT use a service/secret key in the website.

create extension if not exists pgcrypto;

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

alter table public.gifts enable row level security;

drop policy if exists "owners can read their gifts" on public.gifts;
create policy "owners can read their gifts"
on public.gifts for select
to authenticated
using (auth.uid() = owner_id);

drop policy if exists "owners can create gifts" on public.gifts;
create policy "owners can create gifts"
on public.gifts for insert
to authenticated
with check (auth.uid() = owner_id);

drop policy if exists "owners can update their gifts" on public.gifts;
create policy "owners can update their gifts"
on public.gifts for update
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

-- Recipients need to open a gift without logging in.
-- We intentionally expose only the fields needed for the public gift page.
create or replace function public.get_gift_public(p_id uuid)
returns table (
  id uuid,
  recipient text,
  occasion text,
  message text,
  photo_url text,
  music_url text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select g.id, g.recipient, g.occasion, g.message, g.photo_url, g.music_url, g.created_at
  from public.gifts g
  where g.id = p_id
  limit 1;
$$;

revoke all on function public.get_gift_public(uuid) from public;
grant execute on function public.get_gift_public(uuid) to anon, authenticated;

-- Storage bucket for gift media.
insert into storage.buckets (id, name, public)
values ('gift-media', 'gift-media', true)
on conflict (id) do update set public = true;

drop policy if exists "authenticated users upload gift media" on storage.objects;
create policy "authenticated users upload gift media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'gift-media');

drop policy if exists "public can view gift media" on storage.objects;
create policy "public can view gift media"
on storage.objects for select
to public
using (bucket_id = 'gift-media');

-- Allow owners to delete their own uploaded files later.
drop policy if exists "authenticated users delete gift media" on storage.objects;
create policy "authenticated users delete gift media"
on storage.objects for delete
to authenticated
using (bucket_id = 'gift-media' and owner_id = auth.uid());
