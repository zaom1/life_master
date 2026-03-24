import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/presentation/widgets/delete_confirm_dialog.dart';
import '../../../../shared/presentation/widgets/form_bottom_sheet.dart';
import '../../../../shared/presentation/widgets/form_field_section.dart';
import '../../../../shared/presentation/widgets/form_picker_helpers.dart';
import '../../../../shared/presentation/widgets/form_picker_tile.dart';
import '../../../../shared/presentation/widgets/form_primary_button.dart';
import '../../../../shared/presentation/widgets/form_validation_helpers.dart';
import '../providers/todo_provider.dart';
import 'todo_meta.dart';

void showTodoDeleteConfirm(BuildContext context, WidgetRef ref, Todo todo) {
  final l10n = AppLocalizations.of(context)!;
  showDeleteConfirmDialog(
    context,
    title: l10n.dialogDeleteTodoTitle,
    message: l10n.dialogDeleteTodoMessage(todo.title),
    cancelText: l10n.actionCancel,
    confirmText: l10n.actionDelete,
    onConfirm: () async {
      try {
        await ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
        if (context.mounted) {
          showFormSuccess(context, l10n.successTodoDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          showFormError(context, l10n.errorDeleteFailed(e.toString()));
        }
      }
    },
  );
}

void showTodoDialog(BuildContext context, WidgetRef ref, {Todo? todo}) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toString();
  final isEditing = todo != null;
  final titleController = TextEditingController(text: isEditing ? todo.title : '');
  final descController =
      TextEditingController(text: isEditing ? todo.description : '');
  String selectedCategory = isEditing ? todo.category : 'General';
  DateTime? dueDate = isEditing ? todo.dueDate : null;
  bool isImportant = isEditing ? todo.isImportant : false;
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FormBottomSheet(
            accentColor: AppTheme.todoColor,
            icon: isEditing ? Icons.edit : Icons.add_task,
            title: isEditing ? l10n.dialogEditTodo : l10n.dialogNewTodo,
            children: [
                FormFieldSection(
                  children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: l10n.fieldTodoTitle,
                    hintText: l10n.hintTodoTitle,
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.fieldDescriptionOptional,
                    hintText: l10n.hintDescriptionDetail,
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.fieldCategory,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: ref
                      .read(todoCategoriesProvider)
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text(todoCategoryLabel(l10n, c))),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                FormPickerTile(
                  onTap: () async {
                    final date = await pickDateValue(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => dueDate = date);
                    }
                  },
                  icon: Icons.calendar_today,
                  content: Text(
                    dueDate == null
                        ? l10n.labelSetDueDate
                        : l10n.labelDueDate(
                            DateFormat.yMd(localeName).format(dueDate!),
                          ),
                    style: TextStyle(
                      color: dueDate == null ? Colors.grey[500] : null,
                      fontSize: 16,
                    ),
                  ),
                  trailing: dueDate != null
                      ? GestureDetector(
                          onTap: () => setState(() => dueDate = null),
                          child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                        )
                      : Icon(Icons.chevron_right, color: Colors.grey[400]),
                ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.labelMarkImportant),
                  subtitle:
                      Text(l10n.labelMarkImportantHint, style: const TextStyle(fontSize: 12)),
                  secondary: Icon(
                    isImportant ? Icons.star : Icons.star_border,
                    color: isImportant ? Colors.amber : Colors.grey,
                  ),
                  value: isImportant,
                  onChanged: (v) => setState(() => isImportant = v),
                ),
                const SizedBox(height: 8),
                FormPrimaryButton(
                  label: isEditing ? l10n.actionSaveChanges : l10n.actionAddTodo,
                  color: AppTheme.todoColor,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    if (!ensureRequiredText(
                      context,
                      titleController.text,
                      fieldLabel: l10n.fieldTodoTitle,
                    )) {
                      return;
                    }

                    setState(() => isSubmitting = true);
                    try {
                      if (isEditing) {
                        await ref.read(todoNotifierProvider.notifier).updateTodo(
                              todo.copyWith(
                                title: titleController.text.trim(),
                                description: descController.text.isEmpty
                                    ? const Value.absent()
                                    : Value(descController.text),
                                category: selectedCategory,
                                dueDate: dueDate == null
                                    ? const Value.absent()
                                    : Value(dueDate),
                                isImportant: isImportant,
                              ),
                            );
                      } else {
                        await ref.read(todoNotifierProvider.notifier).addTodo(
                              title: titleController.text.trim(),
                              description: descController.text.isEmpty
                                  ? null
                                  : descController.text,
                              category: selectedCategory,
                              dueDate: dueDate,
                              isImportant: isImportant,
                            );
                      }
                      if (!context.mounted) return;
                      showFormSuccess(
                        context,
                        isEditing ? l10n.successTodoUpdated : l10n.successTodoAdded,
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        showFormError(context, l10n.errorSaveFailed(e.toString()));
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
          );
        },
      );
    },
  );
}
