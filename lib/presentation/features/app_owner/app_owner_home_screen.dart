import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class AppOwnerHomeScreen extends StatelessWidget {
  const AppOwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner aplikasi'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Halo, ${user?.name ?? 'Owner aplikasi'} 👋',
              style: const TextStyle(color: Color(0xFF5F6B73))),
          const SizedBox(height: 6),
          const Text('Kendali platform',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF314C82), Color(0xFF536FA8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                SizedBox(height: 14),
                Text('Owner aplikasi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text('Mengatur admin dan kebijakan seluruh platform.',
                    style: TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAEFFD),
                child: Icon(Icons.admin_panel_settings_rounded,
                    color: Color(0xFF435D92)),
              ),
              title: const Text('Pusat moderasi admin',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Tinjau listing dan ringkasan aktivitas.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
              onTap: () => context.go('/admin'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFEAEFFD),
                child: Icon(Icons.manage_accounts_rounded,
                    color: Color(0xFF435D92)),
              ),
              title: Text('Kelola admin',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  'Penambahan dan pengaturan admin akan memakai backend tepercaya.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFEAEFFD),
                child: Icon(Icons.settings_rounded, color: Color(0xFF435D92)),
              ),
              title: Text('Pengaturan platform',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Konfigurasi platform dan audit akses.'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Penetapan role Owner aplikasi dan Admin dilakukan melalui backend tepercaya, bukan formulir pendaftaran.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF5F6B73)),
          ),
        ],
      ),
    );
  }
}
