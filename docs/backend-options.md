# Opsi database untuk Tinggal Klik Kos

Supabase adalah satu-satunya backend aplikasi. Tidak ada fallback ke akun atau data demo. Aplikasi berhenti dengan pesan konfigurasi jika Supabase belum disiapkan.

## Supabase

1. Pastikan file lokal `backend/supabase.local.json` berisi URL proyek dan publishable key.
2. Di SQL Editor Supabase, jalankan migrasi sesuai README, termasuk `003_sync_security.sql`, kedua file migrasi `004`, serta migration `005` sampai `010` berurutan. Migration 010 memperbaiki tabel ulasan yang hilang dan memasang pembersihan chat 24 jam yang berjalan setiap 6 jam lewat pg_cron.
3. Buat akun Admin dengan panduan `backend/supabase/roles-setup.md`. Role istimewa tidak dapat dipilih dari formulir pendaftaran.
4. Jalankan aplikasi dengan perintah Supabase di bawah. Registrasi dan perubahan data akan tersimpan ke Supabase setelah migration policy/RLS diterapkan.

```powershell
flutter run --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
flutter build apk --release --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
```

Gunakan hanya publishable key di aplikasi. Jangan masukkan Supabase secret/service-role key.

Login Google menggunakan Supabase OAuth. Aktifkan Google pada Authentication → Providers, lalu masukkan `io.supabase.tinggalklik://login-callback/` ke daftar redirect URL. Untuk web, izinkan URL lokal dan domain produksi yang digunakan.

## MySQL

MySQL belum didukung oleh aplikasi. Untuk aplikasi HP, koneksi MySQL perlu melalui REST API; API tersebut belum dibuat atau dihubungkan. Mode `APP_BACKEND=mysql` saat ini menampilkan pesan bahwa backend belum tersedia.

Skema awal MySQL: `backend/mysql/schema.sql`.

**Penting:** proses sync Supabase aktif setelah migrasi RLS dijalankan. Pembayaran tetap simulasi dan penandaan “lunas” bukan konfirmasi transfer sungguhan.
