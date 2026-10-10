# Food Rescue

Food Rescue connects restaurants, grocery stores, farms, and neighbors with people and community fridges that can use safe surplus food.

## Interactive prototype

The first mobile-friendly product prototype is available at:

**https://food-rescue-app.treevanderveer.chatgpt.site**

It demonstrates the core loop: browse nearby surplus food, review pickup and safety details, claim a rescue, post a donation, find community fridges, and see community impact.

## First-release scope

- Time-limited food listings with pickup windows and allergen notes
- Atomic claiming so one listing cannot be claimed twice
- Restaurant, store, nonprofit, farm, and individual donors
- Community-fridge locations
- Donation completion records (not automated tax appraisals)
- Photo storage restricted to authenticated owners
- Row-level security on every public table

## Database

Supabase migrations live in `supabase/migrations` and must be applied in numeric order. The schema grants Data API access explicitly because new Supabase projects may not expose SQL-created tables automatically.

## Database regression tests

Run `npm ci && npm test` with Node 22 or newer. Tests apply migrations 0001–0004
to PGlite's PostgreSQL engine and exercise authenticated and anonymous roles:
claim persistence and duplicate rejection, expired/cancelled listings,
organization ownership, server-controlled verification, and owner deletion.
The harness supplies minimal `auth.users` and `auth.uid()` fixtures and omits the
pgcrypto extension statement (UUID generation is built in). It does not verify
hosted Supabase Auth, PostgREST, storage migration 0005, or real concurrent clients.
The private schema containing the trusted claim writer must remain unexposed in
the hosted Data API. Hosted migration/advisor checks remain required before merge.
These are initial migrations in an unmerged foundation PR. Inspect hosted migration
history before applying them; an existing installation needs forward migrations
for the permission changes, not a rerun of initial schema creation.

## Safety and legal review

This project coordinates food recovery; it does not certify food safety, determine charitable eligibility, or assign tax value. The legal notice in `docs/legal-notice.md` must be reviewed by qualified Washington counsel or an established food-recovery nonprofit before public launch.
