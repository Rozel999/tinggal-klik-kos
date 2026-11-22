-- Apply if the earlier three-role schema has already been created.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('customer','kos_owner','admin'));

