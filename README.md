# Tinggal Klik Kos

Aplikasi Flutter untuk pencarian dan pengelolaan kos di Kota Padang, Sumatera Barat. Aplikasi menggunakan Supabase sebagai backend dan tidak menyediakan mode login/data demo.

## Status tahap

Fitur aplikasi terhubung ke Supabase:

- [x] Tahap 1: fondasi, tema Material 3, routing, autentikasi Supabase, dan pembatasan layar berdasarkan peran.
- [x] Tahap 2: pencarian, filter tipe/harga/fasilitas, peta kos dengan GPS perangkat, detail, dan favorit tersimpan.
- [x] Tahap 3: dashboard pemilik, CRUD properti dan unit kamar, status ketersediaan, serta antrean booking.
- [x] Tahap 4: booking kamar, permintaan survei, status persetujuan, dan chat per booking.
- [x] Tahap 5: tagihan awal otomatis saat booking diterima, pengingat di aplikasi, dan simulasi pembayaran.
- [x] Tahap 6: dashboard admin, moderasi listing, booking/tagihan, daftar akun, dan ringkasan.
- [x] Tahap 7: validasi form, penyimpanan lokal, pengujian alur data, dan polishing UI.

## Menjalankan

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8086
```

Buka alamat lokal yang dicetak Flutter. Ganti port jika 8086 sedang dipakai. Untuk menjalankan di Android, sambungkan perangkat atau mulai emulator lalu jalankan `flutter run`.

Fitur GPS meminta izin lokasi saat tombol **Lokasi saya** atau **Gunakan lokasi perangkat** ditekan. Di web, lokasi perlu HTTPS atau localhost.

Login Google memerlukan provider Google aktif di Supabase Authentication dan redirect `io.supabase.tinggalklik://login-callback/` pada daftar URL yang diizinkan. Tambahkan juga URL web lokal/produksi yang digunakan aplikasi.

## Peran aplikasi

- **Owner aplikasi**: superadmin; mengatur admin dan kebijakan platform.
- **Admin**: mengelola moderasi listing dan aktivitas.
- **Pemilik Kos**: mendaftarkan serta mengelola kos miliknya.
- **Pengguna**: mencari dan memesan kos.

Owner aplikasi dan Admin tidak dapat dipilih pada formulir pendaftaran.

## Aplikasi Tinggal Klik Kos dan Supabase

Konfigurasi Supabase dibutuhkan untuk menjalankan aplikasi. File `backend/supabase.local.json` sudah disiapkan secara lokal di workspace ini dan tidak dimasukkan ke Git.

```powershell
flutter run -t lib/main.dart --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
```

Di VS Code pilih konfigurasi **Tinggal Klik Kos (Supabase)** lalu tekan F5. Jangan menjalankan konfigurasi `local`; aplikasi akan berhenti dengan pesan jelas jika Supabase belum dikonfigurasi.

## Kerja bareng lewat GitHub

Setiap orang mengerjakan salinan repository di perangkat masing-masing. Jangan mengedit satu folder yang disinkronkan OneDrive/Google Drive secara bersamaan karena perubahan bisa saling menimpa.

1. Buat repository GitHub lalu push project ini.
2. Rekan meng-clone repository, lalu jalankan `flutter pub get`.
3. Masing-masing salin `backend/supabase.local.example.json` menjadi `backend/supabase.local.json`, lalu isi URL dan publishable key dari proyek Supabase bersama. File lokal itu diabaikan Git.
4. Sebelum mulai: `git pull`. Setelah perubahan selesai: commit dan `git push`.
5. Kerjakan fitur pada branch berbeda atau bagi file/fitur agar konflik lebih sedikit. Jangan commit `service_role` key, password, signing key Android, `backend/supabase.local.json`, atau file `.env`.

Contoh perintah dari PowerShell:

```powershell
git clone https://github.com/USERNAME/NAMA-REPOSITORY.git
cd NAMA-REPOSITORY
flutter pub get
Copy-Item backend/supabase.local.example.json backend/supabase.local.json
```
## Migrasi Supabase dan role

Untuk database yang sudah menjalankan migration 003, jalankan `backend/supabase/migrations/004_booking_occupies_room.sql`, `backend/supabase/migrations/004_two_apps_roles.sql`, `backend/supabase/migrations/005_admin_moderation_only.sql`, `backend/supabase/migrations/006_admin_owner_verification.sql`, `backend/supabase/migrations/007_customer_reviews.sql`, `backend/supabase/migrations/008_shared_schema_expenses.sql`, `backend/supabase/migrations/009_owner_verification_submissions.sql`, dan `backend/supabase/migrations/010_repair_reviews_and_chat_retention.sql` di Supabase SQL Editor. Migration 009 menambahkan antrean verifikasi Mitra, dokumen privat, persetujuan Admin, dan pembatasan listing sampai Mitra disetujui. Migration 010 memastikan tabel ulasan ada, memuat ulang cache PostgREST, dan menghapus pesan chat yang berumur lebih dari 24 jam tiap 6 jam (pg_cron harus tersedia di project Supabase).

Untuk database baru, jalankan `backend/supabase/schema.sql`, lalu migration `003_sync_security.sql`, kedua migration `004_*.sql`, dan migration `005` sampai `010` secara berurutan. Admin hanya dapat meninjau Mitra yang sudah mengirim data dan kedua dokumen; persetujuan membuka akses Mitra untuk mengirim listing. Pembuatan dan pengubahan isi listing tetap dilakukan dari aplikasi Mitra dengan project Supabase yang sama.

Untuk memeriksa instalasi database cloud setelah migrasi, jalankan `backend/supabase/verify_required_schema.sql` di SQL Editor. Semua tabel dan RPC yang ditampilkan harus berstatus ada; bucket dokumen harus privat dan job pembersihan chat harus aktif.
## Pemeriksaan

```powershell
flutter analyze
flutter test
```




## Tes di HP Android

APK debug terbaru dibuat di `build/app/outputs/flutter-apk/app-debug.apk` (sekitar 162 MB / 155 MiB). Kirim file itu ke HP, buka dari File Manager, lalu izinkan instalasi dari sumber tersebut jika Android meminta. Untuk menjalankan langsung dari VS Code, buka folder proyek dengan VS Code Insiders, sambungkan HP dengan kabel data, aktifkan Opsi Pengembang dan USB debugging, setujui dialog izin di HP, lalu pilih perangkat Android di status bar dan tekan `F5`. Verifikasi perangkat lewat `flutter devices`.

Konfigurasi workspace di `.vscode/settings.json` menunjuk Flutter SDK `C:\\src\\flutter` dan JDK bawaan Android Studio; `.vscode/launch.json` menyediakan konfigurasi debug Flutter.






