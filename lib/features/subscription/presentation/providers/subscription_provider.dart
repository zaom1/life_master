import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSubscriptions();
});

final subscriptionCategoriesProvider = Provider<List<String>>((ref) {
  return ['Streaming', 'Music', 'Gaming', 'Productivity', 'Cloud Storage', 'Fitness', 'News', 'Other'];
});

final totalSubscriptionProvider = Provider<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.when(
    data: (subs) => subs.where((s) => s.isActive).fold(0.0, (sum, s) => sum + s.amount),
    loading: () => 0.0,
    error: (e, st) => 0.0,
  );
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  
  SubscriptionNotifier(this._db) : super(const AsyncValue.data(null));
  
  Future<void> addSubscription({
    required String name,
    required double amount,
    required String category,
    required DateTime startDate,
    required DateTime nextBillingDate,
    String billingCycle = 'monthly',
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertSubscription(SubscriptionsCompanion.insert(
        name: name,
        amount: amount,
        category: category,
        startDate: startDate,
        nextBillingDate: nextBillingDate,
        billingCycle: Value(billingCycle),
        description: Value(description),
      ));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> toggleActive(Subscription subscription) async {
    try {
      await _db.updateSubscription(subscription.copyWith(
        isActive: !subscription.isActive,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> deleteSubscription(int id) async {
    try {
      await _db.deleteSubscription(id);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _db.updateSubscription(subscription.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      // Handle error
    }
  }
}

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return SubscriptionNotifier(db);
});
