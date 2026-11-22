# Opsi database untuk Tinggal Klik Kos

Supabase sekarang menjadi jalur data aktif ketika VS Code Insiders menjalankan profil F5. Aplikasi memakai Supabase Auth untuk login/daftar, Postgres untuk seluruh tabel kos, kamar, booking, chat, favorit, dan tagihan, serta Realtime untuk pembaruan lintas perangkat.

## Supabase

1. Pastikan file lokal `backend/supabase.local.json` berisi URL proyek dan publishable key.
2. Di SQL Editor Supabase, jalankan `backend/supabase/migrations/002_roles.sql` bila skema tiga role lama sudah pernah dibuat, lalu jalankan `backend/supabase/migrations/003_sync_security.sql`.
3. Buat akun Owner aplikasi dan Admin dengan panduan `backend/supabase/roles-setup.md`. Role istimewa tidak dapat dipilih dari formulir pendaftaran.
4. Jalankan aplikasi lewat F5 di VS Code Insiders. Registrasi dan perubahan data akan tersimpan ke Supabase; tabel baru perlu mendapat policy/RLS dan realtime publication dari migrasi.

```powershell
flutter run --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
flutter build apk --release --dart-define=APP_BACKEND=supabase --dart-define-from-file=backend/supabase.local.json
```

Gunakan hanya publishable key di aplikasi. Jangan masukkan Supabase secret/service-role key.

## MySQL

Profil MySQL tetap opsi cadangan. Untuk aplikasi HP, Flutter harus menggunakan REST API di server; MySQL hanya menerima koneksi dari API. Server/API MySQL belum dibuat atau dihubungkan.

```powershell
flutter run --dart-define=APP_BACKEND=mysql --dart-define=MYSQL_API_BASE_URL=https://api.example.com
```

Skema awal MySQL: `backend/mysql/schema.sql`.

**Penting:** proses sync Supabase aktif setelah migrasi RLS dijalankan. Data demo lokal tidak otomatis disalin ke Supabase, untuk menghindari mengunggah listing dan akun contoh sebagai data nyata. Pembayaran tetap simulasi dan penandaan “lunas” adalah status demo, bukan konfirmasi transfer sungguhan.
