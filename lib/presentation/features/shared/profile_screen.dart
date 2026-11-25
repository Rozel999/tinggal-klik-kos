import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: const Center(child: Text('Sesi login tidak ditemukan.')));
    }
    if (!_initialized) {
      _nameController.text = user.name;
      _initialized = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
                labelText: 'Nama', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 14),
          _info('Email', user.email, Icons.email_outlined),
          _info('Peran', user.role.label, Icons.badge_outlined),
          _info('ID akun', user.id, Icons.fingerprint_rounded),
          if (user.role == UserRole.kosOwner)
            _info(
                'Verifikasi Mitra',
                user.ownerVerified ? 'Terverifikasi' : 'Menunggu verifikasi',
                user.ownerVerified
                    ? Icons.verified_outlined
                    : Icons.pending_outlined),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: auth.isLoading ? null : () => _save(context, auth),
            icon: auth.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Simpan perubahan'),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value, IconData icon) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: SelectableText(value),
        ),
      );

  Future<void> _save(BuildContext context, AuthProvider auth) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama tidak boleh kosong.')));
      return;
    }
    final ok = await auth.updateDisplayName(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Profil berhasil diperbarui.'
            : auth.error ?? 'Profil gagal diperbarui.')));
  }
}
