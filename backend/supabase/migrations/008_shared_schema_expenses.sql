-- Align the shared project schema with the partner app's room, invoice,
-- and owner-expense fields. Safe to run against an existing project.
begin;

alter table public.kos_rooms
  add column if not exists daily_price integer
    check (daily_price is null or daily_price >= 0);

alter table public.invoices
  add column if not exists late_fee integer not null default 0
    check (late_fee >= 0),
  add column if not exists paid_amount integer not null default 0;

create table if not exists public.owner_expenses (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.kos_listings(id),
  description text not null,
  amount bigint not null check (amount > 0),
  spent_on date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists owner_expenses_listing_date_idx
  on public.owner_expenses(listing_id, spent_on desc);

alter table public.owner_expenses enable row level security;
grant select, insert, update, delete on public.owner_expenses to authenticated;

drop policy if exists owner_expenses_read_owner_or_admin on public.owner_expenses;
create policy owner_expenses_read_owner_or_admin on public.owner_expenses
for select to authenticated
using (
  public.is_platform_staff()
  or exists (
    select 1 from public.kos_listings l
    where l.id = owner_expenses.listing_id
      and l.owner_id = auth.uid()
      and public.current_app_role() = 'kos_owner'
  )
);

drop policy if exists owner_expenses_insert_owner on public.owner_expenses;
create policy owner_expenses_insert_owner on public.owner_expenses
for insert to authenticated
with check (
  exists (
    select 1 from public.kos_listings l
    where l.id = owner_expenses.listing_id
      and l.owner_id = auth.uid()
      and public.current_app_role() = 'kos_owner'
  )
);

drop policy if exists owner_expenses_update_owner on public.owner_expenses;
create policy owner_expenses_update_owner on public.owner_expenses
for update to authenticated
using (
  exists (
    select 1 from public.kos_listings l
    where l.id = owner_expenses.listing_id
      and l.owner_id = auth.uid()
      and public.current_app_role() = 'kos_owner'
  )
)
with check (
  exists (
    select 1 from public.kos_listings l
    where l.id = owner_expenses.listing_id
      and l.owner_id = auth.uid()
      and public.current_app_role() = 'kos_owner'
  )
);

drop policy if exists owner_expenses_delete_owner on public.owner_expenses;
create policy owner_expenses_delete_owner on public.owner_expenses
for delete to authenticated
using (
  exists (
    select 1 from public.kos_listings l
    where l.id = owner_expenses.listing_id
      and l.owner_id = auth.uid()
      and public.current_app_role() = 'kos_owner'
  )
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'owner_expenses'
     ) then
    alter publication supabase_realtime add table public.owner_expenses;
  end if;
end;
$$;

commit;
