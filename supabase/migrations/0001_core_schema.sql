-- Core domain model for the first Food Rescue release.
create extension if not exists pgcrypto;

create type public.donor_kind as enum ('individual', 'restaurant', 'grocery', 'farm', 'nonprofit');
create type public.listing_status as enum ('available', 'claimed', 'completed', 'cancelled', 'expired');
create type public.claim_status as enum ('active', 'completed', 'cancelled', 'no_show');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.donor_organizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  kind public.donor_kind not null,
  address_text text not null,
  latitude double precision,
  longitude double precision,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint donor_latitude_range check (latitude is null or latitude between -90 and 90),
  constraint donor_longitude_range check (longitude is null or longitude between -180 and 180)
);

create table public.food_listings (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid not null references public.profiles(id) on delete cascade,
  organization_id uuid references public.donor_organizations(id) on delete set null,
  title text not null check (char_length(title) between 3 and 120),
  description text not null default '',
  servings integer not null check (servings between 1 and 10000),
  pickup_address text not null,
  latitude double precision,
  longitude double precision,
  pickup_start timestamptz not null default now(),
  pickup_end timestamptz not null,
  allergens text[] not null default '{}',
  requires_refrigeration boolean not null default false,
  photo_path text,
  status public.listing_status not null default 'available',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint listing_pickup_window check (pickup_end > pickup_start),
  constraint listing_latitude_range check (latitude is null or latitude between -90 and 90),
  constraint listing_longitude_range check (longitude is null or longitude between -180 and 180)
);

create table public.claims (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null unique references public.food_listings(id) on delete cascade,
  rescuer_id uuid not null references public.profiles(id) on delete cascade,
  status public.claim_status not null default 'active',
  claimed_at timestamptz not null default now(),
  completed_at timestamptz,
  cancelled_at timestamptz
);

create table public.community_fridges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address_text text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  access_notes text not null default '',
  accepted_items text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index food_listings_available_pickup_idx on public.food_listings (pickup_end) where status = 'available';
create index food_listings_donor_idx on public.food_listings (donor_id, created_at desc);
create index claims_rescuer_idx on public.claims (rescuer_id, claimed_at desc);

grant usage on schema public to anon, authenticated;
grant select on public.community_fridges to anon, authenticated;
grant select on public.food_listings to anon, authenticated;
grant select, insert, update on public.profiles, public.donor_organizations, public.claims to authenticated;
grant insert, update, delete on public.food_listings to authenticated;
