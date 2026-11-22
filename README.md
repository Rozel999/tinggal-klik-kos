# Tinggal Klik kos ku

Aplikasi demo Flutter untuk pencarian dan pengelolaan kos di Kota Padang, Sumatera Barat.

## Status tahap

Seluruh tahap 2â€“7 sudah tersambung dalam mode demo lokal:

- [x] Tahap 1: fondasi, tema Material 3, routing, akun demo, dan pembatasan layar berdasarkan peran.
- [x] Tahap 2: pencarian, filter tipe/harga/fasilitas, peta ilustratif, detail, dan favorit tersimpan.
- [x] Tahap 3: dashboard pemilik, CRUD properti dan unit kamar, status ketersediaan, serta antrean booking.
- [x] Tahap 4: booking kamar, permintaan survei, status persetujuan, dan chat per booking.
- [x] Tahap 5: tagihan awal otomatis saat booking diterima, pengingat di aplikasi, dan simulasi pembayaran.
- [x] Tahap 6: dashboard admin, moderasi listing, dan ringkasan akun demo.
- [x] Tahap 7: validasi form, penyimpanan lokal, pengujian alur data, dan polishing UI.

## Menjalankan

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8086
```

Buka alamat lokal yang dicetak Flutter. Ganti port jika 8086 sedang dipakai. Untuk menjalankan di Android, sambungkan perangkat atau mulai emulator lalu jalankan `flutter run`.

## Peran aplikasi

- **Owner aplikasi**: superadmin; mengatur admin dan kebijakan platform.
- **Admin**: mengelola moderasi listing dan aktivitas.
- **Pemilik Kos**: mendaftarkan serta mengelola kos miliknya.
- **Pengguna**: mencari dan memesan kos.

Owner aplikasi dan Admin tidak dapat dipilih pada formulir pendaftaran.

## APK Pencari Kos dan Supabase

Aplikasi dalam repository ini hanya APK Pencari Kos dengan role Pengguna (`customer`) dan Admin. Aplikasi Mitra dibuat terpisah; rekan Anda dapat menghubungkannya ke proyek Supabase yang sama memakai URL proyek dan publishable key. Tabel listing, kamar, booking, profil, chat, invoice, serta favorit tetap satu sumber di Supabase.

Aplikasi utama tidak menggunakan backend demo. Jalankan dengan konfigurasi Supabase:

```powershell
flutter run -t lib/main.dart --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
```

VS Code memiliki satu konfigurasi F5, **Pencari Kos (Supabase)**. Jika konfigurasi Supabase tidak tersedia, aplikasi berhenti dengan pesan konfigurasi; data demo tidak dimuat.

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

Untuk database yang sudah menjalankan migration 003, jalankan `backend/supabase/migrations/004_two_apps_roles.sql` di Supabase SQL Editor. Migration memindahkan akun lama `app_owner` ke `admin`, memperbarui constraint role, dan membatasi fungsi staff pada Admin.

Untuk database baru, jalankan `backend/supabase/schema.sql`, lalu migration 003 dan 004. Role admin hanya diberikan dari backend/Supabase SQL Editor. Pendaftaran di aplikasi utama hanya membuat Pengguna; pendaftaran aplikasi Mitra membuat role `kos_owner`. RLS membatasi mitra ke listing miliknya dan Admin dapat mengelola semua listing.
## Pemeriksaan

```powershell
flutter analyze
flutter test
```




## Tes di HP Android

APK debug terbaru dibuat di `build/app/outputs/flutter-apk/app-debug.apk` (sekitar 162 MB / 155 MiB). Kirim file itu ke HP, buka dari File Manager, lalu izinkan instalasi dari sumber tersebut jika Android meminta. Untuk menjalankan langsung dari VS Code, buka folder proyek dengan VS Code Insiders, sambungkan HP dengan kabel data, aktifkan Opsi Pengembang dan USB debugging, setujui dialog izin di HP, lalu pilih perangkat Android di status bar dan tekan `F5`. Verifikasi perangkat lewat `flutter devices`.

Konfigurasi workspace di `.vscode/settings.json` menunjuk Flutter SDK `C:\\src\\flutter` dan JDK bawaan Android Studio; `.vscode/launch.json` menyediakan konfigurasi debug Flutter.






