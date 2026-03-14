import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final todosProvider = StreamProvider<List<Todo>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTodos();
});

final todoCategoriesProvider = Provider<List<String>>((ref) {
  return ['General', 'Work', 'Personal', 'Health', 'Shopping', 'Finance'];
});

class TodoNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  
  TodoNotifier(this._db) : super(const AsyncValue.data(null));
  
  Future<void> addTodo({
    required String title,
    String? description,
    String category = 'General',
    DateTime? dueDate,
    bool isImportant = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertTodo(TodosCompanion.insert(
        title: title,
        description: Value(description),
        category: Value(category),
        dueDate: Value(dueDate),
        isImportant: Value(isImportant),
      ));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> toggleComplete(Todo todo) async {
    try {
      await _db.updateTodo(todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> deleteTodo(int id) async {
    try {
      await _db.deleteTodo(id);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateTodo(Todo todo) async {
    try {
      await _db.updateTodo(todo.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      // Handle error
    }
  }
}

final todoNotifierProvider = StateNotifierProvider<TodoNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return TodoNotifier(db);
});
