-- Atomic claim operation prevents two people from claiming the same food.
create or replace function public.claim_food_rescue(p_listing_id uuid)
returns public.claims
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_claim public.claims;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required' using errcode = '42501'; end if;

  update public.food_listings
  set status = 'claimed', updated_at = now()
  where id = p_listing_id and status = 'available' and pickup_end > now();

  if not found then raise exception 'This rescue is no longer available' using errcode = 'P0001'; end if;

  insert into public.claims (listing_id, rescuer_id)
  values (p_listing_id, (select auth.uid()))
  returning * into v_claim;
  return v_claim;
end;
$$;

revoke all on function public.claim_food_rescue(uuid) from public, anon;
grant execute on function public.claim_food_rescue(uuid) to authenticated;
