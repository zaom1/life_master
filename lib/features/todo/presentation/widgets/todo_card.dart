import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/presentation/widgets/form_validation_helpers.dart';
import '../providers/todo_provider.dart';
import 'todo_dialog.dart';
import 'todo_meta.dart';

class TodoCard extends ConsumerWidget {
  final Todo todo;

  const TodoCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final isOverdue =
        todo.dueDate != null && todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: GestureDetector(
            onTap: () async {
              try {
                await ref.read(todoNotifierProvider.notifier).toggleComplete(todo);
                if (context.mounted) {
                  showFormSuccess(
                    context,
                    todo.isCompleted ? l10n.successTodoRestored : l10n.successTodoCompleted,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showFormError(context, l10n.errorActionFailed(e.toString()));
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isCompleted ? AppTheme.todoColor : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted ? AppTheme.todoColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    color: todo.isCompleted ? Colors.grey[400] : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (todo.isImportant)
                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  todo.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.todoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      todoCategoryLabel(l10n, todo.category),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.todoColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (todo.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 11,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat.Md(localeName).format(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? Colors.red : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => showTodoDialog(context, ref, todo: todo),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => showTodoDeleteConfirm(context, ref, todo),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
