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
    expect(find.text('Temukan kos yang pas\nuntuk langkah barumu'),
        findsOneWidget);
    expect(find.text('Masuk dan cari kos'), findsOneWidget);
  });

  testWidgets('role dashboards redirect unauthenticated visitors to login',
      (tester) async {
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
    expect(find.text('Masuk dulu, yuk'), findsOneWidget);
  });

  testWidgets('local owner can open the owner dashboard', (tester) async {
    final auth = AuthProvider();
    final signedIn = auth.signIn('owner@demo.id', 'owner123');
    await tester.pump(const Duration(milliseconds: 500));
    expect(await signedIn, isTrue);
    final router = createAppRouter(auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => KosDataProvider()..load()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Dashboard Pemilik'), findsOneWidget);
    expect(find.text('Properti saya'), findsOneWidget);
  });

  testWidgets('admin can open booking and account management tabs',
      (tester) async {
    final auth = AuthProvider();
    final signedIn = auth.signIn('admin@tinggalklik.id', 'admin123');
    await tester.pump(const Duration(milliseconds: 500));
    expect(await signedIn, isTrue);
    final router = createAppRouter(auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => KosDataProvider()..load()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Admin Platform'), findsOneWidget);
    final bookingsTab = find.byType(Tab).at(2);
    await tester.ensureVisible(bookingsTab);
    await tester.tap(bookingsTab);
    await tester.pumpAndSettle();
    expect(find.text('Booking dan tagihan'), findsOneWidget);

    final accountsTab = find.byType(Tab).at(3);
    await tester.ensureVisible(accountsTab);
    await tester.tap(accountsTab);
    await tester.pumpAndSettle();
    expect(find.text('3 akun terdaftar'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });
}
