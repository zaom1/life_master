import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Map<String, IconData> subscriptionCategoryIcons = {
  'Streaming': Icons.play_circle_outline,
  'Music': Icons.music_note,
  'Gaming': Icons.sports_esports,
  'Productivity': Icons.work_outline,
  'Cloud Storage': Icons.cloud_outlined,
  'News': Icons.newspaper,
  'Fitness': Icons.fitness_center,
  'Other': Icons.more_horiz,
};

String subscriptionCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Streaming':
      return l10n.subscriptionCategoryStreaming;
    case 'Music':
      return l10n.subscriptionCategoryMusic;
    case 'Gaming':
      return l10n.subscriptionCategoryGaming;
    case 'Productivity':
      return l10n.subscriptionCategoryProductivity;
    case 'Cloud Storage':
      return l10n.subscriptionCategoryCloudStorage;
    case 'News':
      return l10n.subscriptionCategoryNews;
    case 'Fitness':
      return l10n.subscriptionCategoryFitness;
    case 'Other':
      return l10n.subscriptionCategoryOther;
    default:
      return category;
  }
}

IconData subscriptionCategoryIcon(String category) {
  return subscriptionCategoryIcons[category] ?? Icons.subscriptions;
}

String billingCycleLabel(AppLocalizations l10n, String cycle) {
  switch (cycle) {
    case 'weekly':
      return l10n.billingWeekly;
    case 'yearly':
      return l10n.billingYearly;
    case 'monthly':
    default:
      return l10n.billingMonthly;
  }
}

DateTime nextBillingDateFrom(DateTime startDate, String billingCycle) {
  DateTime safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  switch (billingCycle) {
    case 'weekly':
      return startDate.add(const Duration(days: 7));
    case 'yearly':
      return safeDate(startDate.year + 1, startDate.month, startDate.day);
    case 'monthly':
    default:
      final nextYear = startDate.month == 12 ? startDate.year + 1 : startDate.year;
      final nextMonth = startDate.month == 12 ? 1 : startDate.month + 1;
      return safeDate(nextYear, nextMonth, startDate.day);
  }
}
