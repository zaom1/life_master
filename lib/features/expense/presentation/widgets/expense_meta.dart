import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Map<String, IconData> categoryIcons = {
  'Food': Icons.restaurant,
  'Transport': Icons.directions_car,
  'Shopping': Icons.shopping_bag,
  'Entertainment': Icons.movie,
  'Health': Icons.local_hospital,
  'Education': Icons.school,
  'Housing': Icons.home,
  'Utilities': Icons.bolt,
  'Other': Icons.more_horiz,
};

String expenseCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Food':
      return l10n.expenseCategoryFood;
    case 'Transport':
      return l10n.expenseCategoryTransport;
    case 'Shopping':
      return l10n.expenseCategoryShopping;
    case 'Entertainment':
      return l10n.expenseCategoryEntertainment;
    case 'Health':
      return l10n.expenseCategoryHealth;
    case 'Education':
      return l10n.expenseCategoryEducation;
    case 'Housing':
      return l10n.expenseCategoryHousing;
    case 'Utilities':
      return l10n.expenseCategoryUtilities;
    case 'Other':
      return l10n.expenseCategoryOther;
    default:
      return category;
  }
}

IconData expenseCategoryIcon(String category) {
  return categoryIcons[category] ?? Icons.receipt;
}
