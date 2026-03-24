import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_event_dialog.dart';
import '../widgets/calendar_month_view.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageCalendarTitle),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
            },
            icon: const Icon(Icons.today, size: 18),
            label: Text(l10n.labelToday),
            style: TextButton.styleFrom(foregroundColor: AppTheme.calendarColor),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final calendarHeight = constraints.maxHeight * 0.42;

          return Column(
            children: [
              SizedBox(
                height: calendarHeight,
                child: CalendarMonthView(
                  selectedDate: selectedDate,
                  eventsAsync: eventsAsync,
                ),
              ),
              const Divider(height: 1),
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
                      DateFormat.MMMEd(localeName).format(selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: eventsAsync.when(
                  data: (events) {
                    final dayEvents = events
                        .where(
                          (e) =>
                              e.startTime.year == selectedDate.year &&
                              e.startTime.month == selectedDate.month &&
                              e.startTime.day == selectedDate.day,
                        )
                        .toList();

                    if (dayEvents.isEmpty) {
                      return _CalendarEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        return CalendarEventCard(event: dayEvents[index]);
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: AppTheme.calendarColor),
                  ),
                  error: (e, st) =>
                      Center(child: Text(l10n.errorLoadFailed(e.toString()))),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCalendarEventDialog(
          context,
          ref,
          selectedDate: selectedDate,
        ),
        backgroundColor: AppTheme.calendarColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.actionAddEvent,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.calendarNoEventsToday,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
