# Pembagian role untuk dua aplikasi

Kedua aplikasi memakai proyek Supabase, tabel, Auth, dan REST API yang sama. Aplikasi Pencari Kos memiliki role `customer` (Pengguna) dan `admin`. Aplikasi Mitra Kos hanya menerima role `kos_owner` (Mitra/Pemilik Kos).

Role disimpan pada `public.profiles.role`. Pendaftaran aplikasi utama hanya menawarkan Pengguna. Pendaftaran aplikasi Mitra membuat profil `kos_owner`; kebijakan RLS tetap membatasi pemilik pada listing miliknya. `admin` hanya ditetapkan melalui SQL Editor oleh pengelola proyek, tidak dari formulir aplikasi.

Untuk menetapkan admin setelah akun pengguna dibuat dan profilnya tersedia:

```sql
update public.profiles set role = 'admin' where email = 'EMAIL_ADMIN';
```

Migration `004_two_apps_roles.sql` mengubah akun lama `app_owner` menjadi `admin`, lalu menghapus role `app_owner` dari constraint. Jalankan setelah migration 003. Jangan menyalin/menggandakan tabel ke aplikasi Mitra; kedua aplikasi mengakses Supabase yang sama memakai Supabase Auth dan REST API.
