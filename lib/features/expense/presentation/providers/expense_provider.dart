import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/providers/async_action_notifier.dart';
import '../../../../shared/providers/database_provider.dart';

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllExpenses();
});

final expenseCategoriesProvider = Provider<List<String>>((ref) {
  return ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Education', 'Housing', 'Utilities', 'Other'];
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final searchQuery = ref.watch(expenseSearchQueryProvider);
  
  if (searchQuery.isEmpty) return expensesAsync;
  
  return expensesAsync.when(
    data: (expenses) {
      final filtered = expenses.where((e) =>
        e.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (e.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final totalExpenseProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.when(
    data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.amount),
    loading: () => 0.0,
    error: (e, st) => 0.0,
  );
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final now = DateTime.now();
  return expensesAsync.when(
    data: (expenses) => expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount),
    loading: () => 0.0,
    error: (e, st) => 0.0,
  );
});

class ExpenseNotifier extends AsyncActionNotifier {
  final AppDatabase _db;

  ExpenseNotifier(this._db);
  
  Future<void> addExpense({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
    String? paymentMethod,
  }) async {
    await runAction(() async {
      await _db.insertExpense(ExpensesCompanion.insert(
        amount: amount,
        category: category,
        description: Value(description),
        date: date,
        paymentMethod: Value(paymentMethod),
      ));
    }, showLoading: true, rethrowOnError: true);
  }
  
  Future<void> deleteExpense(int id) async {
    await runAction(() async {
      await _db.deleteExpense(id);
    }, rethrowOnError: true);
  }
  
  Future<void> updateExpense(Expense expense) async {
    await runAction(() async {
      await _db.updateExpense(expense.copyWith(updatedAt: DateTime.now()));
    }, rethrowOnError: true);
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseNotifier(db);
});
