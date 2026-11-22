-- Initial data model for MySQL 8.0+. Connect to this DB only from a trusted API.
create database if not exists tinggal_klik_kos
  character set utf8mb4 collate utf8mb4_0900_ai_ci;
use tinggal_klik_kos;

create table if not exists profiles (
  id char(36) primary key,
  display_name varchar(120) not null,
  email varchar(254) not null unique,
  password_hash varchar(255) not null,
  role enum('customer','kos_owner','admin','app_owner') not null,
  owner_verified boolean not null default false,
  created_at timestamp not null default current_timestamp
) engine=InnoDB;

create table if not exists kos_listings (
  id char(36) primary key,
  owner_id char(36) not null,
  name varchar(180) not null,
  address varchar(500) not null,
  description text not null,
  monthly_price int unsigned not null,
  gender varchar(30) not null,
  rooms_total int unsigned not null default 0,
  rooms_available int unsigned not null default 0,
  amenities json not null,
  status enum('pending','approved','rejected') not null default 'pending',
  latitude double not null,
  longitude double not null,
  created_at timestamp not null default current_timestamp,
  constraint fk_listing_owner foreign key (owner_id) references profiles(id),
  constraint chk_listing_rooms check (rooms_available <= rooms_total),
  index idx_listing_status_price (status, monthly_price)
) engine=InnoDB;

create table if not exists kos_rooms (
  id char(36) primary key,
  listing_id char(36) not null,
  label varchar(80) not null,
  monthly_price int unsigned not null,
  status enum('available','occupied','maintenance') not null default 'available',
  constraint fk_room_listing foreign key (listing_id) references kos_listings(id) on delete cascade
) engine=InnoDB;

create table if not exists bookings (
  id char(36) primary key,
  listing_id char(36) not null,
  customer_id char(36) not null,
  move_in date not null,
  status enum('pending','accepted','rejected','cancelled','completed') not null default 'pending',
  kind enum('booking','survey') not null default 'booking',
  note text not null,
  created_at timestamp not null default current_timestamp,
  constraint fk_booking_listing foreign key (listing_id) references kos_listings(id),
  constraint fk_booking_customer foreign key (customer_id) references profiles(id),
  index idx_booking_listing_status (listing_id, status)
) engine=InnoDB;

create table if not exists chat_messages (
  id char(36) primary key,
  booking_id char(36) not null,
  sender_id char(36) not null,
  body text not null,
  sent_at timestamp not null default current_timestamp,
  constraint fk_message_booking foreign key (booking_id) references bookings(id) on delete cascade,
  constraint fk_message_sender foreign key (sender_id) references profiles(id)
) engine=InnoDB;

create table if not exists invoices (
  id char(36) primary key,
  booking_id char(36) not null unique,
  customer_id char(36) not null,
  amount int unsigned not null,
  due_at timestamp not null,
  status enum('unpaid','paid','void') not null default 'unpaid',
  created_at timestamp not null default current_timestamp,
  constraint fk_invoice_booking foreign key (booking_id) references bookings(id),
  constraint fk_invoice_customer foreign key (customer_id) references profiles(id)
) engine=InnoDB;

create table if not exists favorites (
  customer_id char(36) not null,
  listing_id char(36) not null,
  created_at timestamp not null default current_timestamp,
  primary key (customer_id, listing_id),
  constraint fk_fav_customer foreign key (customer_id) references profiles(id) on delete cascade,
  constraint fk_fav_listing foreign key (listing_id) references kos_listings(id) on delete cascade
) engine=InnoDB;

