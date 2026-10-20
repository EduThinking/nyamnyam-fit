-- 냠냠핏 보상 기능 (출석 덤벨 선물·덤벨 주고받기). Supabase > SQL Editor에 전체를 붙여 넣고 Run.

create table if not exists public.wallets (
  user_id uuid primary key references auth.users on delete cascade,
  dumbbells int not null default 0 check (dumbbells >= 0),
  received int not null default 0,
  sent int not null default 0,
  last_gift date
);
alter table public.wallets enable row level security;
-- Everyone can read balances; nobody writes directly. Changes only go through the functions below.
create policy "wallets read" on public.wallets for select to authenticated using (true);

alter table public.cheers add column if not exists amount int not null default 0;

-- Daily check-in gift: 50 dumbbells once per day (Korea time).
create or replace function public.claim_daily_gift() returns json
language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Asia/Seoul')::date;
  w public.wallets;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  insert into public.wallets (user_id) values (auth.uid()) on conflict do nothing;
  update public.wallets set dumbbells = dumbbells + 50, last_gift = today
    where user_id = auth.uid() and (last_gift is null or last_gift < today)
    returning * into w;
  if found then return json_build_object('gifted', true, 'dumbbells', w.dumbbells, 'received', w.received, 'sent', w.sent); end if;
  select * into w from public.wallets where user_id = auth.uid();
  return json_build_object('gifted', false, 'dumbbells', w.dumbbells, 'received', w.received, 'sent', w.sent);
end $$;

-- Give dumbbells to another user together with a cheer.
create or replace function public.send_dumbbells(to_id uuid, amount int, emoji text) returns json
language plpgsql security definer set search_path = public as $$
declare w public.wallets;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  if to_id = auth.uid() then raise exception 'self_gift'; end if;
  if amount is null or amount < 1 or amount > 1000 then raise exception 'bad_amount'; end if;
  update public.wallets set dumbbells = dumbbells - amount, sent = sent + amount
    where user_id = auth.uid() and dumbbells >= amount returning * into w;
  if not found then raise exception 'not_enough'; end if;
  insert into public.wallets (user_id) values (to_id) on conflict do nothing;
  update public.wallets set dumbbells = dumbbells + amount, received = received + amount where user_id = to_id;
  insert into public.cheers (from_id, to_id, emoji, at, amount)
    values (auth.uid(), to_id, left(coalesce(emoji, '💪'), 8), (extract(epoch from now()) * 1000)::bigint, amount);
  return json_build_object('dumbbells', w.dumbbells, 'received', w.received, 'sent', w.sent);
end $$;

revoke all on function public.claim_daily_gift() from public, anon;
revoke all on function public.send_dumbbells(uuid, int, text) from public, anon;
grant execute on function public.claim_daily_gift() to authenticated;
grant execute on function public.send_dumbbells(uuid, int, text) to authenticated;
