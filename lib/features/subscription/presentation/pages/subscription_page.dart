import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';

// 订阅分类图标映射
final Map<String, IconData> _categoryIcons = {
  'Streaming': Icons.play_circle_outline,
  'Music': Icons.music_note,
  'Gaming': Icons.sports_esports,
  'Productivity': Icons.work_outline,
  'Cloud': Icons.cloud_outlined,
  'News': Icons.newspaper,
  'Fitness': Icons.fitness_center,
  'Other': Icons.more_horiz,
};

// 订阅分类中文映射
final Map<String, String> _categoryLabels = {
  'Streaming': '视频流媒体',
  'Music': '音乐',
  'Gaming': '游戏',
  'Productivity': '效率工具',
  'Cloud': '云存储',
  'News': '新闻资讯',
  'Fitness': '健身',
  'Other': '其他',
};

// 账单周期中文映射
final Map<String, String> _billingCycleLabels = {
  'weekly': '每周',
  'monthly': '每月',
  'yearly': '每年',
};

String _getCategoryLabel(String category) => _categoryLabels[category] ?? category;
IconData _getCategoryIcon(String category) => _categoryIcons[category] ?? Icons.subscriptions;
String _getBillingCycleLabel(String cycle) => _billingCycleLabels[cycle] ?? cycle;

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});
  
  static void showEditSubscriptionDialog(BuildContext context, WidgetRef ref, dynamic subscription) {
    _showSubscriptionDialogStatic(context, ref, subscription: subscription);
  }
  
  static void showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除订阅'),
          ],
        ),
        content: Text('确定要删除「${subscription.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(subscriptionNotifierProvider.notifier).deleteSubscription(subscription.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsProvider);
    final totalMonthly = ref.watch(totalSubscriptionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
      ),
      body: Column(
        children: [
          // 顶部汇总卡片
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.subscriptionColor,
                    AppTheme.subscriptionColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '月度订阅总计',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¥${totalMonthly.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '每月',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.subscriptions, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 列表
          Expanded(
            child: subsAsync.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppTheme.subscriptionColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.subscriptions_outlined,
                            size: 48,
                            color: AppTheme.subscriptionColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '暂无订阅记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击右下角"+"添加订阅服务',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }
                
                final active = subscriptions.where((s) => s.isActive).toList();
                final inactive = subscriptions.where((s) => !s.isActive).toList();
                
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  children: [
                    if (active.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                        child: Text(
                          '活跃订阅 (${active.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      ...active.map((s) => _SubscriptionCard(subscription: s)),
                    ],
                    if (inactive.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(left: 4, top: active.isNotEmpty ? 12 : 4, bottom: 8),
                        child: Text(
                          '已暂停 (${inactive.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      ...inactive.map((s) => _SubscriptionCard(subscription: s)),
                    ],
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: AppTheme.subscriptionColor),
              ),
              error: (e, st) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionDialogInstance(context, ref),
        backgroundColor: AppTheme.subscriptionColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加订阅', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
  
  void _showAddSubscriptionDialogInstance(BuildContext context, WidgetRef ref) {
    _showSubscriptionDialogStatic(context, ref);
  }
  
  static void _showSubscriptionDialogStatic(BuildContext context, WidgetRef ref, {dynamic subscription}) {
    final isEditing = subscription != null;
    final nameController = TextEditingController(text: isEditing ? subscription.name : '');
    final amountController = TextEditingController(text: isEditing ? subscription.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? subscription.description : '');
    String selectedCategory = isEditing ? subscription.category : 'Streaming';
    String billingCycle = isEditing ? subscription.billingCycle : 'monthly';
    DateTime startDate = isEditing ? subscription.startDate : DateTime.now();
    DateTime nextBilling = isEditing ? subscription.nextBillingDate : DateTime.now().add(const Duration(days: 30));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.subscriptionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.add_circle_outline,
                            color: AppTheme.subscriptionColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? '编辑订阅' : '添加订阅',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '订阅名称',
                        hintText: '如：Netflix、Spotify...',
                        prefixIcon: Icon(Icons.subscriptions_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: '金额',
                        hintText: '0.00',
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.subscriptionColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '分类',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: ref.read(subscriptionCategoriesProvider)
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(_getCategoryIcon(c), size: 18, color: AppTheme.subscriptionColor),
                                    const SizedBox(width: 8),
                                    Text(_getCategoryLabel(c)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: billingCycle,
                      decoration: const InputDecoration(
                        labelText: '扣费周期',
                        prefixIcon: Icon(Icons.calendar_view_month),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('每周')),
                        DropdownMenuItem(value: 'monthly', child: Text('每月')),
                        DropdownMenuItem(value: 'yearly', child: Text('每年')),
                      ],
                      onChanged: (v) => setState(() => billingCycle = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: '备注（可选）',
                        hintText: '添加备注...',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            startDate = date;
                            nextBilling = DateTime(date.year, date.month + 1, date.day);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('开始日期', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                Text(
                                  DateFormat('yyyy年M月d日').format(startDate),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (nameController.text.trim().isNotEmpty && amount != null && amount > 0) {
                          if (isEditing) {
                            ref.read(subscriptionNotifierProvider.notifier).updateSubscription(
                              subscription.copyWith(
                                name: nameController.text.trim(),
                                amount: amount,
                                category: selectedCategory,
                                startDate: startDate,
                                nextBillingDate: nextBilling,
                                billingCycle: billingCycle,
                                description: descController.text.isEmpty ? null : descController.text,
                              ),
                            );
                          } else {
                            ref.read(subscriptionNotifierProvider.notifier).addSubscription(
                              name: nameController.text.trim(),
                              amount: amount,
                              category: selectedCategory,
                              startDate: startDate,
                              nextBillingDate: nextBilling,
                              billingCycle: billingCycle,
                              description: descController.text.isEmpty ? null : descController.text,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.subscriptionColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? '保存修改' : '添加订阅',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final dynamic subscription;
  
  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _getCategoryIcon(subscription.category),
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
                      _getCategoryLabel(subscription.category),
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
                      _getBillingCycleLabel(subscription.billingCycle),
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
                            '即将到期',
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
                onChanged: (v) {
                  ref.read(subscriptionNotifierProvider.notifier).toggleActive(subscription);
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => SubscriptionPage.showEditSubscriptionDialog(context, ref, subscription),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => SubscriptionPage.showDeleteConfirm(context, ref, subscription),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
