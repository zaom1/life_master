import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AsyncActionNotifier extends StateNotifier<AsyncValue<void>> {
  AsyncActionNotifier() : super(const AsyncValue.data(null));

  Future<void> runAction(
    Future<void> Function() action, {
    bool showLoading = false,
    bool rethrowOnError = false,
  }) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }

    try {
      await action();
      if (showLoading) {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (rethrowOnError) {
        rethrow;
      }
    }
  }
}
