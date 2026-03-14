import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllReminders();
});

class ReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  
  ReminderNotifier(this._db) : super(const AsyncValue.data(null));
  
  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime remindTime,
    bool isRepeating = false,
    String repeatType = 'none',
  }) async {
    state = const AsyncValue.loading();
    try {
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
      );
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> toggleComplete(Reminder reminder) async {
    try {
      await _db.updateReminder(reminder.copyWith(
        isCompleted: !reminder.isCompleted,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> deleteReminder(int id) async {
    try {
      await _db.deleteReminder(id);
      await NotificationService().cancelReminder(id);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _db.updateReminder(reminder.copyWith(updatedAt: DateTime.now()));
      
      // Reschedule notification if not completed
      if (!reminder.isCompleted) {
        await NotificationService().scheduleReminder(
          id: reminder.id,
          title: reminder.title,
          body: reminder.description,
          scheduledDate: reminder.remindTime,
        );
      } else {
        await NotificationService().cancelReminder(reminder.id);
      }
    } catch (e) {
      // Handle error
    }
  }
}

final reminderNotifierProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderNotifier(db);
});
