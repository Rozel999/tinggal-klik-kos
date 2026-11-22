import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Masukkan email akun terlebih dahulu.')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sent
            ? 'Jika email terdaftar, tautan reset akan dikirim ke kotak masuk.'
            : auth.error ?? 'Email reset belum dapat dikirim.')));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (success) {
      context.go(auth.user!.role.route);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error ?? 'Gagal masuk.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Kembali',
              onPressed: () => context.go('/onboarding'),
              icon: const Icon(Icons.arrow_back_rounded)),
          title: const Text('Masuk')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE3F1EC),
                            borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.waving_hand_rounded,
                            color: Color(0xFF087F73), size: 29)),
                    const SizedBox(height: 21),
                    const Text('Masuk dulu, yuk',
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    const Text(
                        'Simpan kos favorit dan ajukan sewa dengan mudah.',
                        style:
                            TextStyle(color: Color(0xFF687572), fontSize: 15)),
                    const SizedBox(height: 27),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded)),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Masukkan email yang valid.'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined))),
                        validator: (v) => v == null || v.length < 6
                            ? 'Minimal 6 karakter.'
                            : null),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: auth.isLoading ? null : _resetPassword,
                            child: const Text('Lupa kata sandi?'))),
                    const SizedBox(height: 7),
                    ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Masuk ke akun')),
                    const SizedBox(height: 24),
                    const SizedBox(height: 15),
                    Center(
                        child: TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text(
                                'Belum punya akun? Daftar sekarang'))),
                  ]),
            )),
      ))),
    );
  }
}
