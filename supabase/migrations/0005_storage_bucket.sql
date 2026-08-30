-- 0005_storage_bucket.sql
-- Creates the storage bucket the app uploads donation photos to, and a
-- basic public-read policy so the generated photo URLs actually load.

insert into storage.buckets (id, name, public)
values ('donation-photos', 'donation-photos', true)
on conflict (id) do nothing;

drop policy if exists "Public read donation photos" on storage.objects;
create policy "Public read donation photos"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'donation-photos');

drop policy if exists "Authenticated upload donation photos" on storage.objects;
create policy "Authenticated upload donation photos"
on storage.objects for insert
to authenticated
with check (bucket_id = 'donation-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "Owners update donation photos" on storage.objects;
create policy "Owners update donation photos"
on storage.objects for update
to authenticated
using (bucket_id = 'donation-photos' and owner_id = (select auth.uid())::text)
with check (bucket_id = 'donation-photos' and owner_id = (select auth.uid())::text);

drop policy if exists "Owners delete donation photos" on storage.objects;
create policy "Owners delete donation photos"
on storage.objects for delete
to authenticated
using (bucket_id = 'donation-photos' and owner_id = (select auth.uid())::text);
