-- Run after 002_roles.sql in Supabase SQL Editor.
-- This migration enables sign-up profiles, row-level authorization and sync columns.

alter table public.profiles add column if not exists email text;
update public.profiles p set email = u.email from auth.users u where u.id = p.id and p.email is null;
create unique index if not exists profiles_email_unique on public.profiles(email) where email is not null;
alter table public.kos_listings add column if not exists owner_name text not null default 'Pemilik kos';
alter table public.bookings add column if not exists customer_name text not null default 'Pengguna';
alter table public.chat_messages add column if not exists sender_name text not null default 'Pengguna';
alter table public.invoices add column if not exists listing_name text not null default 'Kos';

create or replace function public.current_app_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_platform_staff()
returns boolean language sql stable security definer set search_path = public
as $$ select coalesce(public.current_app_role() in ('admin', 'app_owner'), false) $$;

create or replace function public.can_manage_listing(p_listing_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.kos_listings l
    where l.id = p_listing_id
      and (l.owner_id = auth.uid() and public.current_app_role() = 'kos_owner'
           or public.is_platform_staff())
  )
$$;

create or replace function public.can_access_booking(p_booking_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.bookings b
    join public.kos_listings l on l.id = b.listing_id
    where b.id = p_booking_id
      and (b.customer_id = auth.uid() or l.owner_id = auth.uid() or public.is_platform_staff())
  )
$$;

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare requested_role text;
begin
  requested_role := case when new.raw_user_meta_data ->> 'role' = 'kos_owner' then 'kos_owner' else 'customer' end;
  insert into public.profiles (id, email, display_name, role, owner_verified)
  values (new.id, new.email, coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Pengguna'), requested_role, false)
  on conflict (id) do update set email = excluded.email, display_name = excluded.display_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.profiles enable row level security;
alter table public.kos_listings enable row level security;
alter table public.kos_rooms enable row level security;
alter table public.bookings enable row level security;
alter table public.chat_messages enable row level security;
alter table public.invoices enable row level security;
alter table public.favorites enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.kos_listings, public.kos_rooms to anon, authenticated;
grant select, update (display_name) on public.profiles to authenticated;
grant select, insert, update, delete on public.kos_listings, public.kos_rooms, public.favorites to authenticated;
grant select, insert on public.bookings to authenticated;

revoke update on public.bookings from authenticated;

grant update (status) on public.bookings to authenticated;
grant select, insert on public.chat_messages to authenticated;
grant select on public.invoices to authenticated;

-- profiles: users cannot promote themselves or alter their role.
drop policy if exists profiles_read_self_or_staff on public.profiles;
create policy profiles_read_self_or_staff on public.profiles for select to authenticated
using (id = auth.uid() or public.is_platform_staff());
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

-- Listings: visitors see approved kos; owners submit pending listings; only staff moderates.
drop policy if exists kos_listings_read_visible on public.kos_listings;
create policy kos_listings_read_visible on public.kos_listings for select to anon, authenticated
using (status = 'approved' or owner_id = auth.uid() or public.is_platform_staff());
drop policy if exists kos_listings_insert_owner_or_staff on public.kos_listings;
create policy kos_listings_insert_owner_or_staff on public.kos_listings for insert to authenticated
with check ((owner_id = auth.uid() and public.current_app_role() = 'kos_owner' and status = 'pending') or public.is_platform_staff());
drop policy if exists kos_listings_update_owner_or_staff on public.kos_listings;
create policy kos_listings_update_owner_or_staff on public.kos_listings for update to authenticated
using ((owner_id = auth.uid() and public.current_app_role() = 'kos_owner') or public.is_platform_staff())
with check ((owner_id = auth.uid() and public.current_app_role() = 'kos_owner' and status = 'pending') or public.is_platform_staff());
drop policy if exists kos_listings_delete_owner_or_staff on public.kos_listings;
create policy kos_listings_delete_owner_or_staff on public.kos_listings for delete to authenticated
using ((owner_id = auth.uid() and public.current_app_role() = 'kos_owner') or public.is_platform_staff());

-- Rooms follow the visibility and ownership of their listing.
drop policy if exists kos_rooms_read_visible on public.kos_rooms;
create policy kos_rooms_read_visible on public.kos_rooms for select to anon, authenticated
using (exists (select 1 from public.kos_listings l where l.id = listing_id and (l.status = 'approved' or l.owner_id = auth.uid() or public.is_platform_staff())));
drop policy if exists kos_rooms_owner_or_staff on public.kos_rooms;
create policy kos_rooms_owner_or_staff on public.kos_rooms for all to authenticated
using (public.can_manage_listing(listing_id)) with check (public.can_manage_listing(listing_id));

-- Customers create their own requests; listing owners and staff manage their status.
drop policy if exists bookings_read_participants on public.bookings;
create policy bookings_read_participants on public.bookings for select to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.kos_listings l where l.id = listing_id and l.owner_id = auth.uid()) or public.is_platform_staff());
drop policy if exists bookings_insert_customer on public.bookings;
create policy bookings_insert_customer on public.bookings for insert to authenticated
with check (
  customer_id = auth.uid()
  and public.current_app_role() = 'customer'
  and status = 'pending'
  and exists (select 1 from public.kos_listings l where l.id = listing_id and l.status = 'approved')
);
drop policy if exists bookings_update_owner_or_staff on public.bookings;
create policy bookings_update_owner_or_staff on public.bookings for update to authenticated
using (exists (select 1 from public.kos_listings l where l.id = listing_id and l.owner_id = auth.uid()) or public.is_platform_staff())
with check (exists (select 1 from public.kos_listings l where l.id = listing_id and l.owner_id = auth.uid()) or public.is_platform_staff());

