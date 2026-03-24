import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../providers/expense_provider.dart';
import 'expense_meta.dart';

void showExpenseDeleteConfirm(BuildContext context, WidgetRef ref, Expense expense) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toString();
  showDeleteConfirmDialog(
    context,
    title: l10n.dialogDeleteExpenseTitle,
    message: l10n.dialogDeleteExpenseMessage,
    cancelText: l10n.actionCancel,
    confirmText: l10n.actionDelete,
    onConfirm: () async {
      try {
        await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
        if (context.mounted) {
          showFormSuccess(context, l10n.successExpenseDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          showFormError(context, l10n.errorDeleteFailed(e.toString()));
        }
      }
    },
  );
}

void showExpenseDialog(BuildContext context, WidgetRef ref, {Expense? expense}) {
  final l10n = AppLocalizations.of(context)!;
  final isEditing = expense != null;
  final amountController = TextEditingController(text: isEditing ? expense.amount.toString() : '');
  final descController = TextEditingController(text: isEditing ? expense.description : '');
  final paymentController = TextEditingController(text: isEditing ? expense.paymentMethod : '');
  String selectedCategory = isEditing ? expense.category : 'Food';
  DateTime selectedDate = isEditing ? expense.date : DateTime.now();
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FormBottomSheet(
            accentColor: AppTheme.expenseColor,
            icon: isEditing ? Icons.edit : Icons.add_circle_outline,
            title: isEditing ? l10n.dialogEditExpense : l10n.dialogNewExpense,
            children: [
                  FormFieldSection(
                    children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: l10n.fieldAmount,
                      hintText: '0.00',
                      prefixText: '¥ ',
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.expenseColor,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.fieldCategory,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: ref
                        .read(expenseCategoriesProvider)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(expenseCategoryIcon(c), size: 18, color: AppTheme.expenseColor),
                                const SizedBox(width: 8),
                                Text(expenseCategoryLabel(l10n, c)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldDescriptionOptional,
                      hintText: l10n.hintDescriptionDetail,
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  TextField(
                    controller: paymentController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldPaymentOptional,
                      hintText: l10n.hintPaymentMethod,
                      prefixIcon: const Icon(Icons.payment),
                    ),
                  ),
                  FormPickerTile(
                    onTap: () async {
                      final date = await pickDateValue(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    icon: Icons.calendar_today,
                    content: Text(
                      DateFormat.yMd(localeName).format(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FormPrimaryButton(
                    label: isEditing ? l10n.actionSaveChanges : l10n.actionRecordExpense,
                    color: AppTheme.expenseColor,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final amount = ensurePositiveAmount(
                        context,
                        amountController.text,
                        fieldLabel: l10n.fieldAmount,
                      );
                      if (amount == null) {
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        if (isEditing) {
                          await ref.read(expenseNotifierProvider.notifier).updateExpense(
                                expense.copyWith(
                                  amount: amount,
                                  category: selectedCategory,
                                  description: descController.text.isEmpty ? null : descController.text,
                                  date: selectedDate,
                                  paymentMethod: paymentController.text.isEmpty ? null : paymentController.text,
                                ),
                              );
                        } else {
                          await ref.read(expenseNotifierProvider.notifier).addExpense(
                                amount: amount,
                                category: selectedCategory,
                                description: descController.text.isEmpty ? null : descController.text,
                                date: selectedDate,
                                paymentMethod: paymentController.text.isEmpty ? null : paymentController.text,
                              );
                        }
                        if (!context.mounted) return;
                        showFormSuccess(
                          context,
                          isEditing ? l10n.successExpenseUpdated : l10n.successExpenseAdded,
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
    },
  );
}
