-- Consolidate platform owner privileges into admin.
-- Run once in the Supabase SQL Editor after migrations 002 and 003.
begin;

update public.profiles set role = 'admin' where role = 'app_owner';

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('customer', 'kos_owner', 'admin'));

create or replace function public.is_platform_staff()
returns boolean language sql stable security definer set search_path = public
as $$ select coalesce(public.current_app_role() = 'admin', false) $$;

create or replace function public.can_manage_listing(p_listing_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.kos_listings l
    where l.id = p_listing_id
      and ((l.owner_id = auth.uid() and public.current_app_role() = 'kos_owner')
           or public.is_platform_staff())
  )
$$;

commit;
