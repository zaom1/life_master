import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_chart.dart';
import '../widgets/expense_dialog.dart';

class ExpensePage extends ConsumerWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageExpenseTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: l10n.expenseMonthlyTotal,
                    amount: monthlyExpense,
                    icon: Icons.calendar_month,
                    color: AppTheme.expenseColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: l10n.expenseTotal,
                    amount: totalExpense,
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.expenseSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(expenseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(expenseSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          const ExpenseChart(),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) return _ExpenseEmptyState();

                final sortedExpenses = List<Expense>.from(expenses)
                  ..sort((a, b) => b.date.compareTo(a.date));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: sortedExpenses.length,
                  itemBuilder: (context, index) {
                    return ExpenseCard(expense: sortedExpenses[index]);
                  },
                );
              },
              loading: () =>
                  Center(child: CircularProgressIndicator(color: AppTheme.expenseColor)),
              error: (e, st) => Center(child: Text(l10n.errorLoadFailed(e.toString()))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseDialog(context, ref),
        backgroundColor: AppTheme.expenseColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.actionAddExpense,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.expenseColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 48,
              color: AppTheme.expenseColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.expenseEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.expenseEmptyHint,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
