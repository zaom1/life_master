import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/providers/async_action_notifier.dart';
import '../../../../shared/providers/database_provider.dart';

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllReminders();
});

class ReminderNotifier extends AsyncActionNotifier {
  final AppDatabase _db;

  ReminderNotifier(this._db);
  
  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime remindTime,
    bool isRepeating = false,
    String repeatType = 'none',
  }) async {
    await runAction(() async {
      final id = await _db.insertReminder(RemindersCompanion.insert(
        title: title,
        description: Value(description),
        remindTime: remindTime,
        isRepeating: Value(isRepeating),
        repeatType: Value(repeatType),
      ));
      
      // Schedule notification
      await NotificationService().scheduleReminder(
        id: id,
        title: title,
        body: description,
        scheduledDate: remindTime,
        repeatType: isRepeating ? repeatType : 'none',
      );
    }, showLoading: true, rethrowOnError: true);
  }
  
  Future<void> toggleComplete(Reminder reminder) async {
    await runAction(() async {
      final updatedReminder = reminder.copyWith(
        isCompleted: !reminder.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _db.updateReminder(updatedReminder);

      if (updatedReminder.isCompleted) {
        await NotificationService().cancelReminder(updatedReminder.id);
      } else {
        await NotificationService().scheduleReminder(
          id: updatedReminder.id,
          title: updatedReminder.title,
          body: updatedReminder.description,
          scheduledDate: updatedReminder.remindTime,
          repeatType:
              updatedReminder.isRepeating ? updatedReminder.repeatType : 'none',
        );
      }
    }, rethrowOnError: true);
  }
  
  Future<void> deleteReminder(int id) async {
    await runAction(() async {
      await _db.deleteReminder(id);
      await NotificationService().cancelReminder(id);
    }, rethrowOnError: true);
  }
  
  Future<void> updateReminder(Reminder reminder) async {
    await runAction(() async {
      await _db.updateReminder(reminder.copyWith(updatedAt: DateTime.now()));
      
      // Reschedule notification if not completed
      if (!reminder.isCompleted) {
        await NotificationService().scheduleReminder(
          id: reminder.id,
          title: reminder.title,
          body: reminder.description,
          scheduledDate: reminder.remindTime,
          repeatType: reminder.isRepeating ? reminder.repeatType : 'none',
        );
      } else {
        await NotificationService().cancelReminder(reminder.id);
      }
    }, rethrowOnError: true);
  }
}

final reminderNotifierProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderNotifier(db);
});
