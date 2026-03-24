import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_dialog.dart';
import '../widgets/todo_meta.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  static const _allCategoryValue = '__all__';
  String _selectedCategory = _allCategoryValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todosAsync = ref.watch(todosProvider);
    final categories = ref.watch(todoCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageTodoTitle),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.todoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 18, color: AppTheme.todoColor),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCategory == _allCategoryValue
                        ? l10n.labelAll
                        : todoCategoryLabel(l10n, _selectedCategory),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.todoColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (value) => setState(() => _selectedCategory = value),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(value: _allCategoryValue, child: Text(l10n.labelAll)),
              ...categories.map(
                (c) => PopupMenuItem(value: c, child: Text(todoCategoryLabel(l10n, c))),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: todosAsync.when(
        data: (todos) {
          final filteredTodos = _selectedCategory == _allCategoryValue
              ? todos
              : todos.where((t) => t.category == _selectedCategory).toList();

          if (filteredTodos.isEmpty) {
            return _TodoEmptyState();
          }

          final completedCount =
              filteredTodos.where((t) => t.isCompleted).length;
          final total = filteredTodos.length;

          return Column(
            children: [
              _TodoProgressCard(completedCount: completedCount, total: total),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return TodoCard(todo: todo);
                  },
                ),
              ),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppTheme.todoColor)),
        error: (e, st) => Center(child: Text(l10n.errorLoadFailed(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTodoDialog(context, ref),
        backgroundColor: AppTheme.todoColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddTodo, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TodoProgressCard extends StatelessWidget {
  final int completedCount;
  final int total;

  const _TodoProgressCard({required this.completedCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.todoColor, AppTheme.todoColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todoProgressToday,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.todoProgressCompleted(completedCount, total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completedCount / total : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${total > 0 ? (completedCount / total * 100).round() : 0}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoEmptyState extends StatelessWidget {
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
              color: AppTheme.todoColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.todoColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.todoEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.todoEmptyHint,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
