import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../logic/controllers/period_controller.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();

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
            // Range: 5 years past to 5 years future
            firstDay: DateTime.now().subtract(const Duration(days: 365 * 5)),
            lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
            focusedDay: DateTime.now(),

            // Material 3 style header
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

            // Calendar grid style
            calendarStyle: CalendarStyle(
              // Today's Date highlight
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
              // Style for weekend text
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.error.withOpacity(0.6),
              ),
              outsideDaysVisible: false, // Only show days of current month
            ),

            // Weekday header label
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
          ),
          // Separator
          const Divider(indent: 20, endIndent: 20),
        ],
      ),
    );
  }
}
