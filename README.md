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

## Safety and legal review

This project coordinates food recovery; it does not certify food safety, determine charitable eligibility, or assign tax value. The legal notice in `docs/legal-notice.md` must be reviewed by qualified Washington counsel or an established food-recovery nonprofit before public launch.