-- Chat is restricted to booking participants.
drop policy if exists chat_read_participants on public.chat_messages;
create policy chat_read_participants on public.chat_messages for select to authenticated
using (public.can_access_booking(booking_id));
drop policy if exists chat_insert_participant on public.chat_messages;
create policy chat_insert_participant on public.chat_messages for insert to authenticated
with check (sender_id = auth.uid() and public.can_access_booking(booking_id));

-- Invoice reads are private. The demo payment action is an RPC, never a client table update.
drop policy if exists invoices_read_participants on public.invoices;
create policy invoices_read_participants on public.invoices for select to authenticated
using (customer_id = auth.uid() or exists (select 1 from public.bookings b join public.kos_listings l on l.id = b.listing_id where b.id = booking_id and l.owner_id = auth.uid()) or public.is_platform_staff());

create or replace function public.mark_demo_invoice_paid(p_invoice_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  update public.invoices set status = 'paid'
  where id = p_invoice_id and customer_id = auth.uid() and status = 'unpaid';
  if not found then raise exception 'Invoice tidak ditemukan atau bukan milik pengguna ini'; end if;
end;
$$;
grant execute on function public.mark_demo_invoice_paid(uuid) to authenticated;

-- Favorites belong to the signed-in customer.
drop policy if exists favorites_owner_only on public.favorites;
create policy favorites_owner_only on public.favorites for all to authenticated
using (customer_id = auth.uid()) with check (customer_id = auth.uid());

create or replace function public.create_invoice_after_booking_accept()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status is distinct from new.status and new.kind = 'booking' then
    insert into public.invoices (booking_id, customer_id, listing_name, amount, due_at, status)
    select new.id, new.customer_id, l.name, l.monthly_price, now() + interval '30 days', 'unpaid'
    from public.kos_listings l where l.id = new.listing_id
    on conflict (booking_id) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists booking_accept_creates_invoice on public.bookings;
create trigger booking_accept_creates_invoice after update of status on public.bookings
for each row execute function public.create_invoice_after_booking_accept();

create or replace function public.refresh_listing_room_counts(p_listing_id uuid)
returns void language sql security definer set search_path = public
as $$
  update public.kos_listings l set
    rooms_total = (select count(*)::integer from public.kos_rooms r where r.listing_id = p_listing_id),
    rooms_available = (select count(*)::integer from public.kos_rooms r where r.listing_id = p_listing_id and r.status = 'available')
  where l.id = p_listing_id
$$;

create or replace function public.on_room_changed()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_listing_room_counts(old.listing_id);
    return old;
  end if;
  perform public.refresh_listing_room_counts(new.listing_id);
  if tg_op = 'UPDATE' and old.listing_id <> new.listing_id then
    perform public.refresh_listing_room_counts(old.listing_id);
  end if;
  return new;
end;
$$;
drop trigger if exists room_change_refresh_counts on public.kos_rooms;
create trigger room_change_refresh_counts after insert or update or delete on public.kos_rooms
for each row execute function public.on_room_changed();

-- Enable database change streams for cross-device updates, if publication exists.
do $$
declare t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['kos_listings','kos_rooms','bookings','chat_messages','invoices','favorites'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;


