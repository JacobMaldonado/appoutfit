import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth/auth_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/wardrobe/wardrobe_screen.dart';
import 'presentation/wardrobe/add_item_screen.dart';
import 'presentation/suggest/suggest_screen.dart';
import 'presentation/saved/saved_screen.dart';
import 'presentation/history/history_screen.dart';
import 'presentation/shared/widgets/scaffold_with_bottom_nav.dart';

class ClosetApp extends StatelessWidget {
  const ClosetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Clo·set',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _router = GoRouter(
  initialLocation: AppConstants.routeSplash,
  redirect: (context, state) {
    final authService = sl<AuthService>();
    final isAuthenticated = authService.currentUser != null;
    final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
        state.matchedLocation == AppConstants.routeRegister ||
        state.matchedLocation == AppConstants.routeSplash;

    if (!isAuthenticated && !isAuthRoute) return AppConstants.routeLogin;
    if (isAuthenticated && isAuthRoute) return AppConstants.routeWardrobe;
    return null;
  },
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAddItem,
      builder: (context, state) => const AddItemScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithBottomNav(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.routeWardrobe,
              builder: (context, state) => const WardrobeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.routeSuggest,
              builder: (context, state) => const SuggestScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.routeSaved,
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.routeHistory,
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
