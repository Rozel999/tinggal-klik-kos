import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/onboarding_screen.dart';
import '../../presentation/features/auth/register_screen.dart';
import '../../presentation/features/auth/splash_intro_screen.dart';
import '../../presentation/features/admin/admin_home_screen.dart';
import '../../presentation/features/customer/customer_home_screen.dart';
import '../../presentation/features/owner/owner_home_screen.dart';
import '../../presentation/providers/auth_provider.dart';

GoRouter createAppRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isSplash = location == '/splash';
        final isPublic = location == '/onboarding' ||
            location == '/login' ||
            location == '/register' ||
            isSplash;
        if (!auth.isAuthenticated && !isPublic) return '/login';
        if (auth.isAuthenticated && isPublic && !isSplash) {
          return auth.user!.role.route;
        }
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
        GoRoute(path: '/splash', builder: (_, __) => const SplashIntroScreen()),
        GoRoute(
            path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: '/customer', builder: (_, __) => const CustomerHomeScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
        GoRoute(path: '/owner', builder: (_, __) => const OwnerHomeScreen()),
      ],
    );
