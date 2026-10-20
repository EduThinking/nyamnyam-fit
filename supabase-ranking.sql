-- 냠냠핏 랭킹 따봉. Supabase > SQL Editor에 전체를 붙여 넣고 Run.
-- One thumbs-up per person, per ranker, per week (week = Monday date in Korea time, e.g. 2026-10-19).

create table if not exists public.rank_likes (
  target uuid not null references auth.users on delete cascade,
  liker uuid not null default auth.uid() references auth.users on delete cascade,
  week text not null check (week ~ '^\d{4}-\d{2}-\d{2}$'),
  created_at timestamptz not null default now(),
  primary key (target, liker, week),
  check (target <> liker)
);
alter table public.rank_likes enable row level security;
create policy "likes read all" on public.rank_likes for select to authenticated using (true);
create policy "likes give own" on public.rank_likes for insert to authenticated with check (liker = auth.uid());
create policy "likes take back own" on public.rank_likes for delete to authenticated using (liker = auth.uid());
