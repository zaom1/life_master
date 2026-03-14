import 'package:drift/drift.dart';

import 'app_database_native.dart'
    if (dart.library.html) 'app_database_web.dart';

part 'app_database.g.dart';

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get remindTime => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isRepeating => boolean().withDefault(const Constant(false))();
  TextColumn get repeatType => text().withDefault(const Constant('none'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get location => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#10B981'))();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextBillingDate => dateTime()();
  TextColumn get billingCycle => text().withDefault(const Constant('monthly'))();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Todos, Reminders, CalendarEvents, Expenses, Subscriptions])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(openConnection());

  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
      },
    );
  }
  
  Future<List<Todo>> getAllTodos() => select(todos).get();
  
  Stream<List<Todo>> watchAllTodos() => select(todos).watch();
  
  Future<int> insertTodo(TodosCompanion todo) => into(todos).insert(todo);
  
  Future<bool> updateTodo(Todo todo) => update(todos).replace(todo);
  
  Future<int> deleteTodo(int id) => (delete(todos)..where((t) => t.id.equals(id))).go();
  
  Future<List<Reminder>> getAllReminders() => select(reminders).get();
  
  Stream<List<Reminder>> watchAllReminders() => select(reminders).watch();
  
  Future<int> insertReminder(RemindersCompanion reminder) => into(reminders).insert(reminder);
  
  Future<bool> updateReminder(Reminder reminder) => update(reminders).replace(reminder);
  
  Future<int> deleteReminder(int id) => (delete(reminders)..where((r) => r.id.equals(id))).go();
  
  Future<List<CalendarEvent>> getAllCalendarEvents() => select(calendarEvents).get();
  
  Stream<List<CalendarEvent>> watchAllCalendarEvents() => select(calendarEvents).watch();
  
  Future<int> insertCalendarEvent(CalendarEventsCompanion event) => into(calendarEvents).insert(event);
  
  Future<bool> updateCalendarEvent(CalendarEvent event) => update(calendarEvents).replace(event);
  
  Future<int> deleteCalendarEvent(int id) => (delete(calendarEvents)..where((e) => e.id.equals(id))).go();
  
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  
  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();
  
  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  
  Future<bool> updateExpense(Expense expense) => update(expenses).replace(expense);
  
  Future<int> deleteExpense(int id) => (delete(expenses)..where((e) => e.id.equals(id))).go();
  
  Future<List<Subscription>> getAllSubscriptions() => select(subscriptions).get();
  
  Stream<List<Subscription>> watchAllSubscriptions() => select(subscriptions).watch();
  
  Future<int> insertSubscription(SubscriptionsCompanion subscription) => into(subscriptions).insert(subscription);
  
  Future<bool> updateSubscription(Subscription subscription) => update(subscriptions).replace(subscription);
  
  Future<int> deleteSubscription(int id) => (delete(subscriptions)..where((s) => s.id.equals(id))).go();
}


