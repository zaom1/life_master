import 'package:flutter/material.dart';
import 'package:lifemaster/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../providers/calendar_provider.dart';

DateTime _shiftMonthClamped(DateTime date, int deltaMonths) {
  final targetMonth = DateTime(date.year, date.month + deltaMonths, 1);
  final lastDayOfTargetMonth =
      DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final clampedDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;
  return DateTime(targetMonth.year, targetMonth.month, clampedDay);
}

class CalendarMonthView extends ConsumerWidget {
  final DateTime selectedDate;
  final AsyncValue<List<CalendarEvent>> eventsAsync;

  const CalendarMonthView({
    super.key,
    required this.selectedDate,
    required this.eventsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeName = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      _shiftMonthClamped(selectedDate, -1);
                },
              ),
              Text(
                DateFormat.yMMMM(localeName).format(
                  DateTime(selectedDate.year, selectedDate.month, 1),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      _shiftMonthClamped(selectedDate, 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const _WeekDayRow(),
          const SizedBox(height: 4),
          Expanded(
            child: _CalendarGrid(selectedDate: selectedDate, eventsAsync: eventsAsync),
          ),
        ],
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  const _WeekDayRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
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
  final AsyncValue<List<CalendarEvent>> eventsAsync;

  const _CalendarGrid({required this.selectedDate, required this.eventsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    final eventDays = <int>{};
    if (eventsAsync.hasValue) {
      for (final event in eventsAsync.value!) {
        if (event.startTime.year == selectedDate.year &&
            event.startTime.month == selectedDate.month) {
          eventDays.add(event.startTime.day);
        }
      }
    }

    final totalCells = firstWeekday - 1 + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - (firstWeekday - 1);
        if (dayOffset < 1 || dayOffset > daysInMonth) {
          return const SizedBox();
        }

        final day = dayOffset;
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final isSelected = date.day == selectedDate.day &&
            date.month == selectedDate.month &&
            date.year == selectedDate.year;
        final now = DateTime.now();
        final isToday =
            date.day == now.day && date.month == now.month && date.year == now.year;
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
                    fontWeight:
                        isToday || isSelected ? FontWeight.bold : FontWeight.normal,
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
