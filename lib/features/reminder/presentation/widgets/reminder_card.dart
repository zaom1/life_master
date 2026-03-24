import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/presentation/widgets/form_validation_helpers.dart';
import '../providers/reminder_provider.dart';
import 'reminder_dialog.dart';

class ReminderCard extends ConsumerWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final isOverdue = reminder.remindTime.isBefore(DateTime.now()) && !reminder.isCompleted;
    final accentColor = isOverdue ? Colors.red : AppTheme.reminderColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: GestureDetector(
            onTap: () async {
              try {
                await ref.read(reminderNotifierProvider.notifier).toggleComplete(reminder);
                if (context.mounted) {
                  showFormSuccess(
                    context,
                    reminder.isCompleted
                        ? l10n.successReminderRestored
                        : l10n.successReminderCompleted,
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
                color: reminder.isCompleted ? AppTheme.reminderColor : Colors.transparent,
                border: Border.all(
                  color: reminder.isCompleted
                      ? AppTheme.reminderColor
                      : (isOverdue ? Colors.red : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: reminder.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted ? Colors.grey[400] : (isOverdue ? Colors.red[700] : null),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminder.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  reminder.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 11, color: accentColor),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat.Md(localeName).add_Hm().format(reminder.remindTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reminder.isRepeating) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.reminderColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 11, color: AppTheme.reminderColor),
                          const SizedBox(width: 3),
                          Text(
                            switch (reminder.repeatType) {
                              'daily' => l10n.repeatDaily,
                              'weekly' => l10n.repeatWeekly,
                              'monthly' => l10n.repeatMonthly,
                              _ => reminder.repeatType,
                            },
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.reminderColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.badgeOverdue,
                        style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
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
                onPressed: () => showReminderDialog(context, ref, reminder: reminder),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => showReminderDeleteConfirm(context, ref, reminder),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
