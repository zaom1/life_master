import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/providers/async_action_notifier.dart';
import '../../../../shared/providers/database_provider.dart';

final calendarEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCalendarEvents();
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class CalendarEventNotifier extends AsyncActionNotifier {
  final AppDatabase _db;

  CalendarEventNotifier(this._db);
  
  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String color = '#10B981',
    bool isAllDay = false,
  }) async {
    await runAction(() async {
      await _db.insertCalendarEvent(CalendarEventsCompanion.insert(
        title: title,
        description: Value(description),
        startTime: startTime,
        endTime: endTime,
        location: Value(location),
        color: Value(color),
        isAllDay: Value(isAllDay),
      ));
    }, showLoading: true, rethrowOnError: true);
  }
  
  Future<void> deleteEvent(int id) async {
    await runAction(() async {
      await _db.deleteCalendarEvent(id);
    }, rethrowOnError: true);
  }
  
  Future<void> updateEvent(CalendarEvent event) async {
    await runAction(() async {
      await _db.updateCalendarEvent(event.copyWith(updatedAt: DateTime.now()));
    }, rethrowOnError: true);
  }
}

final calendarEventNotifierProvider = StateNotifierProvider<CalendarEventNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return CalendarEventNotifier(db);
});
