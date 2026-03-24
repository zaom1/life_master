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
import '../providers/subscription_provider.dart';
import 'subscription_meta.dart';

void showSubscriptionDeleteConfirm(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toString();
  showDeleteConfirmDialog(
    context,
    title: l10n.dialogDeleteSubscriptionTitle,
    message: l10n.dialogDeleteSubscriptionMessage(subscription.name),
    cancelText: l10n.actionCancel,
    confirmText: l10n.actionDelete,
    onConfirm: () async {
      try {
        await ref.read(subscriptionNotifierProvider.notifier).deleteSubscription(subscription.id);
        if (context.mounted) {
          showFormSuccess(context, l10n.successSubscriptionDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          showFormError(context, l10n.errorDeleteFailed(e.toString()));
        }
      }
    },
  );
}

void showSubscriptionDialog(
  BuildContext context,
  WidgetRef ref, {
  Subscription? subscription,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isEditing = subscription != null;
  final nameController = TextEditingController(text: isEditing ? subscription.name : '');
  final amountController = TextEditingController(text: isEditing ? subscription.amount.toString() : '');
  final descController = TextEditingController(text: isEditing ? subscription.description : '');
  String selectedCategory = isEditing ? subscription.category : 'Streaming';
  String billingCycle = isEditing ? subscription.billingCycle : 'monthly';
  DateTime startDate = isEditing ? subscription.startDate : DateTime.now();
  DateTime nextBilling = isEditing
      ? subscription.nextBillingDate
      : nextBillingDateFrom(DateTime.now(), billingCycle);
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FormBottomSheet(
            accentColor: AppTheme.subscriptionColor,
            icon: isEditing ? Icons.edit : Icons.add_circle_outline,
            title:
                isEditing ? l10n.dialogEditSubscription : l10n.dialogNewSubscription,
            children: [
                  FormFieldSection(
                    children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.fieldSubscriptionName,
                      hintText: l10n.hintSubscriptionName,
                      prefixIcon: const Icon(Icons.subscriptions_outlined),
                    ),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: l10n.fieldAmount,
                      hintText: '0.00',
                      prefixText: '¥ ',
                      prefixStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.subscriptionColor,
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
                        .read(subscriptionCategoriesProvider)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(subscriptionCategoryIcon(c), size: 18, color: AppTheme.subscriptionColor),
                                const SizedBox(width: 8),
                                Text(subscriptionCategoryLabel(l10n, c)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: billingCycle,
                    decoration: InputDecoration(
                      labelText: l10n.fieldBillingCycle,
                      prefixIcon: const Icon(Icons.calendar_view_month),
                    ),
                    items: [
                      DropdownMenuItem(value: 'weekly', child: Text(l10n.billingWeekly)),
                      DropdownMenuItem(value: 'monthly', child: Text(l10n.billingMonthly)),
                      DropdownMenuItem(value: 'yearly', child: Text(l10n.billingYearly)),
                    ],
                    onChanged: (v) => setState(() {
                      billingCycle = v!;
                      nextBilling = nextBillingDateFrom(startDate, billingCycle);
                    }),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldDescriptionOptional,
                      hintText: l10n.hintSubscriptionDesc,
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  FormPickerTile(
                    onTap: () async {
                      final date = await pickDateValue(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date;
                          nextBilling = nextBillingDateFrom(date, billingCycle);
                        });
                      }
                    },
                    icon: Icons.calendar_today,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.labelStartDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        Text(
                          DateFormat.yMd(localeName).format(startDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FormPrimaryButton(
                    label:
                        isEditing ? l10n.actionSaveChanges : l10n.actionAddSubscription,
                    color: AppTheme.subscriptionColor,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!ensureRequiredText(
                        context,
                        nameController.text,
                        fieldLabel: l10n.fieldSubscriptionName,
                      )) {
                        return;
                      }

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
                          await ref.read(subscriptionNotifierProvider.notifier).updateSubscription(
                                subscription.copyWith(
                                  name: nameController.text.trim(),
                                  amount: amount,
                                  category: selectedCategory,
                                  startDate: startDate,
                                  nextBillingDate: nextBilling,
                                  billingCycle: billingCycle,
                                  description: descController.text.isEmpty ? null : descController.text,
                                ),
                              );
                        } else {
                          await ref.read(subscriptionNotifierProvider.notifier).addSubscription(
                                name: nameController.text.trim(),
                                amount: amount,
                                category: selectedCategory,
                                startDate: startDate,
                                nextBillingDate: nextBilling,
                                billingCycle: billingCycle,
                                description: descController.text.isEmpty ? null : descController.text,
                              );
                        }
                        if (!context.mounted) return;
                        showFormSuccess(
                          context,
                          isEditing
                              ? l10n.successSubscriptionUpdated
                              : l10n.successSubscriptionAdded,
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
