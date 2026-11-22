import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/app_user.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/onboarding_screen.dart';
import '../../presentation/features/auth/register_screen.dart';
import '../../presentation/features/admin/admin_home_screen.dart';
import '../../presentation/features/customer/customer_home_screen.dart';
import '../../presentation/providers/auth_provider.dart';

GoRouter createAppRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/onboarding',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isPublic = location == '/onboarding' ||
            location == '/login' ||
            location == '/register';
        if (!auth.isAuthenticated && !isPublic) return '/login';
        if (auth.isAuthenticated && isPublic) return auth.user!.role.route;
        final role = auth.user?.role;
        if (role == null) return null;
        if (location.startsWith('/admin') && role != UserRole.admin) {
          return role.route;
        }
        if (location.startsWith('/owner') && role != UserRole.kosOwner) {
          return role.route;
        }
        if (location.startsWith('/customer') && role != UserRole.customer) {
          return role.route;
        }
        return null;
      },
      routes: [
        GoRoute(
            path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: '/customer', builder: (_, __) => const CustomerHomeScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
        GoRoute(
            path: '/owner',
            builder: (_, __) => const _PartnerAppRequiredScreen()),
      ],
    );

class _PartnerAppRequiredScreen extends StatelessWidget {
  const _PartnerAppRequiredScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Aplikasi Mitra Kos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.apartment_rounded, size: 54),
              const SizedBox(height: 16),
              const Text('Akun pemilik kos menggunakan aplikasi Mitra Kos.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  child: const Text('Keluar')),
            ]),
          ),
        ),
      );
}
