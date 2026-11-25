-- Reconcile the live database with tables expected by the app, and retain
-- chat messages for 24 hours. The cleanup job runs every six hours.
begin;

create table if not exists public.kos_reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  listing_id uuid not null references public.kos_listings(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  customer_name text not null default 'Pengguna',
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now()
);

alter table public.kos_reviews enable row level security;
grant select on public.kos_reviews to anon, authenticated;
grant insert on public.kos_reviews to authenticated;

drop policy if exists kos_reviews_read_visible on public.kos_reviews;
create policy kos_reviews_read_visible on public.kos_reviews
for select to anon, authenticated
using (
  customer_id = auth.uid()
  or public.is_platform_staff()
  or exists (
    select 1 from public.kos_listings l
    where l.id = kos_reviews.listing_id
      and (l.status = 'approved' or l.owner_id = auth.uid())
  )
);

drop policy if exists kos_reviews_insert_completed_customer on public.kos_reviews;
create policy kos_reviews_insert_completed_customer on public.kos_reviews
for insert to authenticated
with check (
  customer_id = auth.uid()
  and exists (
    select 1 from public.bookings b
    where b.id = kos_reviews.booking_id
      and b.listing_id = kos_reviews.listing_id
      and b.customer_id = auth.uid()
      and b.status = 'completed'
      and b.kind = 'booking'
  )
);

create or replace function public.set_kos_review_customer_name()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  select display_name into new.customer_name
  from public.profiles where id = new.customer_id;
  return new;
end;
$$;

drop trigger if exists set_kos_review_customer_name on public.kos_reviews;
create trigger set_kos_review_customer_name
before insert on public.kos_reviews
for each row execute function public.set_kos_review_customer_name();

create index if not exists chat_messages_sent_at_idx
  on public.chat_messages(sent_at);

create or replace function public.cleanup_old_chat_messages()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count bigint;
begin
  delete from public.chat_messages
  where sent_at < now() - interval '24 hours';
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function public.cleanup_old_chat_messages() from public, anon, authenticated;

-- Supabase provides pg_cron. Schedule idempotently so rerunning this migration
-- replaces the existing job instead of creating duplicate cleanup jobs.
create extension if not exists pg_cron;
do $$
declare
  old_job record;
begin
  for old_job in
    select jobid from cron.job where jobname = 'tinggal-klik-kos-chat-cleanup'
  loop
    perform cron.unschedule(old_job.jobid);
  end loop;
  perform cron.schedule(
    'tinggal-klik-kos-chat-cleanup',
    '0 */6 * * *',
    'select public.cleanup_old_chat_messages();'
  );
end;
$$;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'kos_reviews'
     ) then
    alter publication supabase_realtime add table public.kos_reviews;
  end if;
end;
$$;

notify pgrst, 'reload schema';
commit;
