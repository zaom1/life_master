import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String todoCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'General':
      return l10n.todoCategoryGeneral;
    case 'Work':
      return l10n.todoCategoryWork;
    case 'Personal':
      return l10n.todoCategoryPersonal;
    case 'Health':
      return l10n.todoCategoryHealth;
    case 'Shopping':
      return l10n.todoCategoryShopping;
    case 'Finance':
      return l10n.todoCategoryFinance;
    default:
      return category;
  }
}
