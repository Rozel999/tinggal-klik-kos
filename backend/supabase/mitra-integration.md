# Kontrak Integrasi Aplikasi Mitra dengan Supabase Tinggal Klik Kos

Aplikasi Pencari Kos dan aplikasi Mitra harus menggunakan **satu Supabase project yang sama**. Supabase SDK menggunakan Auth dan REST API (`/rest/v1`) project tersebut. Jangan membuat project, tabel listing, atau ID listing baru di backend kedua.

## Konfigurasi aplikasi Mitra

Dari Supabase Dashboard → Project Settings → API, gunakan:

- `SUPABASE_URL`: Project URL yang sama dengan aplikasi Tinggal Klik Kos.
- `SUPABASE_PUBLISHABLE_KEY`: Publishable key project yang sama.
- `SUPABASE_SERVICE_ROLE_KEY`: jangan pernah dimasukkan ke aplikasi mobile atau dibagikan ke client.

Build Mitra menggunakan application ID Android yang berbeda dari `com.example.tinggal_klik_kos`, sehingga dua APK bisa dipasang berdampingan. ID aplikasi tidak mengubah database/API project.

## Role dan profil

Nilai `profiles.role` yang dipakai:

- `customer`: Pengguna aplikasi Tinggal Klik Kos.
- `admin`: Admin aplikasi Tinggal Klik Kos; dapat membaca listing dan mengubah status moderasi. Input, edit data, dan penghapusan listing dilakukan dari aplikasi Mitra.
- `kos_owner`: Mitra pada aplikasi terpisah.

Saat signup di aplikasi Mitra, buat user Supabase Auth dengan metadata `display_name` dan `role: kos_owner`. Trigger `handle_new_auth_user` membuat baris `profiles`; `profiles.id` sama dengan `auth.users.id`. Jangan membuat UUID profil sendiri dan jangan memberi role melalui endpoint publik selain alur signup mitra.

Admin tidak boleh dipilih saat signup. Perubahan role admin dilakukan pengelola proyek lewat Supabase SQL Editor. Role lama `app_owner` dipindahkan ke `admin` oleh migration `004_two_apps_roles.sql`.

## Tabel dan aturan data

| Tabel | Pemakaian Mitra | Kolom kunci |
| --- | --- | --- |
| `kos_listings` | CRUD listing milik akun mitra; kirim sebagai `pending` untuk direview | `id`, `owner_id`, `owner_name`, `name`, `address`, `description`, `monthly_price`, `gender`, `rooms_total`, `rooms_available`, `amenities`, `status`, `latitude`, `longitude` |
| `kos_rooms` | CRUD unit kamar milik listing | `id`, `listing_id`, `label`, `monthly_price`, `daily_price` (opsional), `status` |
| `bookings` | Baca dan tanggapi permintaan pada listing milik mitra | `id`, `listing_id`, `customer_id`, `move_in`, `status`, `kind`, `note`, `created_at` |
| `chat_messages` | Baca/kirim pesan untuk booking yang diikuti | `id`, `booking_id`, `sender_id`, `sender_name`, `body`, `sent_at` |
| `profiles` | Baca profil sendiri dan nama pelanggan yang memang dibutuhkan | `id`, `email`, `display_name`, `role`, `owner_verified` |
| `owner_verifications` | Simpan data legal/rekening dan status pengajuan Mitra | `owner_id`, `legal_name`, `phone`, `bank_name`, `account_holder`, `account_number`, `ktp_object_path`, `selfie_object_path`, `status`, `review_note` |
| `invoices` | Baca tagihan penyewa terkait; status pembayaran demo diperbarui lewat RPC aman | `amount`, `late_fee`, `paid_amount`, `status`, `due_at` |
| `owner_expenses` | CRUD biaya operasional untuk kos miliknya | `listing_id`, `description`, `amount`, `spent_on` |

## Alur verifikasi Mitra

