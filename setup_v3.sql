-- GiftBox Pro V3 - interactive / multi-photo migration
-- Run this AFTER V2/V2-fixed. Safe to run again.

alter table public.gifts add column if not exists photo_urls jsonb not null default '[]'::jsonb;
alter table public.gifts add column if not exists effect text not null default 'hearts';
alter table public.gifts add column if not exists interaction_mode text not null default 'cake360';

do $$
begin
  if not exists (select 1 from pg_constraint where conname='gifts_effect_check') then
    alter table public.gifts add constraint gifts_effect_check
      check (effect in ('hearts','fireworks','petals','confetti','stars','mixed'));
  end if;
  if not exists (select 1 from pg_constraint where conname='gifts_interaction_mode_check') then
    alter table public.gifts add constraint gifts_interaction_mode_check
      check (interaction_mode in ('cake360','giftstory','memory'));
  end if;
end $$;

-- Backfill old gifts: keep the old single photo as the first gallery photo.
update public.gifts
set photo_urls = jsonb_build_array(photo_url)
where photo_url is not null
  and (photo_urls is null or photo_urls = '[]'::jsonb);

-- Return type changed again in V3 => DROP first.
drop function if exists public.get_gift_public(uuid);

create function public.get_gift_public(p_id uuid)
returns table (
  id uuid,
  recipient text,
  sender_name text,
  gift_title text,
  occasion text,
  message text,
  theme text,
  effect text,
  interaction_mode text,
  photo_url text,
  photo_urls jsonb,
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
  select
    g.id,g.recipient,g.sender_name,g.gift_title,g.occasion,g.message,
    g.theme,g.effect,g.interaction_mode,g.photo_url,g.photo_urls,g.music_url,
    g.open_at,g.created_at
  from public.gifts g
  where g.id=p_id
    and g.status='active'
    and (g.open_at is null or g.open_at <= now())
  limit 1;
end;
$$;

drop function if exists public.get_gift_gate(uuid);

create function public.get_gift_gate(p_id uuid)
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
  select true,g.open_at,g.status,g.recipient,g.occasion,g.theme
  from public.gifts g
  where g.id=p_id and g.status='active'
  limit 1;
$$;

revoke all on function public.get_gift_public(uuid) from public;
grant execute on function public.get_gift_public(uuid) to anon,authenticated;
revoke all on function public.get_gift_gate(uuid) from public;
grant execute on function public.get_gift_gate(uuid) to anon,authenticated;
