import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/providers/async_action_notifier.dart';
import '../../../../shared/providers/database_provider.dart';

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSubscriptions();
});

final subscriptionCategoriesProvider = Provider<List<String>>((ref) {
  return ['Streaming', 'Music', 'Gaming', 'Productivity', 'Cloud Storage', 'Fitness', 'News', 'Other'];
});

double _monthlyEquivalent(Subscription subscription) {
  switch (subscription.billingCycle) {
    case 'weekly':
      return subscription.amount * 52 / 12;
    case 'yearly':
      return subscription.amount / 12;
    case 'monthly':
    default:
      return subscription.amount;
  }
}

final totalSubscriptionProvider = Provider<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.when(
    data: (subs) =>
        subs.where((s) => s.isActive).fold(0.0, (sum, s) => sum + _monthlyEquivalent(s)),
    loading: () => 0.0,
    error: (e, st) => 0.0,
  );
});

class SubscriptionNotifier extends AsyncActionNotifier {
  final AppDatabase _db;

  SubscriptionNotifier(this._db);
  
  Future<void> addSubscription({
    required String name,
    required double amount,
    required String category,
    required DateTime startDate,
    required DateTime nextBillingDate,
    String billingCycle = 'monthly',
    String? description,
  }) async {
    await runAction(() async {
      await _db.insertSubscription(SubscriptionsCompanion.insert(
        name: name,
        amount: amount,
        category: category,
        startDate: startDate,
        nextBillingDate: nextBillingDate,
        billingCycle: Value(billingCycle),
        description: Value(description),
      ));
    }, showLoading: true, rethrowOnError: true);
  }
  
  Future<void> toggleActive(Subscription subscription) async {
    await runAction(() async {
      await _db.updateSubscription(subscription.copyWith(
        isActive: !subscription.isActive,
        updatedAt: DateTime.now(),
      ));
    }, rethrowOnError: true);
  }
  
  Future<void> deleteSubscription(int id) async {
    await runAction(() async {
      await _db.deleteSubscription(id);
    }, rethrowOnError: true);
  }
  
  Future<void> updateSubscription(Subscription subscription) async {
    await runAction(() async {
      await _db.updateSubscription(subscription.copyWith(updatedAt: DateTime.now()));
    }, rethrowOnError: true);
  }
}

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return SubscriptionNotifier(db);
});
