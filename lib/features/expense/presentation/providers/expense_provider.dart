import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

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

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  
  ExpenseNotifier(this._db) : super(const AsyncValue.data(null));
  
  Future<void> addExpense({
    required double amount,
    required String category,
    String? description,
    required DateTime date,
    String? paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertExpense(ExpensesCompanion.insert(
        amount: amount,
        category: category,
        description: Value(description),
        date: date,
        paymentMethod: Value(paymentMethod),
      ));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> deleteExpense(int id) async {
    try {
      await _db.deleteExpense(id);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateExpense(Expense expense) async {
    try {
      await _db.updateExpense(expense.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      // Handle error
    }
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseNotifier(db);
});
