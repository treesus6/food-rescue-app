-- Every public table is protected by row-level security.
alter table public.profiles enable row level security;
alter table public.donor_organizations enable row level security;
alter table public.food_listings enable row level security;
alter table public.claims enable row level security;
alter table public.community_fridges enable row level security;

create policy "profiles_read_own" on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "organizations_public_read" on public.donor_organizations for select to anon, authenticated using (true);
create policy "organizations_owner_insert" on public.donor_organizations for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "organizations_owner_update" on public.donor_organizations for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "organizations_owner_delete" on public.donor_organizations for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "listings_public_read" on public.food_listings for select to anon, authenticated using (status <> 'cancelled');
create policy "listings_donor_insert" on public.food_listings for insert to authenticated with check ((select auth.uid()) = donor_id);
create policy "listings_donor_update" on public.food_listings for update to authenticated using ((select auth.uid()) = donor_id) with check ((select auth.uid()) = donor_id);
create policy "listings_donor_delete" on public.food_listings for delete to authenticated using ((select auth.uid()) = donor_id);

create policy "claims_participant_read" on public.claims for select to authenticated using ((select auth.uid()) = rescuer_id or exists (select 1 from public.food_listings l where l.id = listing_id and l.donor_id = (select auth.uid())));
create policy "claims_rescuer_update" on public.claims for update to authenticated using ((select auth.uid()) = rescuer_id) with check ((select auth.uid()) = rescuer_id);

create policy "fridges_public_read" on public.community_fridges for select to anon, authenticated using (is_active);
