-- Initial data model for PostgreSQL/Supabase. Run only after reviewing policies.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null check (role in ('customer','kos_owner','admin')),
  owner_verified boolean not null default false,
  created_at timestamptz not null default now(),
  email text
);

create table if not exists public.kos_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  name text not null,
  address text not null,
  description text not null default '',
  monthly_price integer not null check (monthly_price >= 0),
  gender text not null,
  rooms_total integer not null default 0 check (rooms_total >= 0),
  rooms_available integer not null default 0 check (rooms_available between 0 and rooms_total),
  amenities text[] not null default '{}',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  latitude double precision not null,
  longitude double precision not null,
  created_at timestamptz not null default now(),
  owner_name text not null default 'Pemilik kos'
);

create table if not exists public.kos_rooms (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.kos_listings(id) on delete cascade,
  label text not null,
  monthly_price integer not null check (monthly_price >= 0),
  status text not null default 'available' check (status in ('available','occupied','maintenance')),
  daily_price integer check (daily_price is null or daily_price >= 0)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.kos_listings(id),
  customer_id uuid not null references public.profiles(id),
  move_in date not null,
  status text not null default 'pending' check (status in ('pending','accepted','rejected','cancelled','completed')),
  kind text not null default 'booking' check (kind in ('booking','survey')),
  note text not null default '',
  created_at timestamptz not null default now(),
  customer_name text not null default 'Pengguna',
  room_id uuid references public.kos_rooms(id) on delete set null
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text not null,
  sent_at timestamptz not null default now(),
  sender_name text not null default 'Pengguna'
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id),
  customer_id uuid not null references public.profiles(id),
  amount integer not null check (amount >= 0),
  due_at timestamptz not null,
  status text not null default 'unpaid' check (status in ('unpaid','paid','void')),
  created_at timestamptz not null default now(),
  listing_name text not null default 'Kos',
  late_fee integer not null default 0 check (late_fee >= 0),
  paid_amount integer not null default 0
);

create table if not exists public.favorites (
  customer_id uuid not null references public.profiles(id) on delete cascade,
  listing_id uuid not null references public.kos_listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (customer_id, listing_id)
);

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
    check (status in ('draft','submitted','approved','rejected')),
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

-- RLS is enabled on every exposed table. Add and test role-specific policies
-- before granting client access. Default-deny is intentional.
do $$ declare t text; begin
  foreach t in array array['profiles','kos_listings','kos_rooms','bookings','chat_messages','invoices','favorites','owner_expenses','kos_reviews','owner_verifications'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;


