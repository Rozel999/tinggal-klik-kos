-- The Pencari Kos admin app is an operations/moderation console.
-- Listing creation and content edits belong to the separate Mitra app.

drop policy if exists kos_listings_insert_owner_or_staff on public.kos_listings;
create policy kos_listings_insert_owner_only on public.kos_listings
for insert to authenticated
with check (owner_id = auth.uid()
  and public.current_app_role() = 'kos_owner'
  and status = 'pending');

drop policy if exists kos_listings_delete_owner_or_staff on public.kos_listings;
create policy kos_listings_delete_owner_only on public.kos_listings
for delete to authenticated
using (owner_id = auth.uid()
  and public.current_app_role() = 'kos_owner');

create or replace function public.protect_listing_content_from_admin()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if public.current_app_role() = 'admin' and (
    new.owner_id is distinct from old.owner_id or
    new.name is distinct from old.name or
    new.address is distinct from old.address or
    new.description is distinct from old.description or
    new.monthly_price is distinct from old.monthly_price or
    new.gender is distinct from old.gender or
    new.rooms_total is distinct from old.rooms_total or
    new.rooms_available is distinct from old.rooms_available or
    new.amenities is distinct from old.amenities or
    new.latitude is distinct from old.latitude or
    new.longitude is distinct from old.longitude
  ) then
    raise exception 'Admin hanya dapat mengubah status moderasi listing.';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_listing_content_from_admin on public.kos_listings;
create trigger protect_listing_content_from_admin
before update on public.kos_listings
for each row execute function public.protect_listing_content_from_admin();
