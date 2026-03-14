import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/presentation/pages/todo_page.dart';
import '../../features/reminder/presentation/pages/reminder_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/expense/presentation/pages/expense_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../shared/presentation/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/todo',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/todo',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodoPage(),
            ),
          ),
          GoRoute(
            path: '/reminder',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReminderPage(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarPage(),
            ),
          ),
          GoRoute(
            path: '/expense',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExpensePage(),
            ),
          ),
          GoRoute(
            path: '/subscription',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SubscriptionPage(),
            ),
          ),
        ],
      ),
    ],
  );
});
