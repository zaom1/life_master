import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

final _currentIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  final Widget child;
  
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_currentIndexProvider);
    final location = GoRouterState.of(context).uri.path;
    
    // 根据当前位置更新索引
    int newIndex = 0;
    if (location.contains('/reminder')) {
      newIndex = 1;
    } else if (location.contains('/calendar')) {
      newIndex = 2;
    } else if (location.contains('/expense')) {
      newIndex = 3;
    } else if (location.contains('/subscription')) {
      newIndex = 4;
    }
    
    // 如果索引发生变化，更新状态
    if (newIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(_currentIndexProvider.notifier).state = newIndex;
      });
    }
    
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
          selectedIndex: newIndex,
          height: 64,
          onDestinationSelected: (index) {
            ref.read(_currentIndexProvider.notifier).state = index;
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle, color: AppTheme.todoColor),
              label: '待办',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: AppTheme.reminderColor),
              label: '提醒',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: AppTheme.calendarColor),
              label: '日历',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.expenseColor),
              label: '支出',
            ),
            NavigationDestination(
              icon: Icon(Icons.subscriptions_outlined),
              selectedIcon: Icon(Icons.subscriptions, color: AppTheme.subscriptionColor),
              label: '订阅',
            ),
          ],
        ),
      ),
    );
  }
}
