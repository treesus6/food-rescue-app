-- Donation records are audit data. Values are recorded, never appraised by the app.
create table public.donation_receipts (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null unique references public.food_listings(id) on delete restrict,
  donor_id uuid not null references public.profiles(id) on delete restrict,
  recipient_id uuid references public.profiles(id) on delete set null,
  servings integer not null check (servings > 0),
  completed_at timestamptz not null,
  legal_notice_version text not null default 'RCW_69.80.031_v1',
  created_at timestamptz not null default now()
);

alter table public.donation_receipts enable row level security;
grant select on public.donation_receipts to authenticated;
create policy "receipts_participant_read" on public.donation_receipts for select to authenticated using ((select auth.uid()) in (donor_id, recipient_id));

comment on table public.donation_receipts is 'Pickup record only; not a charitable-value appraisal or tax deduction guarantee.';
