-- Allow platform admins to verify Mitra accounts from the admin app.
-- The SECURITY DEFINER function performs a narrow, role-checked update so
-- authenticated users cannot promote themselves by writing profiles directly.

create or replace function public.admin_set_owner_verified(
  p_owner_id uuid,
  p_verified boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or public.current_app_role() is distinct from 'admin' then
    raise exception 'Hanya Admin yang dapat memverifikasi Mitra.'
      using errcode = '42501';
  end if;

  update public.profiles
  set owner_verified = p_verified
  where id = p_owner_id and role = 'kos_owner';

  if not found then
    raise exception 'Akun Mitra tidak ditemukan.'
      using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.admin_set_owner_verified(uuid, boolean) from public;
grant execute on function public.admin_set_owner_verified(uuid, boolean) to authenticated;
