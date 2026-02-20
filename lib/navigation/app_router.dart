import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../screens/shell_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/calibration_screen.dart';
import '../screens/add_bill_screen.dart';
import '../screens/split_friends_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/pool_detail_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/create_pool_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter? _cachedRouter;
AppProvider? _cachedProvider;

GoRouter createRouter(AppProvider provider) {
  // Return cached router if provider hasn't changed
  if (_cachedRouter != null && _cachedProvider == provider) {
    return _cachedRouter!;
  }
  _cachedProvider = provider;

  _cachedRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: provider,
    redirect: (context, state) {
      final isLoggedIn = provider.user != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/calibration',
        builder: (context, state) => const CalibrationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _DashboardPlaceholder()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _AnalyticsPlaceholder()),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _SocialPlaceholder()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _ProfilePlaceholder()),
          ),
        ],
      ),
      GoRoute(
        path: '/add-bill',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'expense';
          return AddBillScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/split',
        builder: (context, state) => const SplitFriendsScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/pool/:id',
        builder: (context, state) {
          final poolId = state.pathParameters['id'] ?? '';
          return PoolDetailScreen(poolId: poolId);
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/create-pool-bill',
        builder: (context, state) => const CreatePoolScreen(),
      ),
    ],
  );
  return _cachedRouter!;
}

// Thin wrappers — actual screens are loaded inside ShellScreen's IndexedStack
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SocialPlaceholder extends StatelessWidget {
  const _SocialPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
