-- 0005_storage_bucket.sql
-- Creates the storage bucket the app uploads donation photos to, and a
-- basic public-read policy so the generated photo URLs actually load.

insert into storage.buckets (id, name, public)
values ('donation-photos', 'donation-photos', true)
on conflict (id) do nothing;

create policy if not exists "Public read donation photos"
on storage.objects for select
using (bucket_id = 'donation-photos');

create policy if not exists "Authenticated upload donation photos"
on storage.objects for insert
with check (bucket_id = 'donation-photos' and auth.role() = 'authenticated');