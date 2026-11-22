import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinggal_klik_kos/core/router/app_router.dart';
import 'package:tinggal_klik_kos/main.dart';
import 'package:tinggal_klik_kos/presentation/providers/auth_provider.dart';
import 'package:tinggal_klik_kos/presentation/providers/kos_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app opens the onboarding screen', (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KosDataProvider()..load()),
      ],
      child: const TinggalKlikApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cari kos nyaman,\ntinggal klik!'), findsOneWidget);
    expect(find.text('Mulai Jelajahi'), findsOneWidget);
  });

  testWidgets('role dashboards redirect unauthenticated visitors to login', (tester) async {
    final auth = AuthProvider();
    final router = createAppRouter(auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => KosDataProvider()..load()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    router.go('/admin');
    await tester.pumpAndSettle();
    expect(find.text('Senang melihatmu lagi!'), findsOneWidget);
  });
}
