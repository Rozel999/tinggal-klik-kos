-- Shared owner verification workflow between the Mitra and admin apps.
begin;

create table if not exists public.owner_verifications (
  owner_id uuid primary key references public.profiles(id) on delete cascade,
  legal_name text,
  phone text,
  bank_name text,
  account_holder text,
  account_number text,
  ktp_object_path text,
  selfie_object_path text,
  status text not null default 'draft'
    check (status in ('draft', 'submitted', 'approved', 'rejected')),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id),
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint owner_verifications_ktp_path_check check (
    ktp_object_path is null or ktp_object_path like owner_id::text || '/ktp.%'
  ),
  constraint owner_verifications_selfie_path_check check (
    selfie_object_path is null or selfie_object_path like owner_id::text || '/selfie.%'
  )
);

create index if not exists owner_verifications_status_submitted_idx
  on public.owner_verifications(status, submitted_at desc);

-- Keep already verified accounts approved; all other Mitra accounts start as drafts.
insert into public.owner_verifications(owner_id, status)
select p.id, case when p.owner_verified then 'approved' else 'draft' end
from public.profiles p
where p.role = 'kos_owner'
on conflict (owner_id) do nothing;

create or replace function public.ensure_owner_verification_row()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'kos_owner' then
    insert into public.owner_verifications(owner_id, status)
    values (new.id, case when new.owner_verified then 'approved' else 'draft' end)
    on conflict (owner_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists ensure_owner_verification_row on public.profiles;
create trigger ensure_owner_verification_row
after insert or update of role on public.profiles
for each row execute function public.ensure_owner_verification_row();

create or replace function public.protect_owner_verification_changes()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_resubmitting boolean;
begin
  v_resubmitting := old.status = 'rejected' and new.status = 'submitted';
  if public.current_app_role() = 'admin' then
    return new;
  end if;
  if auth.uid() is distinct from old.owner_id
     or public.current_app_role() is distinct from 'kos_owner' then
    raise exception 'Tidak memiliki akses untuk mengubah data verifikasi Mitra.'
      using errcode = '42501';
  end if;
  if old.status not in ('draft', 'rejected') then
    raise exception 'Data tidak dapat diubah saat pengajuan sedang ditinjau atau sudah disetujui.'
      using errcode = '42501';
  end if;
  if (new.status is distinct from old.status
      and not (old.status in ('draft', 'rejected') and new.status = 'submitted'))
     or (not v_resubmitting and (
       new.reviewed_at is distinct from old.reviewed_at
       or new.reviewed_by is distinct from old.reviewed_by
       or new.review_note is distinct from old.review_note
     ))
     or (v_resubmitting and (
       new.reviewed_at is not null
       or new.reviewed_by is not null
       or new.review_note is not null
     ))
     or (new.status <> 'submitted'
         and new.submitted_at is distinct from old.submitted_at) then
    raise exception 'Status pengajuan hanya dapat diubah melalui alur verifikasi.'
      using errcode = '42501';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists protect_owner_verification_changes on public.owner_verifications;
create trigger protect_owner_verification_changes
before update on public.owner_verifications
for each row execute function public.protect_owner_verification_changes();

alter table public.owner_verifications enable row level security;
grant select on public.owner_verifications to authenticated;
grant update (
  legal_name, phone, bank_name, account_holder, account_number,
  ktp_object_path, selfie_object_path
) on public.owner_verifications to authenticated;

drop policy if exists owner_verifications_read_owner_or_admin on public.owner_verifications;
create policy owner_verifications_read_owner_or_admin
on public.owner_verifications for select to authenticated
using (owner_id = auth.uid() or public.is_platform_staff());

drop policy if exists owner_verifications_update_owner_draft on public.owner_verifications;
create policy owner_verifications_update_owner_draft
on public.owner_verifications for update to authenticated
using (
  owner_id = auth.uid()
  and public.current_app_role() = 'kos_owner'
  and status in ('draft', 'rejected')
)
with check (
  owner_id = auth.uid()
  and public.current_app_role() = 'kos_owner'
  and status in ('draft', 'rejected')
);

create or replace function public.submit_owner_verification()
returns void
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_record public.owner_verifications%rowtype;
begin
  if auth.uid() is null or public.current_app_role() is distinct from 'kos_owner' then
    raise exception 'Hanya akun Mitra yang dapat mengirim data verifikasi.'
      using errcode = '42501';
  end if;

  select * into v_record
  from public.owner_verifications
  where owner_id = auth.uid()
  for update;

  if not found then
    raise exception 'Data verifikasi Mitra belum tersedia.';
  end if;
  if v_record.status not in ('draft', 'rejected') then
    raise exception 'Pengajuan saat ini tidak dapat dikirim ulang.';
  end if;
  if coalesce(trim(v_record.legal_name), '') = ''
     or coalesce(trim(v_record.phone), '') = ''
     or coalesce(trim(v_record.bank_name), '') = ''
     or coalesce(trim(v_record.account_holder), '') = ''
     or coalesce(trim(v_record.account_number), '') = '' then
    raise exception 'Lengkapi data diri dan rekening terlebih dahulu.';
  end if;
  if v_record.ktp_object_path is null or v_record.selfie_object_path is null then
    raise exception 'Unggah KTP dan foto selfie terlebih dahulu.';
  end if;
  if not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'owner-verification-docs'
      and o.name = v_record.ktp_object_path
  ) or not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'owner-verification-docs'
      and o.name = v_record.selfie_object_path
  ) then
    raise exception 'File KTP atau selfie belum berhasil diunggah.';
  end if;

  update public.owner_verifications
  set status = 'submitted', submitted_at = now(), reviewed_at = null,
      reviewed_by = null, review_note = null, updated_at = now()
  where owner_id = auth.uid();
