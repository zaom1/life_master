import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/calendar_provider.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});
  
  static void showEditEventDialog(BuildContext context, WidgetRef ref, dynamic event) {
    _showEventDialogStatic(context, ref, event: event);
  }
  
  static void showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('删除日程'),
          ],
        ),
        content: Text('确定要删除「${event.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(calendarEventNotifierProvider.notifier).deleteEvent(event.id);
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
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
            },
            icon: const Icon(Icons.today, size: 18),
            label: const Text('今天'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.calendarColor,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 计算日历可用高度 (约屏幕一半)
          final calendarHeight = constraints.maxHeight * 0.42;
          
          return Column(
            children: [
              // 日历头部 - 固定高度
              SizedBox(
                height: calendarHeight,
                child: _CalendarView(
                  selectedDate: selectedDate,
                  eventsAsync: eventsAsync,
                ),
              ),
              const Divider(height: 1),
              // 选中日期标题
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.calendarColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('M月d日 EEEE', 'zh_CN').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 事件列表 - 自动填充剩余空间
              Expanded(
                child: eventsAsync.when(
                  data: (events) {
                    final dayEvents = events.where((e) =>
                      e.startTime.year == selectedDate.year &&
                      e.startTime.month == selectedDate.month &&
                      e.startTime.day == selectedDate.day
                    ).toList();
                    
                    if (dayEvents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.calendarColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available,
                                size: 32,
                                color: AppTheme.calendarColor.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '今天没有日程',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        return _EventCard(event: dayEvents[index]);
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: AppTheme.calendarColor),
                  ),
                  error: (e, st) => Center(child: Text('加载失败: $e')),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialogInstance(context, ref, selectedDate),
        backgroundColor: AppTheme.calendarColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加日程', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
  
  void _showAddEventDialogInstance(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    _showEventDialogStatic(context, ref, selectedDate: selectedDate);
  }
  
  static void _showEventDialogStatic(BuildContext context, WidgetRef ref, {DateTime? selectedDate, dynamic event}) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: isEditing ? event.title : '');
    final descController = TextEditingController(text: isEditing ? event.description : '');
    final locationController = TextEditingController(text: isEditing ? event.location : '');
    DateTime startTime = isEditing ? event.startTime : (selectedDate ?? DateTime.now());
    DateTime endTime = isEditing ? event.endTime : startTime.add(const Duration(hours: 1));
    bool isAllDay = isEditing ? event.isAllDay : false;
    String selectedColor = isEditing ? event.color : '#059669';
    
    final colorOptions = [
      {'color': '#059669', 'label': '绿色'},
      {'color': '#4F46E5', 'label': '蓝色'},
      {'color': '#DB2777', 'label': '粉色'},
      {'color': '#D97706', 'label': '橙色'},
      {'color': '#7C3AED', 'label': '紫色'},
      {'color': '#DC2626', 'label': '红色'},
    ];
    
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
                            color: AppTheme.calendarColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.event,
                            color: AppTheme.calendarColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? '编辑日程' : '新建日程',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '日程标题',
                        hintText: '输入日程名称...',
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
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: '地点（可选）',
                        hintText: '添加地点...',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('全天日程'),
                      secondary: Icon(
                        Icons.wb_sunny_outlined,
                        color: isAllDay ? AppTheme.calendarColor : Colors.grey,
                      ),
                      value: isAllDay,
                      onChanged: (v) => setState(() => isAllDay = v),
                    ),
                    // 开始时间
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null && context.mounted) {
                          if (!isAllDay) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startTime),
                            );
                            if (time != null) {
                              setState(() => startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                            }
                          } else {
                            setState(() => startTime = DateTime(date.year, date.month, date.day));
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
                            Icon(Icons.play_circle_outline, size: 20, color: AppTheme.calendarColor),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('开始时间', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                Text(
                                  isAllDay
                                      ? DateFormat('yyyy年M月d日').format(startTime)
                                      : DateFormat('yyyy年M月d日 HH:mm').format(startTime),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isAllDay) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endTime,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endTime),
                            );
                            if (time != null) {
                              setState(() => endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
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
                              Icon(Icons.stop_circle_outlined, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('结束时间', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  Text(
                                    DateFormat('yyyy年M月d日 HH:mm').format(endTime),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 颜色选择
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('颜色标签', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Row(
                          children: colorOptions.map((opt) {
                            final colorHex = opt['color'] as String;
                            final colorVal = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                            final isSelected = selectedColor == colorHex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () => setState(() => selectedColor = colorHex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colorVal,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: colorVal, width: 3)
                                        : null,
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: colorVal.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          if (isEditing) {
                            ref.read(calendarEventNotifierProvider.notifier).updateEvent(
                              event.copyWith(
                                title: titleController.text.trim(),
                                description: descController.text.isEmpty ? null : descController.text,
                                location: locationController.text.isEmpty ? null : locationController.text,
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                color: selectedColor,
                              ),
                            );
                          } else {
                            ref.read(calendarEventNotifierProvider.notifier).addEvent(
                              title: titleController.text.trim(),
                              description: descController.text.isEmpty ? null : descController.text,
                              location: locationController.text.isEmpty ? null : locationController.text,
                              startTime: startTime,
                              endTime: endTime,
                              isAllDay: isAllDay,
                              color: selectedColor,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.calendarColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? '保存修改' : '添加日程',
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

// 合并后的日历视图（包含月份选择、星期和日期网格）
class _CalendarView extends ConsumerWidget {
  final DateTime selectedDate;
  final AsyncValue eventsAsync;
  
  const _CalendarView({required this.selectedDate, required this.eventsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // 月份选择
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = DateTime(
                    selectedDate.year, selectedDate.month - 1, selectedDate.day,
                  );
                },
              ),
              Text(
                DateFormat('yyyy年 M月').format(selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = DateTime(
                    selectedDate.year, selectedDate.month + 1, selectedDate.day,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 星期行
          _WeekDayRow(),
          const SizedBox(height: 4),
          // 日期网格 - 自适应填充
          Expanded(
            child: _CalendarGrid(selectedDate: selectedDate, eventsAsync: eventsAsync),
          ),
        ],
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      children: days.asMap().entries.map((entry) {
        final isWeekend = entry.key >= 5;
        return Expanded(
          child: Center(
            child: Text(
              entry.value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isWeekend ? Colors.red[400] : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarGrid extends ConsumerWidget {
  final DateTime selectedDate;
  final AsyncValue eventsAsync;
  
  const _CalendarGrid({required this.selectedDate, required this.eventsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    
    // 获取有事件的日期
    final eventDays = <int>{};
    if (eventsAsync.hasValue) {
      for (final event in eventsAsync.value!) {
        if (event.startTime.year == selectedDate.year &&
            event.startTime.month == selectedDate.month) {
          eventDays.add(event.startTime.day);
        }
      }
    }
    
    // 计算行数
    final totalCells = firstWeekday - 1 + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    
    // 使用 GridView.builder 自适应父容器高度
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        
        // 空白格子或超出当月天数
        if (dayOffset < 1 || dayOffset > daysInMonth) {
          return const SizedBox();
        }
        
        final day = dayOffset;
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final isSelected = date.day == selectedDate.day && 
                           date.month == selectedDate.month && 
                           date.year == selectedDate.year;
        final isToday = date.day == DateTime.now().day && 
                        date.month == DateTime.now().month && 
                        date.year == DateTime.now().year;
        final hasEvent = eventDays.contains(day);
        final isWeekend = date.weekday >= 6;
        
        return InkWell(
          onTap: () {
            ref.read(selectedDateProvider.notifier).state = date;
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.calendarColor
                  : (isToday ? AppTheme.calendarColor.withOpacity(0.12) : null),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? AppTheme.calendarColor
                            : (isWeekend ? Colors.red[400] : Colors.black87)),
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (hasEvent)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppTheme.calendarColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventCard extends ConsumerWidget {
  final dynamic event;
  
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventColor = Color(int.parse(event.color.replaceFirst('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event, color: eventColor, size: 22),
          ),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  event.description!,
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
                      color: eventColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 11, color: eventColor),
                        const SizedBox(width: 3),
                        Text(
                          event.isAllDay
                              ? '全天'
                              : '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: eventColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
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
                          Icon(Icons.location_on, size: 11, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(
                            event.location!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                onPressed: () => CalendarPage.showEditEventDialog(context, ref, event),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[400]),
                onPressed: () => CalendarPage.showDeleteConfirm(context, ref, event),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
