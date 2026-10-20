-- 냠냠핏 database schema. Paste this whole file into Supabase > SQL Editor and press Run.

create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  data jsonb not null,
  channel text,
  updated_at timestamptz default now()
);
create table if not exists public.days (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  date text not null,
  data jsonb not null,
  updated_at timestamptz default now(),
  primary key (user_id, date)
);
create table if not exists public.friends (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  list jsonb not null default '{}'::jsonb
);
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  channel text not null,
  text text not null check (char_length(text) <= 1000),
  attach jsonb,
  created_at bigint not null
);
create table if not exists public.post_likes (
  post_id uuid references public.posts on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  primary key (post_id, user_id)
);
create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  text text not null check (char_length(text) <= 200),
  at bigint not null
);
create table if not exists public.cheers (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null default auth.uid() references auth.users on delete cascade,
  to_id uuid not null references auth.users on delete cascade,
  emoji text not null,
  at bigint not null
);
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  creator uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null, descr text, metric text not null,
  target int not null, reward int not null, badge text,
  start_date text not null, end_date text not null,
  vis text not null default 'friends', invited jsonb default '{}'::jsonb,
  created_at bigint not null
);
create table if not exists public.challenge_members (
  challenge_id uuid references public.challenges on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  progress int not null default 0,
  active boolean not null default true,
  primary key (challenge_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.days enable row level security;
alter table public.friends enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.cheers enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_members enable row level security;

-- Profiles: every signed-in user can see profiles (ranking, friends); each user edits only their own.
create policy "profiles read" on public.profiles for select to authenticated using (true);
create policy "profiles insert own" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles update own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles delete own" on public.profiles for delete to authenticated using (id = auth.uid());
-- Daily logs and friend lists: private to their owner.
create policy "days own" on public.days for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "friends own" on public.friends for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Community
create policy "posts read" on public.posts for select to authenticated using (true);
create policy "posts insert own" on public.posts for insert to authenticated with check (user_id = auth.uid());
create policy "posts delete own" on public.posts for delete to authenticated using (user_id = auth.uid());
create policy "likes read" on public.post_likes for select to authenticated using (true);
create policy "likes insert own" on public.post_likes for insert to authenticated with check (user_id = auth.uid());
create policy "likes delete own" on public.post_likes for delete to authenticated using (user_id = auth.uid());
create policy "comments read" on public.post_comments for select to authenticated using (true);
create policy "comments insert own" on public.post_comments for insert to authenticated with check (user_id = auth.uid());
create policy "comments delete own" on public.post_comments for delete to authenticated using (user_id = auth.uid());
-- Cheers: only sender and receiver see them.
create policy "cheers read" on public.cheers for select to authenticated using (to_id = auth.uid() or from_id = auth.uid());
create policy "cheers insert own" on public.cheers for insert to authenticated with check (from_id = auth.uid());
-- Challenges
create policy "challenges read" on public.challenges for select to authenticated using (true);
create policy "challenges insert own" on public.challenges for insert to authenticated with check (creator = auth.uid());
create policy "challenges delete own" on public.challenges for delete to authenticated using (creator = auth.uid());
create policy "members read" on public.challenge_members for select to authenticated using (true);
create policy "members insert own" on public.challenge_members for insert to authenticated with check (user_id = auth.uid());
create policy "members update own" on public.challenge_members for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "members delete own" on public.challenge_members for delete to authenticated using (user_id = auth.uid());

create index if not exists posts_channel_idx on public.posts (channel, created_at desc);
create index if not exists cheers_to_idx on public.cheers (to_id, at desc);
