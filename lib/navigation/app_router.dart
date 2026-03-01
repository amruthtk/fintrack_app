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
import '../screens/profile_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/settlements_screen.dart';
import '../screens/pools_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/group_details_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/security_screen.dart';
import '../screens/to_pay_screen.dart';
import '../screens/to_receive_screen.dart';
import '../screens/today_spent_screen.dart';
import '../screens/group_bills_screen.dart';
import '../screens/spin_wheel_screen.dart';

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
    initialLocation: '/splash',
    refreshListenable: provider,
    redirect: (context, state) {
      final user = provider.user;
      final isLoggedIn = user != null;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/auth';
      final isCalibrationRoute = state.matchedLocation == '/calibration';

      // Allow splash to finish
      if (isSplashRoute) return null;

      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn) {
        if (isAuthRoute) return '/';

        // Redirection for calibration
        final needsCalibration =
            user.wealthCalibrationComplete != true &&
            !user.wallets.any((w) => w.balance > 0);
        if (needsCalibration && !isCalibrationRoute) {
          return '/calibration';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
                const NoTransitionPage(child: DashboardScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      GoRoute(
        path: '/settlements',
        builder: (context, state) {
          final initialTab = state.uri.queryParameters['tab'];
          return SettlementsScreen(initialTab: initialTab);
        },
      ),
      GoRoute(path: '/pools', builder: (context, state) => const PoolsScreen()),
      GoRoute(path: '/to-pay', builder: (context, state) => const ToPayScreen()),
      GoRoute(path: '/to-receive', builder: (context, state) => const ToReceiveScreen()),
      GoRoute(path: '/today-spent', builder: (context, state) => const TodaySpentScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
        builder: (context, state) {
          final wallet = state.uri.queryParameters['wallet'];
          return TransactionsScreen(initialWallet: wallet);
        },
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
      GoRoute(
        path: '/group/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id'] ?? '';
          return GroupDetailsScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/group-bills/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id'] ?? '';
          final groupName = state.uri.queryParameters['name'] ?? 'Group';
          return GroupBillsScreen(groupId: groupId, groupName: groupName);
        },
      ),
      GoRoute(
        path: '/spin-wheel',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final members = (extra?['memberNames'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final groupName = extra?['groupName'] as String? ?? 'Group';
          return SpinWheelScreen(memberNames: members, groupName: groupName);
        },
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
    ],
  );
  return _cachedRouter!;
}

// Shell placeholders are no longer needed as we use actual screens in the routes
