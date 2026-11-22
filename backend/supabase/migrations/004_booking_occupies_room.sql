-- Assign an actual room to an accepted booking and mark it occupied atomically.
alter table public.bookings
  add column if not exists room_id uuid references public.kos_rooms(id) on delete set null;

create or replace function public.accept_kos_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_listing_id uuid;
  v_room_id uuid;
  v_status text;
begin
  select b.listing_id, b.status
    into v_listing_id, v_status
    from public.bookings b
   where b.id = p_booking_id
   for update;

  if not found then
    raise exception 'Booking tidak ditemukan';
  end if;
  if not public.can_manage_listing(v_listing_id) then
    raise exception 'Tidak memiliki akses untuk menerima booking ini';
  end if;
  if v_status <> 'pending' then
    raise exception 'Booking ini sudah diproses';
  end if;

  select r.id into v_room_id
    from public.kos_rooms r
   where r.listing_id = v_listing_id
     and r.status = 'available'
   order by r.label
   limit 1
   for update skip locked;

  if v_room_id is null then
    raise exception 'Tidak ada kamar tersedia untuk booking ini';
  end if;

  update public.kos_rooms set status = 'occupied' where id = v_room_id;
  update public.bookings
     set status = 'accepted', room_id = v_room_id
   where id = p_booking_id;
end;
$$;

grant execute on function public.accept_kos_booking(uuid) to authenticated;

-- Reconcile older accepted bookings that predate room assignment.
do $$
declare
  b record;
  r_id uuid;
begin
  for b in
    select id, listing_id
      from public.bookings
     where status = 'accepted' and kind = 'booking' and room_id is null
     order by created_at
  loop
    select id into r_id
      from public.kos_rooms
     where listing_id = b.listing_id and status = 'available'
     order by label
     limit 1
     for update skip locked;
    if r_id is not null then
      update public.kos_rooms set status = 'occupied' where id = r_id;
      update public.bookings set room_id = r_id where id = b.id;
    end if;
    r_id := null;
  end loop;
end $$;
