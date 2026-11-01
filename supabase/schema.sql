-- ============================================================
--  NumisVault — схема базы данных Supabase
--  Выполните этот скрипт целиком в SQL Editor вашего проекта.
-- ============================================================

-- 1. Таблица монет ------------------------------------------------------------
create table if not exists public.coins (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  title        text not null default '',
  country      text not null default '',
  year         integer,
  mint         text not null default '',
  metal        text not null default 'silver',
  fineness     text not null default '',
  obverse_desc text not null default '',
  reverse_desc text not null default '',
  weight       double precision,
  diameter     double precision,
  mintage      text not null default '',
  grade        text not null default 'vf',
  updated_at   timestamptz not null default now()
);

create index if not exists coins_user_idx on public.coins (user_id, updated_at desc);

-- 2. Таблица PNG-сторон (base64) ---------------------------------------------
create table if not exists public.coin_images (
  id         text primary key,          -- '<coin_uuid>:obverse' | '<coin_uuid>:reverse'
  user_id    uuid not null references auth.users (id) on delete cascade,
  coin_id    uuid not null,
  face       text not null check (face in ('obverse', 'reverse')),
  png        text not null,             -- base64 PNG с прозрачным фоном
  updated_at timestamptz not null default now()
);

create index if not exists coin_images_coin_idx on public.coin_images (coin_id);
create index if not exists coin_images_user_idx on public.coin_images (user_id);

-- 3. Row Level Security: каждый видит только свою коллекцию ------------------
alter table public.coins        enable row level security;
alter table public.coin_images  enable row level security;

drop policy if exists "own coins" on public.coins;
create policy "own coins" on public.coins
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own images" on public.coin_images;
create policy "own images" on public.coin_images
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Realtime для таблицы монет ---------------------------------------------
-- Если строка ниже выдаст ошибку «already member of publication» — таблица
-- уже добавлена, это нормально.
alter publication supabase_realtime add table public.coins;

-- 5. (необязательно) Статистика -------------------------------------------------
create or replace view public.vault_stats as
select user_id,
       count(*)                      as coins_count,
       count(*) filter (where year is not null) as with_year,
       min(year)                     as oldest,
       max(year)                     as newest
from public.coins
group by user_id;
