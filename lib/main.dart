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

  if (BackendConfig.mode != BackendMode.supabase ||
      !BackendConfig.isConfigured) {
    throw StateError(
        'Supabase belum dikonfigurasi. Jalankan dengan SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.');
  }
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
  );
  final auth = AuthProvider(repository: SupabaseAuthRepository());
  await auth.restoreSession();
  final data = KosDataProvider();
  await data.load();

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
      title: 'Tinggal Klik kos ku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
