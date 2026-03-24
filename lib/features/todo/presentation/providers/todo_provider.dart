import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/providers/async_action_notifier.dart';
import '../../../../shared/providers/database_provider.dart';

final todosProvider = StreamProvider<List<Todo>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTodos();
});

final todoCategoriesProvider = Provider<List<String>>((ref) {
  return ['General', 'Work', 'Personal', 'Health', 'Shopping', 'Finance'];
});

class TodoNotifier extends AsyncActionNotifier {
  final AppDatabase _db;

  TodoNotifier(this._db);
  
  Future<void> addTodo({
    required String title,
    String? description,
    String category = 'General',
    DateTime? dueDate,
    bool isImportant = false,
  }) async {
    await runAction(() async {
      await _db.insertTodo(TodosCompanion.insert(
        title: title,
        description: Value(description),
        category: Value(category),
        dueDate: Value(dueDate),
        isImportant: Value(isImportant),
      ));
    }, showLoading: true, rethrowOnError: true);
  }
  
  Future<void> toggleComplete(Todo todo) async {
    await runAction(() async {
      await _db.updateTodo(todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      ));
    }, rethrowOnError: true);
  }
  
  Future<void> deleteTodo(int id) async {
    await runAction(() async {
      await _db.deleteTodo(id);
    }, rethrowOnError: true);
  }
  
  Future<void> updateTodo(Todo todo) async {
    await runAction(() async {
      await _db.updateTodo(todo.copyWith(updatedAt: DateTime.now()));
    }, rethrowOnError: true);
  }
}

final todoNotifierProvider = StateNotifierProvider<TodoNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return TodoNotifier(db);
});
