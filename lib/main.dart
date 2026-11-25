import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/backend_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/supabase_auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/kos_data_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfig.mode != BackendMode.supabase) {
    throw StateError(
        'Aplikasi ini harus dijalankan dengan Supabase. Pilih konfigurasi VS Code "Tinggal Klik Kos (Supabase)" atau gunakan perintah di README.');
  }
  if (!BackendConfig.isConfigured) {
    throw StateError(
        'Supabase belum terkonfigurasi. Jalankan menggunakan --dart-define-from-file=backend/supabase.local.json.');
  }
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
  );
  final auth = AuthProvider(repository: SupabaseAuthRepository());
  await auth.restoreSession();
  final data = KosDataProvider();
  unawaited(data.load());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: data),
      ],
      child: const TinggalKlikApp(),
    ),
  );
}

class TinggalKlikApp extends StatelessWidget {
  const TinggalKlikApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(context.read<AuthProvider>());
    return MaterialApp.router(
      title: 'Tinggal Klik Kos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
