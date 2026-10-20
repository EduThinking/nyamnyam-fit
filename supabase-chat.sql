-- 냠냠핏 전체 실시간 채팅. Supabase > SQL Editor에 전체를 붙여 넣고 Run.

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  text text not null check (char_length(text) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists chat_messages_created_idx on public.chat_messages (created_at desc);

alter table public.chat_messages enable row level security;
create policy "chat read" on public.chat_messages for select to authenticated using (true);
create policy "chat send own" on public.chat_messages for insert to authenticated with check (user_id = auth.uid());
create policy "chat delete own" on public.chat_messages for delete to authenticated using (user_id = auth.uid());

-- Deliver new and deleted messages to open apps in real time.
alter publication supabase_realtime add table public.chat_messages;
