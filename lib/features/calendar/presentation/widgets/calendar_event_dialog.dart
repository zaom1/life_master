import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/data/database/app_database.dart';
import '../../../../shared/presentation/widgets/delete_confirm_dialog.dart';
import '../../../../shared/presentation/widgets/form_bottom_sheet.dart';
import '../../../../shared/presentation/widgets/form_field_section.dart';
import '../../../../shared/presentation/widgets/form_picker_helpers.dart';
import '../../../../shared/presentation/widgets/form_picker_tile.dart';
import '../../../../shared/presentation/widgets/form_primary_button.dart';
import '../../../../shared/presentation/widgets/form_validation_helpers.dart';
import '../providers/calendar_provider.dart';

void showCalendarEventDeleteConfirm(
  BuildContext context,
  WidgetRef ref,
  CalendarEvent event,
) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toString();
  showDeleteConfirmDialog(
    context,
    title: l10n.dialogDeleteEventTitle,
    message: l10n.dialogDeleteEventMessage(event.title),
    cancelText: l10n.actionCancel,
    confirmText: l10n.actionDelete,
    onConfirm: () async {
      try {
        await ref.read(calendarEventNotifierProvider.notifier).deleteEvent(event.id);
        if (context.mounted) {
          showFormSuccess(context, l10n.successEventDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          showFormError(context, l10n.errorDeleteFailed(e.toString()));
        }
      }
    },
  );
}

void showCalendarEventDialog(
  BuildContext context,
  WidgetRef ref, {
  DateTime? selectedDate,
  CalendarEvent? event,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isEditing = event != null;
  final titleController = TextEditingController(text: isEditing ? event.title : '');
  final descController =
      TextEditingController(text: isEditing ? event.description : '');
  final locationController =
      TextEditingController(text: isEditing ? event.location : '');
  DateTime startTime = isEditing ? event.startTime : (selectedDate ?? DateTime.now());
  DateTime endTime = isEditing ? event.endTime : startTime.add(const Duration(hours: 1));
  bool isAllDay = isEditing ? event.isAllDay : false;
  String selectedColor = isEditing ? event.color : '#059669';
  bool isSubmitting = false;

  final colorOptions = [
    {'color': '#059669'},
    {'color': '#4F46E5'},
    {'color': '#DB2777'},
    {'color': '#D97706'},
    {'color': '#7C3AED'},
    {'color': '#DC2626'},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return FormBottomSheet(
            accentColor: AppTheme.calendarColor,
            icon: isEditing ? Icons.edit : Icons.event,
            title: isEditing ? l10n.dialogEditEvent : l10n.dialogNewEvent,
            children: [
                  FormFieldSection(
                    children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.fieldEventTitle,
                      hintText: l10n.hintEventTitle,
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.fieldDescriptionOptional,
                      hintText: l10n.hintDescriptionDetail,
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldLocationOptional,
                      hintText: l10n.hintLocation,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.labelAllDayEvent),
                    secondary: Icon(
                      Icons.wb_sunny_outlined,
                      color: isAllDay ? AppTheme.calendarColor : Colors.grey,
                    ),
                    value: isAllDay,
                    onChanged: (v) => setState(() => isAllDay = v),
                  ),
                  const SizedBox(height: 12),
                  FormFieldSection(
                    title: l10n.sectionTimeSettings,
                    spacing: 8,
                    children: [
                  FormPickerTile(
                    onTap: () async {
                      if (isAllDay) {
                        final date = await pickDateValue(
                          context: context,
                          initialDate: startTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            startTime = DateTime(date.year, date.month, date.day);
                          });
                        }
                      } else {
                        final selected = await pickDateTimeValue(
                          context: context,
                          initialDateTime: startTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          setState(() {
                            startTime = selected;
                          });
                        }
                      }
                    },
                    icon: Icons.play_circle_outline,
                    iconColor: AppTheme.calendarColor,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.labelStartTime,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        Text(
                          isAllDay
                              ? DateFormat.yMd(localeName).format(startTime)
                              : DateFormat.yMd(localeName).add_Hm().format(startTime),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  if (!isAllDay)
                    FormPickerTile(
                      onTap: () async {
                        final selected = await pickDateTimeValue(
                          context: context,
                          initialDateTime: endTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          setState(() {
                            endTime = selected;
                          });
                        }
                      },
                      icon: Icons.stop_circle_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labelEndTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          Text(
                            DateFormat.yMd(localeName).add_Hm().format(endTime),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FormFieldSection(
                    title: l10n.sectionColorTag,
                    spacing: 8,
                    children: [
                      Row(
                        children: colorOptions.map((opt) {
                          final colorHex = opt['color'] as String;
                          final colorVal =
                              Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
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
                                      ? [
                                          BoxShadow(
                                            color: colorVal.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FormPrimaryButton(
                    label: isEditing ? l10n.actionSaveChanges : l10n.actionAddEvent,
                    color: AppTheme.calendarColor,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (!ensureRequiredText(
                        context,
                        titleController.text,
                        fieldLabel: l10n.fieldEventTitle,
                      )) {
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        if (isEditing) {
                          await ref.read(calendarEventNotifierProvider.notifier).updateEvent(
                                event.copyWith(
                                  title: titleController.text.trim(),
                                  description: descController.text.isEmpty
                                      ? null
                                      : descController.text,
                                  location: locationController.text.isEmpty
                                      ? null
                                      : locationController.text,
                                  startTime: startTime,
                                  endTime: endTime,
                                  isAllDay: isAllDay,
                                  color: selectedColor,
                                ),
                              );
                        } else {
                          await ref.read(calendarEventNotifierProvider.notifier).addEvent(
                                title: titleController.text.trim(),
                                description: descController.text.isEmpty
                                    ? null
                                    : descController.text,
                                location: locationController.text.isEmpty
                                    ? null
                                    : locationController.text,
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                color: selectedColor,
                              );
                        }
                        if (!context.mounted) return;
                        showFormSuccess(
                          context,
                          isEditing ? l10n.successEventUpdated : l10n.successEventAdded,
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          showFormError(context, l10n.errorSaveFailed(e.toString()));
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      );
    },
  );
}