1. Setelah akun `kos_owner` dibuat, database otomatis menyiapkan baris `owner_verifications` dengan status `draft`.
2. Aplikasi Mitra mengisi nama legal, nomor telepon, nama bank, nama pemilik rekening, dan nomor rekening pada baris milik akun tersebut.
3. Unggah KTP dan selfie ke bucket Storage **private** `owner-verification-docs` dengan nama `<auth.uid()>/ktp.jpg` dan `<auth.uid()>/selfie.jpg` (ekstensi jpg/jpeg/png/webp). Simpan object path tersebut ke `ktp_object_path` dan `selfie_object_path`.
4. Setelah data dan kedua file tersedia, panggil RPC `submit_owner_verification()` tanpa parameter. RPC menolak pengajuan yang belum lengkap dan mengubah status menjadi `submitted`.
5. Admin hanya melihat status `submitted` pada antrean verifikasi aplikasi Tinggal Klik Kos. Admin dapat membaca dokumen dengan signed URL sementara, lalu memanggil `admin_review_owner_verification(p_owner_id, p_approved, p_note)`.
6. Hasil tinjauan tersimpan sebagai `approved` atau `rejected`; alasan penolakan tersimpan di `review_note`. Penolakan mengembalikan data ke keadaan yang bisa diedit dan dikirim ulang. Persetujuan mengatur `profiles.owner_verified = true`, yang menjadi syarat database untuk membuat atau mengubah listing.

Jangan ubah `status`, `reviewed_by`, `reviewed_at`, `review_note`, atau `profiles.owner_verified` secara langsung dari aplikasi Mitra. Jangan jadikan bucket dokumen publik atau gunakan service-role key di aplikasi.

ID baru sebaiknya dibuat oleh default UUID database. Untuk listing baru, `owner_id` harus berasal dari `Supabase.instance.client.auth.currentUser!.id`, bukan dari text input atau ID hardcoded. `status` listing baru/hasil edit mitra adalah `pending`; Admin yang menyetujui atau menolak.

Status yang berlaku: listing `pending/approved/rejected`; kamar `available/occupied/maintenance`; booking `pending/accepted/rejected/cancelled/completed`; tipe booking `booking/survey`.

## RLS dan sinkronisasi

Migration `003_sync_security.sql` membuat trigger, kebijakan RLS, fungsi, dan pendaftaran Realtime. Migration `004_two_apps_roles.sql` menggabungkan `app_owner` menjadi `admin` dan membuat admin sebagai satu-satunya platform staff.

Dengan RLS:

- Pengguna umum hanya membaca listing `approved`.
- Mitra membaca/mengubah listing dan kamar yang `owner_id`-nya sama dengan ID sesi mereka.
- Mitra membaca booking/chat yang terkait ke listing/booking miliknya.
- Admin dapat membaca semua listing dan menyetujui/menolak listing. Admin tidak membuat, mengedit isi, atau menghapus listing dari aplikasi Tinggal Klik Kos.
- Biaya operasional hanya dapat dibaca dan dikelola Mitra pemilik listing terkait; Admin boleh membaca semua biaya untuk pengawasan.

Jangan memakai `select()` tanpa filter owner dengan asumsi client-side filter adalah pengaman. RLS database tetap sumber otorisasi; filter `.eq('owner_id', currentUser.id)` dapat ditambahkan untuk efisiensi dan kejelasan.

Agar perubahan di dua aplikasi terlihat tanpa tutup-buka, subscribe Realtime ke tabel yang dipakai setelah user login. Realtime tidak menggantikan baca REST awal; lakukan query awal lalu ikuti event perubahan. Migration `010_repair_reviews_and_chat_retention.sql` mempertahankan pesan chat selama 24 jam dan membersihkan pesan lama tiap 6 jam menggunakan pg_cron; beri tahu pengguna bahwa riwayat chat akan terhapus otomatis.

## Urutan setup proyek

1. Di project Supabase yang sama, jalankan schema baru atau migration yang belum dijalankan secara berurutan.
2. Jalankan `003_sync_security.sql`, lalu `004_two_apps_roles.sql` di SQL Editor.
3. Pastikan tabel `kos_listings`, `kos_rooms`, `bookings`, `chat_messages`, `profiles`, `invoices`, `owner_expenses`, `kos_reviews`, dan `owner_verifications` ada dan RLS aktif. Jalankan migrations `006_admin_owner_verification.sql`, `007_customer_reviews.sql`, `008_shared_schema_expenses.sql`, `009_owner_verification_submissions.sql`, dan `010_repair_reviews_and_chat_retention.sql`.
4. Daftarkan/login akun Mitra, pastikan profilnya `kos_owner`, lalu uji satu listing pending dan satu update kamar.
5. Uji dari Tinggal Klik Kos: listing pending tidak tampil untuk pencari, listing approved tampil, dan perubahan status kamar tercermin.

`004_two_apps_roles.sql` disiapkan di repository ini, tetapi harus dijalankan di Dashboard Supabase agar perubahan role berlaku pada project cloud.
