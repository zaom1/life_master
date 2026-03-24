import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/reminder_provider.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_dialog.dart';

class ReminderPage extends ConsumerWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageReminderTitle)),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return _ReminderEmptyState();
          }

          final activeReminders = reminders.where((r) => !r.isCompleted).toList();
          final doneReminders = reminders.where((r) => r.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              if (activeReminders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    l10n.reminderPendingCount(activeReminders.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ...activeReminders.map((r) => ReminderCard(reminder: r)),
              ],
              if (doneReminders.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(
                    left: 4,
                    top: activeReminders.isNotEmpty ? 12 : 0,
                    bottom: 8,
                  ),
                  child: Text(
                    l10n.reminderCompletedCount(doneReminders.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                ...doneReminders.map((r) => ReminderCard(reminder: r)),
              ],
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppTheme.reminderColor)),
        error: (e, st) => Center(child: Text(l10n.errorLoadFailed(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showReminderDialog(context, ref),
        backgroundColor: AppTheme.reminderColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.actionAddReminder,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ReminderEmptyState extends StatelessWidget {
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
              color: AppTheme.reminderColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 48,
              color: AppTheme.reminderColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.reminderEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reminderEmptyHint,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
