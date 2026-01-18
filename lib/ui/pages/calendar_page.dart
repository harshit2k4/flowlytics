import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import '../../logic/controllers/period_controller.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final PeriodController controller = Get.find<PeriodController>();
  DateTime _focusedDay = DateTime.now();
  // Fetch baseline cycle length from settings for future projections
  final int _baseline = Hive.box(
    'settings_box',
  ).get('baseline_cycle', defaultValue: 28);

  // LOGIC: Display predictions upto 6 months forward
  bool _isPredictedDay(DateTime date) {
    if (controller.predictedStartDate.value.year == 0) return false;

    DateTime firstPredStart = controller.predictedStartDate.value;
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    for (int i = 0; i < 6; i++) {
      DateTime pStart = firstPredStart.add(Duration(days: i * _baseline));
      DateTime pEnd = pStart.add(const Duration(days: 4));

      DateTime s = DateTime(pStart.year, pStart.month, pStart.day);
      DateTime e = DateTime(pEnd.year, pEnd.month, pEnd.day);

      if ((normalizedDate.isAtSameMomentAs(s) || normalizedDate.isAfter(s)) &&
          (normalizedDate.isAtSameMomentAs(e) || normalizedDate.isBefore(e))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CYCLE OVERVIEW",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365 * 5)),
            lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
            focusedDay: _focusedDay,

            // Increase height to prevent weekday text clipping
            daysOfWeekHeight: 32,

            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            calendarStyle: CalendarStyle(
              // Today: Secondary border only
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: false,
            ),

            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),

            onPageChanged: (focusedDay) =>
                setState(() => _focusedDay = focusedDay),

            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                DateTime date = DateTime(day.year, day.month, day.day);

                // Check for Actual Logged Period Days
                bool isActualDay = controller.allLogs.any((log) {
                  DateTime s = DateTime(
                    log.startDate.year,
                    log.startDate.month,
                    log.startDate.day,
                  );
                  DateTime e = DateTime(
                    log.endDate.year,
                    log.endDate.month,
                    log.endDate.day,
                  );
                  return (date.isAtSameMomentAs(s) || date.isAfter(s)) &&
                      (date.isAtSameMomentAs(e) || date.isBefore(e));
                });

                if (isActualDay) {
                  return _buildStatusCircle(
                    context,
                    day,
                    Theme.of(context).colorScheme.errorContainer,
                  );
                }

                // Check for predicted days
                if (_isPredictedDay(date)) {
                  return _buildPredictedGhost(context, day);
                }

                return null;
              },
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // Legend taking full width permitted by divider indents
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 20.0,
            ),
            child: _buildFullWidthPillLegend(context),
          ),

          Divider(
            height: 1,
            thickness: 0.8,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // Highlight for logged period days
  Widget _buildStatusCircle(BuildContext context, DateTime day, Color color) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Lighter color highlight for predictions
  Widget _buildPredictedGhost(BuildContext context, DateTime day) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Legend pill spanning the available width
  Widget _buildFullWidthPillLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity, // Forces the pill to take the full width
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Distribute items equally
        children: [
          _legendItem(
            context,
            "Logged",
            Theme.of(context).colorScheme.errorContainer,
            true,
          ),
          _legendItem(
            context,
            "Predicted",
            Theme.of(context).colorScheme.primary.withOpacity(0.4),
            true,
            isPred: true,
          ),
          _legendItem(
            context,
            "Today",
            Theme.of(context).colorScheme.secondary,
            false,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context,
    String text,
    Color color,
    bool isSolid, {
    bool isPred = false,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSolid ? color : null,
            shape: BoxShape.circle,
            // Today (not solid) shows only the border
            border: !isSolid
                ? Border.all(color: color, width: 2)
                : (isPred ? Border.all(color: color.withOpacity(0.5)) : null),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
