import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showFormError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showFormSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

bool ensureRequiredText(
  BuildContext context,
  String value, {
  required String fieldLabel,
}) {
  if (value.trim().isNotEmpty) {
    return true;
  }

  final l10n = AppLocalizations.of(context)!;
  showFormError(context, l10n.errorRequiredField(fieldLabel));
  return false;
}

double? ensurePositiveAmount(
  BuildContext context,
  String value, {
  String fieldLabel = 'amount',
}) {
  final amount = double.tryParse(value.trim());
  if (amount != null && amount > 0) {
    return amount;
  }

  final l10n = AppLocalizations.of(context)!;
  showFormError(context, l10n.errorAmountMustBePositive(fieldLabel));
  return null;
}
