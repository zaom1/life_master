import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/reminder_provider.dart';

class ReminderPage extends ConsumerWidget {
  const ReminderPage({super.key});
  
  static void showAddReminderDialog(BuildContext context, WidgetRef ref, {dynamic reminder}) {
    _showReminderDialogStatic(context, ref, reminder: reminder);
  }
  
  static void showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除提醒'),
          ],
        ),
        content: Text('确定要删除「${reminder.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(reminderNotifierProvider.notifier).deleteReminder(reminder.id);
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
    final remindersAsync = ref.watch(remindersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('提醒事项'),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.reminderColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: AppTheme.reminderColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '暂无提醒事项',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角"+"添加新提醒',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }
          
          // 分组：未完成 + 已完成
          final activeReminders = reminders.where((r) => !r.isCompleted).toList();
          final doneReminders = reminders.where((r) => r.isCompleted).toList();
          
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              if (activeReminders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    '待处理 (${activeReminders.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ...activeReminders.map((r) => _ReminderCard(reminder: r)),
              ],
              if (doneReminders.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.only(left: 4, top: activeReminders.isNotEmpty ? 12 : 0, bottom: 8),
                  child: Text(
                    '已完成 (${doneReminders.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                ...doneReminders.map((r) => _ReminderCard(reminder: r)),
              ],
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.reminderColor),
        ),
        error: (e, st) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialogInstance(context, ref),
        backgroundColor: AppTheme.reminderColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加提醒', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
  
  void _showAddReminderDialogInstance(BuildContext context, WidgetRef ref) {
    _showReminderDialogStatic(context, ref);
  }
  
  static void _showReminderDialogStatic(BuildContext context, WidgetRef ref, {dynamic reminder}) {
    final isEditing = reminder != null;
    final titleController = TextEditingController(text: isEditing ? reminder.title : '');
    final descController = TextEditingController(text: isEditing ? reminder.description : '');
    DateTime selectedDateTime = isEditing ? reminder.remindTime : DateTime.now().add(const Duration(hours: 1));
    bool isRepeating = isEditing ? reminder.isRepeating : false;
    String repeatType = isEditing ? reminder.repeatType : 'none';
    
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
                          color: AppTheme.reminderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add_alarm,
                          color: AppTheme.reminderColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? '编辑提醒' : '新建提醒',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '提醒标题',
                      hintText: '输入提醒名称...',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '备注说明（可选）',
                      hintText: '添加详细说明...',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year, date.month, date.day, time.hour, time.minute,
                            );
                          });
                        }
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
                          Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('yyyy年M月d日 HH:mm').format(selectedDateTime),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('重复提醒'),
                    secondary: Icon(
                      Icons.repeat,
                      color: isRepeating ? AppTheme.reminderColor : Colors.grey,
                    ),
                    value: isRepeating,
                    onChanged: (v) => setState(() => isRepeating = v),
                  ),
                  if (isRepeating) ...[
                    DropdownButtonFormField<String>(
                      value: repeatType == 'none' ? 'daily' : repeatType,
                      decoration: const InputDecoration(
                        labelText: '重复频率',
                        prefixIcon: Icon(Icons.calendar_view_week),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('每天')),
                        DropdownMenuItem(value: 'weekly', child: Text('每周')),
                        DropdownMenuItem(value: 'monthly', child: Text('每月')),
                      ],
                      onChanged: (v) => setState(() => repeatType = v!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        if (isEditing) {
                          ref.read(reminderNotifierProvider.notifier).updateReminder(
                            reminder.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.isEmpty ? null : descController.text,
                              remindTime: selectedDateTime,
                              isRepeating: isRepeating,
                              repeatType: repeatType,
                            ),
                          );
                        } else {
                          ref.read(reminderNotifierProvider.notifier).addReminder(
                            title: titleController.text.trim(),
                            description: descController.text.isEmpty ? null : descController.text,
                            remindTime: selectedDateTime,
                            isRepeating: isRepeating,
                            repeatType: repeatType,
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.reminderColor,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEditing ? '保存修改' : '添加提醒',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final dynamic reminder;
  
  const _ReminderCard({required this.reminder});

  String _getRepeatLabel(String type) {
    switch (type) {
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = reminder.remindTime.isBefore(DateTime.now()) && !reminder.isCompleted;
    final accentColor = isOverdue ? Colors.red : AppTheme.reminderColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => ref.read(reminderNotifierProvider.notifier).toggleComplete(reminder),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reminder.isCompleted ? AppTheme.reminderColor : Colors.transparent,
                border: Border.all(
                  color: reminder.isCompleted
                      ? AppTheme.reminderColor
                      : (isOverdue ? Colors.red : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: reminder.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted
                  ? Colors.grey[400]
                  : (isOverdue ? Colors.red[700] : null),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminder.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  reminder.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 11, color: accentColor),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('M月d日 HH:mm').format(reminder.remindTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reminder.isRepeating) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.reminderColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 11, color: AppTheme.reminderColor),
                          const SizedBox(width: 3),
                          Text(
                            _getRepeatLabel(reminder.repeatType),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.reminderColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '已过期',
                        style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
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
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => ReminderPage.showAddReminderDialog(context, ref, reminder: reminder),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => ReminderPage.showDeleteConfirm(context, ref, reminder),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
