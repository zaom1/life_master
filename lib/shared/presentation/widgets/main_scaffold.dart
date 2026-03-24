import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

int _indexFromLocation(String location) {
  if (location.startsWith('/reminder')) {
    return 1;
  }
  if (location.startsWith('/calendar')) {
    return 2;
  }
  if (location.startsWith('/expense')) {
    return 3;
  }
  if (location.startsWith('/subscription')) {
    return 4;
  }
  return 0;
}

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          height: 64,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/todo');
                break;
              case 1:
                context.go('/reminder');
                break;
              case 2:
                context.go('/calendar');
                break;
              case 3:
                context.go('/expense');
                break;
              case 4:
                context.go('/subscription');
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline),
              selectedIcon:
                  const Icon(Icons.check_circle, color: AppTheme.todoColor),
              label: l10n.navTodo,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon:
                  const Icon(Icons.notifications, color: AppTheme.reminderColor),
              label: l10n.navReminder,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  const Icon(Icons.calendar_month, color: AppTheme.calendarColor),
              label: l10n.navCalendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.expenseColor,
              ),
              label: l10n.navExpense,
            ),
            NavigationDestination(
              icon: const Icon(Icons.subscriptions_outlined),
              selectedIcon:
                  const Icon(Icons.subscriptions, color: AppTheme.subscriptionColor),
              label: l10n.navSubscription,
            ),
          ],
        ),
      ),
    );
  }
}
