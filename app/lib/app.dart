import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/notifiers/user_profile_notifier.dart';
import 'core/theme/app_theme.dart';
import 'data/models/clothing_item.dart';
import 'data/models/outfit.dart';
import 'data/services/auth/auth_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/wardrobe/wardrobe_screen.dart';
import 'presentation/wardrobe/add_item_screen.dart';
import 'presentation/wardrobe/item_detail_screen.dart';
import 'presentation/wardrobe/mass_capture/mass_tutorial_screen.dart';
import 'presentation/wardrobe/mass_capture/mass_camera_screen.dart';
import 'presentation/wardrobe/mass_capture/mass_review_screen.dart';
import 'presentation/suggest/suggest_screen.dart';
import 'presentation/suggest/outfit_detail_screen.dart';
import 'presentation/saved/saved_screen.dart';
import 'presentation/history/history_screen.dart';
import 'presentation/account/account_screen.dart';
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
  refreshListenable: sl<UserProfileNotifier>(),
  redirect: (context, state) {
    final authService = sl<AuthService>();
    final profileNotifier = sl<UserProfileNotifier>();
    final isAuthenticated = authService.currentUser != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == AppConstants.routeLogin ||
        loc == AppConstants.routeRegister ||
        loc == AppConstants.routeSplash;
    final isOnboardingRoute = loc == AppConstants.routeOnboarding;

    if (!isAuthenticated && !isAuthRoute) return AppConstants.routeLogin;

    if (isAuthenticated && isAuthRoute) {
      if (profileNotifier.onboardingComplete == false) {
        return AppConstants.routeOnboarding;
      }
      return AppConstants.routeWardrobe;
    }

    // Redirect to onboarding if profile loaded and not yet complete
    if (isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
      if (profileNotifier.onboardingComplete == false) {
        return AppConstants.routeOnboarding;
      }
    }

    // Block re-visiting onboarding once complete
    if (isAuthenticated && isOnboardingRoute &&
        profileNotifier.onboardingComplete == true) {
      return AppConstants.routeWardrobe;
    }

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
      path: AppConstants.routeOnboarding,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final fromAccount = extra?['fromAccount'] as bool? ?? false;
        return OnboardingScreen(fromAccount: fromAccount);
      },
    ),
    GoRoute(
      path: AppConstants.routeAddItem,
      builder: (context, state) => const AddItemScreen(),
    ),
    GoRoute(
      path: AppConstants.routeItemDetail,
      builder: (context, state) {
        final item = state.extra as ClothingItem;
        return ItemDetailScreen(item: item);
      },
    ),
    GoRoute(
      path: AppConstants.routeOutfitDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OutfitDetailScreen(
          outfit: extra['outfit'] as Outfit,
          wardrobeItems: extra['wardrobeItems'] as List<ClothingItem>,
        );
      },
    ),
    GoRoute(
      path: AppConstants.routeHistory,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppConstants.routeMassTutorial,
      builder: (context, state) => const MassTutorialScreen(),
    ),
    GoRoute(
      path: AppConstants.routeMassCamera,
      builder: (context, state) => const MassCameraScreen(),
    ),
    GoRoute(
      path: AppConstants.routeMassReview,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MassReviewScreen(sessionId: extra['sessionId'] as String);
      },
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
              path: AppConstants.routeAccount,
              builder: (context, state) => const AccountScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
