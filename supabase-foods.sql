-- 냠냠핏 음식 목록 공유 기능. Supabase > SQL Editor에 전체를 붙여 넣고 Run.

create table if not exists public.foods (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 40),
  amount text check (char_length(amount) <= 30),
  kcal int not null check (kcal between 0 and 5000),
  carb numeric not null default 0 check (carb between 0 and 1000),
  protein numeric not null default 0 check (protein between 0 and 1000),
  fat numeric not null default 0 check (fat between 0 and 1000),
  created_by uuid default auth.uid() references auth.users on delete set null,
  created_at timestamptz default now()
);
alter table public.foods enable row level security;
create policy "foods read" on public.foods for select to authenticated using (true);
create policy "foods insert own" on public.foods for insert to authenticated with check (created_by = auth.uid());
create policy "foods update own" on public.foods for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "foods delete own" on public.foods for delete to authenticated using (created_by = auth.uid());

-- How many times each food has been recorded (built-in or user-added). Only changed through bump_food.
create table if not exists public.food_stats (
  key text primary key check (char_length(key) <= 120),
  uses int not null default 0
);
alter table public.food_stats enable row level security;
create policy "food stats read" on public.food_stats for select to authenticated using (true);

create or replace function public.bump_food(k text) returns void
language sql security definer set search_path = public as $$
  insert into public.food_stats (key, uses) values (left(k, 120), 1)
  on conflict (key) do update set uses = public.food_stats.uses + 1;
$$;
revoke all on function public.bump_food(text) from public, anon;
grant execute on function public.bump_food(text) to authenticated;
