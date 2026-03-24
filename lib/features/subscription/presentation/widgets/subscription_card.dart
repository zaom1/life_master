import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/presentation/widgets/form_validation_helpers.dart';
import '../providers/subscription_provider.dart';
import 'subscription_dialog.dart';
import 'subscription_meta.dart';

class SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionCard({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDueSoon = subscription.nextBillingDate.difference(DateTime.now()).inDays <= 7;
    final isActive = subscription.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.subscriptionColor : Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              subscriptionCategoryIcon(subscription.category),
              color: isActive ? AppTheme.subscriptionColor : Colors.grey,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  subscription.name,
                  style: TextStyle(
                    color: isActive ? null : Colors.grey[400],
                    decoration: isActive ? null : TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '¥${subscription.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isActive ? AppTheme.subscriptionColor : Colors.grey[400],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isActive ? AppTheme.subscriptionColor : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subscriptionCategoryLabel(l10n, subscription.category),
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? AppTheme.subscriptionColor : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      billingCycleLabel(l10n, subscription.billingCycle),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                  if (isActive && isDueSoon) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 11, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            l10n.badgeDueSoon,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: subscription.isActive,
                activeColor: AppTheme.subscriptionColor,
                onChanged: (v) async {
                  try {
                    await ref.read(subscriptionNotifierProvider.notifier).toggleActive(subscription);
                    if (context.mounted) {
                      showFormSuccess(
                        context,
                        v ? l10n.successSubscriptionEnabled : l10n.successSubscriptionPaused,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showFormError(context, l10n.errorActionFailed(e.toString()));
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => showSubscriptionDialog(context, ref, subscription: subscription),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => showSubscriptionDeleteConfirm(context, ref, subscription),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
