import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/todo_provider.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});
  
  static void showAddTodoDialog(BuildContext context, WidgetRef ref, {dynamic todo}) {
    _TodoPageState._showTodoDialogStatic(context, ref, todo: todo);
  }
  
  static void showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除待办'),
          ],
        ),
        content: Text('确定要删除「${todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
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
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  String _selectedCategory = '全部';
  
  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosProvider);
    final categories = ref.watch(todoCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.todoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 18, color: AppTheme.todoColor),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCategory,
                    style: TextStyle(fontSize: 13, color: AppTheme.todoColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '全部', child: Text('全部')),
              ...categories.map((c) => PopupMenuItem(value: c, child: Text(c))),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: todosAsync.when(
        data: (todos) {
          final filteredTodos = _selectedCategory == '全部'
              ? todos
              : todos.where((t) => t.category == _selectedCategory).toList();
          
          final completedCount = filteredTodos.where((t) => t.isCompleted).length;
          final total = filteredTodos.length;
          
          if (filteredTodos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.todoColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline, size: 48, color: AppTheme.todoColor.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '暂无待办事项',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角"+"添加新任务',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // 进度概览
              if (total > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.todoColor,
                        AppTheme.todoColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '今日进度',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount / $total 已完成',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? completedCount / total : 0,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${total > 0 ? (completedCount / total * 100).round() : 0}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return _TodoCard(todo: todo);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.todoColor),
        ),
        error: (e, st) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TodoPage.showAddTodoDialog(context, ref),
        backgroundColor: AppTheme.todoColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加待办', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
  

  
  static void _showTodoDialogStatic(BuildContext context, WidgetRef ref, {dynamic todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: isEditing ? todo.title : '');
    final descController = TextEditingController(text: isEditing ? todo.description : '');
    String selectedCategory = isEditing ? todo.category : 'General';
    DateTime? dueDate = isEditing ? todo.dueDate : null;
    bool isImportant = isEditing ? todo.isImportant : false;
    
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
                  // 顶部拖动条
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
                          color: AppTheme.todoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add_task,
                          color: AppTheme.todoColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? '编辑待办' : '新建待办',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: '任务标题',
                      hintText: '输入任务名称...',
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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '分类',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: ref.read(todoCategoriesProvider)
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => dueDate = date);
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
                            dueDate == null
                                ? '设置截止日期'
                                : '截止：${DateFormat('yyyy年M月d日').format(dueDate!)}',
                            style: TextStyle(
                              color: dueDate == null ? Colors.grey[500] : null,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (dueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => dueDate = null),
                              child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('标记为重要'),
                    subtitle: const Text('重要任务会显示星标', style: TextStyle(fontSize: 12)),
                    secondary: Icon(
                      isImportant ? Icons.star : Icons.star_border,
                      color: isImportant ? Colors.amber : Colors.grey,
                    ),
                    value: isImportant,
                    onChanged: (v) => setState(() => isImportant = v),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        if (isEditing) {
                          ref.read(todoNotifierProvider.notifier).updateTodo(
                            todo.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.isEmpty ? null : descController.text,
                              category: selectedCategory,
                              dueDate: dueDate,
                              isImportant: isImportant,
                            ),
                          );
                        } else {
                          ref.read(todoNotifierProvider.notifier).addTodo(
                            title: titleController.text.trim(),
                            description: descController.text.isEmpty ? null : descController.text,
                            category: selectedCategory,
                            dueDate: dueDate,
                            isImportant: isImportant,
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.todoColor,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEditing ? '保存修改' : '添加任务',
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

class _TodoCard extends ConsumerWidget {
  final dynamic todo;
  
  const _TodoCard({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = todo.dueDate != null && 
                      todo.dueDate!.isBefore(DateTime.now()) && 
                      !todo.isCompleted;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => ref.read(todoNotifierProvider.notifier).toggleComplete(todo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isCompleted ? AppTheme.todoColor : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted ? AppTheme.todoColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    color: todo.isCompleted ? Colors.grey[400] : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (todo.isImportant)
                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  todo.description!,
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
                      color: AppTheme.todoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      todo.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.todoColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (todo.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 11,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('M月d日').format(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? Colors.red : Colors.grey[600],
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
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[500]),
                onPressed: () => TodoPage.showAddTodoDialog(context, ref, todo: todo),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => TodoPage.showDeleteConfirm(context, ref, todo),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
