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
import '../providers/reminder_provider.dart';

void showReminderDeleteConfirm(BuildContext context, WidgetRef ref, Reminder reminder) {
  final l10n = AppLocalizations.of(context)!;
  showDeleteConfirmDialog(
    context,
    title: l10n.dialogDeleteReminderTitle,
    message: l10n.dialogDeleteReminderMessage(reminder.title),
    cancelText: l10n.actionCancel,
    confirmText: l10n.actionDelete,
    onConfirm: () async {
      try {
        await ref.read(reminderNotifierProvider.notifier).deleteReminder(reminder.id);
        if (context.mounted) {
          showFormSuccess(context, l10n.successReminderDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          showFormError(context, l10n.errorDeleteFailed(e.toString()));
        }
      }
    },
  );
}

void showReminderDialog(BuildContext context, WidgetRef ref, {Reminder? reminder}) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toString();
  final isEditing = reminder != null;
  final titleController = TextEditingController(text: isEditing ? reminder.title : '');
  final descController = TextEditingController(text: isEditing ? reminder.description : '');
  DateTime selectedDateTime = isEditing
      ? reminder.remindTime
      : DateTime.now().add(const Duration(hours: 1));
  bool isRepeating = isEditing ? reminder.isRepeating : false;
  String repeatType = isEditing ? reminder.repeatType : 'none';
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FormBottomSheet(
            accentColor: AppTheme.reminderColor,
            icon: isEditing ? Icons.edit : Icons.add_alarm,
            title: isEditing ? l10n.dialogEditReminder : l10n.dialogNewReminder,
            children: [
                FormFieldSection(
                  children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.fieldReminderTitle,
                    hintText: l10n.hintReminderTitle,
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
                FormPickerTile(
                  onTap: () async {
                    final selected = await pickDateTimeValue(
                      context: context,
                      initialDateTime: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(() {
                        selectedDateTime = selected;
                      });
                    }
                  },
                  icon: Icons.access_time,
                  content: Text(
                    DateFormat.yMd(localeName).add_Hm().format(selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.labelRepeatReminder),
                  secondary: Icon(
                    Icons.repeat,
                    color: isRepeating ? AppTheme.reminderColor : Colors.grey,
                  ),
                  value: isRepeating,
                  onChanged: (v) => setState(() => isRepeating = v),
                ),
                if (isRepeating) ...[
                  DropdownButtonFormField<String>(
                    value: repeatType == 'none' ? 'daily' : repeatType,
                    decoration: InputDecoration(
                      labelText: l10n.fieldRepeatFrequency,
                      prefixIcon: const Icon(Icons.calendar_view_week),
                    ),
                    items: [
                      DropdownMenuItem(value: 'daily', child: Text(l10n.repeatDaily)),
                      DropdownMenuItem(value: 'weekly', child: Text(l10n.repeatWeekly)),
                      DropdownMenuItem(value: 'monthly', child: Text(l10n.repeatMonthly)),
                    ],
                    onChanged: (v) => setState(() => repeatType = v!),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                FormPrimaryButton(
                  label: isEditing ? l10n.actionSaveChanges : l10n.actionAddReminder,
                  color: AppTheme.reminderColor,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    if (!ensureRequiredText(
                      context,
                      titleController.text,
                      fieldLabel: l10n.fieldReminderTitle,
                    )) {
                      return;
                    }

                    setState(() => isSubmitting = true);
                    try {
                      if (isEditing) {
                        await ref.read(reminderNotifierProvider.notifier).updateReminder(
                              reminder.copyWith(
                                title: titleController.text.trim(),
                                description: descController.text.isEmpty
                                    ? const Value.absent()
                                    : Value(descController.text),
                                remindTime: selectedDateTime,
                                isRepeating: isRepeating,
                                repeatType: repeatType,
                              ),
                            );
                      } else {
                        await ref.read(reminderNotifierProvider.notifier).addReminder(
                              title: titleController.text.trim(),
                              description: descController.text.isEmpty ? null : descController.text,
                              remindTime: selectedDateTime,
                              isRepeating: isRepeating,
                              repeatType: repeatType,
                            );
                      }
                      if (!context.mounted) return;
                      showFormSuccess(
                        context,
                        isEditing ? l10n.successReminderUpdated : l10n.successReminderAdded,
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
