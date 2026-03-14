import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../providers/expense_provider.dart';

// 支出分类图标映射
final Map<String, IconData> _categoryIcons = {
  'Food': Icons.restaurant,
  'Transport': Icons.directions_car,
  'Shopping': Icons.shopping_bag,
  'Entertainment': Icons.movie,
  'Health': Icons.local_hospital,
  'Education': Icons.school,
  'Housing': Icons.home,
  'Other': Icons.more_horiz,
};

// 支出分类中文映射
final Map<String, String> _categoryLabels = {
  'Food': '餐饮',
  'Transport': '交通',
  'Shopping': '购物',
  'Entertainment': '娱乐',
  'Health': '医疗',
  'Education': '教育',
  'Housing': '住房',
  'Other': '其他',
};

String _getCategoryLabel(String category) {
  return _categoryLabels[category] ?? category;
}

IconData _getCategoryIcon(String category) {
  return _categoryIcons[category] ?? Icons.receipt;
}

class ExpensePage extends ConsumerWidget {
  const ExpensePage({super.key});
  
  static void showEditExpenseDialog(BuildContext context, WidgetRef ref, dynamic expense) {
    _showExpenseDialogStatic(context, ref, expense: expense);
  }
  
  static void showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除支出'),
          ],
        ),
        content: const Text('确定要删除这条支出记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
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
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('支出记录'),
      ),
      body: Column(
        children: [
          // 顶部汇总卡片
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: '本月支出',
                    amount: monthlyExpense,
                    icon: Icons.calendar_month,
                    color: AppTheme.expenseColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: '累计支出',
                    amount: totalExpense,
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索分类或描述...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(expenseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(expenseSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          // 图表
          const ExpenseChart(),
          // 列表
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: AppTheme.expenseColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '暂无支出记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击右下角"+"添加支出',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }
                
                final sortedExpenses = List<Expense>.from(expenses)
                  ..sort((a, b) => b.date.compareTo(a.date));
                
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: sortedExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = sortedExpenses[index];
                    return _ExpenseCard(expense: expense);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: AppTheme.expenseColor),
              ),
              error: (e, st) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialogInstance(context, ref),
        backgroundColor: AppTheme.expenseColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加支出', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
  
  void _showAddExpenseDialogInstance(BuildContext context, WidgetRef ref) {
    _showExpenseDialogStatic(context, ref);
  }
  
  static void _showExpenseDialogStatic(BuildContext context, WidgetRef ref, {dynamic expense}) {
    final isEditing = expense != null;
    final amountController = TextEditingController(text: isEditing ? expense.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? expense.description : '');
    final paymentController = TextEditingController(text: isEditing ? expense.paymentMethod : '');
    String selectedCategory = isEditing ? expense.category : 'Food';
    DateTime selectedDate = isEditing ? expense.date : DateTime.now();
    
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
                            color: AppTheme.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.add_circle_outline,
                            color: AppTheme.expenseColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? '编辑支出' : '记录支出',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: '金额',
                        hintText: '0.00',
                        prefixText: '¥ ',
                        prefixStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.expenseColor,
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
                      items: ref.read(expenseCategoriesProvider)
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(_getCategoryIcon(c), size: 18, color: AppTheme.expenseColor),
                                    const SizedBox(width: 8),
                                    Text(_getCategoryLabel(c)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: '备注（可选）',
                        hintText: '添加备注说明...',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paymentController,
                      decoration: const InputDecoration(
                        labelText: '支付方式（可选）',
                        hintText: '如：微信、支付宝、现金...',
                        prefixIcon: Icon(Icons.payment),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
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
                            Text(
                              DateFormat('yyyy年M月d日').format(selectedDate),
                              style: const TextStyle(fontSize: 16),
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
                        if (amount != null && amount > 0) {
                          if (isEditing) {
                            ref.read(expenseNotifierProvider.notifier).updateExpense(
                              expense.copyWith(
                                amount: amount,
                                category: selectedCategory,
                                description: descController.text.isEmpty ? null : descController.text,
                                date: selectedDate,
                                paymentMethod: paymentController.text.isEmpty ? null : paymentController.text,
                              ),
                            );
                          } else {
                            ref.read(expenseNotifierProvider.notifier).addExpense(
                              amount: amount,
                              category: selectedCategory,
                              description: descController.text.isEmpty ? null : descController.text,
                              date: selectedDate,
                              paymentMethod: paymentController.text.isEmpty ? null : paymentController.text,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.expenseColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? '保存修改' : '记录支出',
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final dynamic expense;
  
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.expenseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: AppTheme.expenseColor,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Text(
                '¥${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.expenseColor,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('M月d日').format(expense.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.expenseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getCategoryLabel(expense.category),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.expenseColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (expense.paymentMethod != null && expense.paymentMethod!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment, size: 11, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(
                            expense.paymentMethod!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (expense.description != null && expense.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  expense.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => ExpensePage.showEditExpenseDialog(context, ref, expense),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => ExpensePage.showDeleteConfirm(context, ref, expense),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseChart extends ConsumerWidget {
  const ExpenseChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    
    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) return const SizedBox.shrink();
        
        final now = DateTime.now();
        final monthlyData = <int, double>{};
        final monthLabels = <int, String>{};
        
        for (int i = 5; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthExpenses = expenses
              .where((e) => e.date.year == month.year && e.date.month == month.month)
              .fold(0.0, (sum, e) => sum + e.amount);
          final idx = 6 - i - 1;
          monthlyData[idx] = monthExpenses;
          monthLabels[idx] = '${month.month}月';
        }
        
        final maxAmount = monthlyData.values.reduce((a, b) => a > b ? a : b);
        
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, size: 18, color: AppTheme.expenseColor),
                    const SizedBox(width: 6),
                    const Text(
                      '近6个月趋势',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxAmount > 0 ? maxAmount * 1.3 : 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  monthLabels[idx] ?? '',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: monthlyData.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.expenseColor,
                                  AppTheme.expenseColor.withOpacity(0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
