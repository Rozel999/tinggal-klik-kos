-- Run in Supabase SQL Editor after migrations 003 through 010.
-- Every row should report present/true before rebuilding and testing the app.
with required(table_name) as (
  values
    ('profiles'),
    ('kos_listings'),
    ('kos_rooms'),
    ('bookings'),
    ('chat_messages'),
    ('invoices'),
    ('favorites'),
    ('kos_reviews'),
    ('owner_expenses'),
    ('owner_verifications')
)
select r.table_name,
       to_regclass(format('public.%I', r.table_name)) is not null as object_exists,
       coalesce(c.relrowsecurity, false) as rls_enabled
from required r
left join pg_class c
  on c.oid = to_regclass(format('public.%I', r.table_name))
order by r.table_name;

select required.function_name,
       to_regprocedure(required.signature) is not null as object_exists
from (values
  ('accept_kos_booking', 'public.accept_kos_booking(uuid)'),
  ('mark_demo_invoice_paid', 'public.mark_demo_invoice_paid(uuid)'),
  ('submit_owner_verification', 'public.submit_owner_verification()'),
  ('admin_review_owner_verification',
   'public.admin_review_owner_verification(uuid,boolean,text)'),
  ('cleanup_old_chat_messages', 'public.cleanup_old_chat_messages()')
) as required(function_name, signature)
order by required.function_name;

select id as bucket_id, public as is_public
from storage.buckets
where id = 'owner-verification-docs';

select jobname, schedule, active
from cron.job
where jobname = 'tinggal-klik-kos-chat-cleanup';