end;
$$;

create or replace function public.admin_review_owner_verification(
  p_owner_id uuid,
  p_approved boolean,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if auth.uid() is null or public.current_app_role() is distinct from 'admin' then
    raise exception 'Hanya Admin yang dapat meninjau pengajuan Mitra.'
      using errcode = '42501';
  end if;
  if not p_approved and coalesce(trim(p_note), '') = '' then
    raise exception 'Isi alasan penolakan agar Mitra tahu data yang perlu diperbaiki.';
  end if;

  v_status := case when p_approved then 'approved' else 'rejected' end;
  update public.owner_verifications
  set status = v_status,
      reviewed_at = now(),
      reviewed_by = auth.uid(),
      review_note = nullif(trim(p_note), ''),
      updated_at = now()
  where owner_id = p_owner_id and status = 'submitted';

  if not found then
    raise exception 'Pengajuan Mitra tidak ditemukan atau belum dikirim.';
  end if;

  update public.profiles
  set owner_verified = p_approved
  where id = p_owner_id and role = 'kos_owner';
end;
$$;

revoke all on function public.submit_owner_verification() from public;
revoke all on function public.admin_review_owner_verification(uuid, boolean, text) from public;
grant execute on function public.submit_owner_verification() to authenticated;
grant execute on function public.admin_review_owner_verification(uuid, boolean, text) to authenticated;

-- Remove the old boolean-only approval RPC: approval now requires a submitted record.
drop function if exists public.admin_set_owner_verified(uuid, boolean);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'owner-verification-docs',
  'owner-verification-docs',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists owner_verification_files_read_owner_or_admin on storage.objects;
create policy owner_verification_files_read_owner_or_admin
on storage.objects for select to authenticated
using (
  bucket_id = 'owner-verification-docs'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_platform_staff()
  )
);

drop policy if exists owner_verification_files_insert_owner on storage.objects;
create policy owner_verification_files_insert_owner
on storage.objects for insert to authenticated
with check (
  bucket_id = 'owner-verification-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_app_role() = 'kos_owner'
  and exists (
    select 1 from public.owner_verifications v
    where v.owner_id = auth.uid() and v.status in ('draft', 'rejected')
  )
  and (
    name ~ ('^' || auth.uid()::text || '/ktp\.(jpg|jpeg|png|webp)$')
    or name ~ ('^' || auth.uid()::text || '/selfie\.(jpg|jpeg|png|webp)$')
  )
);

drop policy if exists owner_verification_files_update_owner on storage.objects;
create policy owner_verification_files_update_owner
on storage.objects for update to authenticated
using (
  bucket_id = 'owner-verification-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_app_role() = 'kos_owner'
  and exists (
    select 1 from public.owner_verifications v
    where v.owner_id = auth.uid() and v.status in ('draft', 'rejected')
  )
)
with check (
  bucket_id = 'owner-verification-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_app_role() = 'kos_owner'
  and exists (
    select 1 from public.owner_verifications v
    where v.owner_id = auth.uid() and v.status in ('draft', 'rejected')
  )
  and (
    name ~ ('^' || auth.uid()::text || '/ktp\.(jpg|jpeg|png|webp)$')
    or name ~ ('^' || auth.uid()::text || '/selfie\.(jpg|jpeg|png|webp)$')
  )
);

drop policy if exists owner_verification_files_delete_owner on storage.objects;
create policy owner_verification_files_delete_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'owner-verification-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_app_role() = 'kos_owner'
  and exists (
    select 1 from public.owner_verifications v
    where v.owner_id = auth.uid() and v.status in ('draft', 'rejected')
  )
);

-- A Mitra may publish kos only after an admin has approved verification.
drop policy if exists kos_listings_insert_owner_only on public.kos_listings;
create policy kos_listings_insert_verified_owner on public.kos_listings
for insert to authenticated
with check (
  owner_id = auth.uid()
  and public.current_app_role() = 'kos_owner'
  and status = 'pending'
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.owner_verified = true
  )
);

drop policy if exists kos_listings_update_owner_or_staff on public.kos_listings;
create policy kos_listings_update_verified_owner_or_staff on public.kos_listings
for update to authenticated
using (
  public.is_platform_staff()
  or (
    owner_id = auth.uid()
    and public.current_app_role() = 'kos_owner'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.owner_verified = true
    )
  )
)
with check (
  public.is_platform_staff()
  or (
    owner_id = auth.uid()
    and public.current_app_role() = 'kos_owner'
    and status = 'pending'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.owner_verified = true
    )
  )
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'owner_verifications'
     ) then
    alter publication supabase_realtime add table public.owner_verifications;
  end if;
end;
$$;

commit;
