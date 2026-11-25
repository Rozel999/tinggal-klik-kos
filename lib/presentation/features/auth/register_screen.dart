import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.mitraApp = false, super.key});
  final bool mitraApp;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.customer;

  @override
  void initState() {
    super.initState();
    if (widget.mitraApp) _role = UserRole.kosOwner;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    if (ok) {
      context.go(auth.user!.role.route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Pendaftaran gagal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.home_work_rounded,
                          color: Colors.white, size: 22)),
                  const SizedBox(width: 11),
                  const Text('Tinggal Klik Kos',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const SizedBox(height: 25),
                Text(
                    widget.mitraApp
                        ? 'Daftar akun mitra'
                        : 'Daftar akun pengguna',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().length < 3
                      ? 'Nama terlalu singkat.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email tidak valid.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Kata sandi (minimal 6 karakter)',
                      prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimal 6 karakter.' : null,
                ),
                const SizedBox(height: 18),
                Text(
                    widget.mitraApp
                        ? 'Role: Mitra Pemilik Kos'
                        : 'Role: Pengguna',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (widget.mitraApp) ...[
                  const SizedBox(height: 12),
                  const Text(
                      'Listing yang dikirim akan menunggu pemeriksaan admin.',
                      style: TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Daftar Sekarang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
