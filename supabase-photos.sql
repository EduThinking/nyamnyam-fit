-- 냠냠핏 채널 글 사진 첨부. Supabase > SQL Editor에 전체를 붙여 넣고 Run.

alter table public.posts add column if not exists images text[] not null default '{}';

-- Public bucket: anyone with the link can view a photo; only the owner can upload/delete in their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('post-images', 'post-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

create policy "post images upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'post-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "post images delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'post-images' and (storage.foldername(name))[1] = auth.uid()::text);
