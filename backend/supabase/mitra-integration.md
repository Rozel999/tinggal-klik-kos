# Kontrak Integrasi Aplikasi Mitra dengan Supabase Tinggal Klik Kos

Aplikasi Pencari Kos dan aplikasi Mitra harus menggunakan **satu Supabase project yang sama**. Supabase SDK menggunakan Auth dan REST API (`/rest/v1`) project tersebut. Jangan membuat project, tabel listing, atau ID listing baru di backend kedua.

## Konfigurasi aplikasi Mitra

Dari Supabase Dashboard → Project Settings → API, gunakan:

- `SUPABASE_URL`: Project URL yang sama dengan aplikasi Pencari Kos.
- `SUPABASE_PUBLISHABLE_KEY`: Publishable key project yang sama.
- `SUPABASE_SERVICE_ROLE_KEY`: jangan pernah dimasukkan ke aplikasi mobile atau dibagikan ke client.

Build Mitra menggunakan application ID Android yang berbeda dari `com.example.tinggal_klik_kos`, sehingga dua APK bisa dipasang berdampingan. ID aplikasi tidak mengubah database/API project.

## Role dan profil

Nilai `profiles.role` yang dipakai:

- `customer`: Pengguna aplikasi Pencari Kos.
- `admin`: Admin aplikasi Pencari Kos; dapat mengelola seluruh listing.
- `kos_owner`: Mitra pada aplikasi terpisah.

Saat signup di aplikasi Mitra, buat user Supabase Auth dengan metadata `display_name` dan `role: kos_owner`. Trigger `handle_new_auth_user` membuat baris `profiles`; `profiles.id` sama dengan `auth.users.id`. Jangan membuat UUID profil sendiri dan jangan memberi role melalui endpoint publik selain alur signup mitra.

Admin tidak boleh dipilih saat signup. Perubahan role admin dilakukan pengelola proyek lewat Supabase SQL Editor. Role lama `app_owner` dipindahkan ke `admin` oleh migration `004_two_apps_roles.sql`.

## Tabel dan aturan data

| Tabel | Pemakaian Mitra | Kolom kunci |
| --- | --- | --- |
| `kos_listings` | CRUD listing milik akun mitra; kirim sebagai `pending` untuk direview | `id`, `owner_id`, `owner_name`, `name`, `address`, `description`, `monthly_price`, `gender`, `rooms_total`, `rooms_available`, `amenities`, `status`, `latitude`, `longitude` |
| `kos_rooms` | CRUD unit kamar milik listing | `id`, `listing_id`, `label`, `monthly_price`, `status` |
| `bookings` | Baca dan tanggapi permintaan pada listing milik mitra | `id`, `listing_id`, `customer_id`, `move_in`, `status`, `kind`, `note`, `created_at` |
| `chat_messages` | Baca/kirim pesan untuk booking yang diikuti | `id`, `booking_id`, `sender_id`, `sender_name`, `body`, `sent_at` |
| `profiles` | Baca profil sendiri dan nama pelanggan yang memang dibutuhkan | `id`, `email`, `display_name`, `role`, `owner_verified` |

ID baru sebaiknya dibuat oleh default UUID database. Untuk listing baru, `owner_id` harus berasal dari `Supabase.instance.client.auth.currentUser!.id`, bukan dari text input atau ID hardcoded. `status` listing baru/hasil edit mitra adalah `pending`; Admin yang menyetujui atau menolak.

Status yang berlaku: listing `pending/approved/rejected`; kamar `available/occupied/maintenance`; booking `pending/accepted/rejected/cancelled/completed`; tipe booking `booking/survey`.

## RLS dan sinkronisasi

Migration `003_sync_security.sql` membuat trigger, kebijakan RLS, fungsi, dan pendaftaran Realtime. Migration `004_two_apps_roles.sql` menggabungkan `app_owner` menjadi `admin` dan membuat admin sebagai satu-satunya platform staff.

Dengan RLS:

- Pengguna umum hanya membaca listing `approved`.
- Mitra membaca/mengubah listing dan kamar yang `owner_id`-nya sama dengan ID sesi mereka.
- Mitra membaca booking/chat yang terkait ke listing/booking miliknya.
- Admin dapat mengelola semua listing.

Jangan memakai `select()` tanpa filter owner dengan asumsi client-side filter adalah pengaman. RLS database tetap sumber otorisasi; filter `.eq('owner_id', currentUser.id)` dapat ditambahkan untuk efisiensi dan kejelasan.

Agar perubahan di dua aplikasi terlihat tanpa tutup-buka, subscribe Realtime ke tabel yang dipakai setelah user login. Realtime tidak menggantikan baca REST awal; lakukan query awal lalu ikuti event perubahan.

## Urutan setup proyek

1. Di project Supabase yang sama, jalankan schema baru atau migration yang belum dijalankan secara berurutan.
2. Jalankan `003_sync_security.sql`, lalu `004_two_apps_roles.sql` di SQL Editor.
3. Pastikan tabel `kos_listings`, `kos_rooms`, `bookings`, `chat_messages`, dan `profiles` ada dan RLS aktif.
4. Daftarkan/login akun Mitra, pastikan profilnya `kos_owner`, lalu uji satu listing pending dan satu update kamar.
5. Uji dari Pencari Kos: listing pending tidak tampil untuk pencari, listing approved tampil, dan perubahan status kamar tercermin.

`004_two_apps_roles.sql` disiapkan di repository ini, tetapi harus dijalankan di Dashboard Supabase agar perubahan role berlaku pada project cloud.
