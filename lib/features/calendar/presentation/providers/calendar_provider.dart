import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final calendarEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCalendarEvents();
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class CalendarEventNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  
  CalendarEventNotifier(this._db) : super(const AsyncValue.data(null));
  
  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String color = '#10B981',
    bool isAllDay = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertCalendarEvent(CalendarEventsCompanion.insert(
        title: title,
        description: Value(description),
        startTime: startTime,
        endTime: endTime,
        location: Value(location),
        color: Value(color),
        isAllDay: Value(isAllDay),
      ));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> deleteEvent(int id) async {
    try {
      await _db.deleteCalendarEvent(id);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _db.updateCalendarEvent(event.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      // Handle error
    }
  }
}

final calendarEventNotifierProvider = StateNotifierProvider<CalendarEventNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return CalendarEventNotifier(db);
});
