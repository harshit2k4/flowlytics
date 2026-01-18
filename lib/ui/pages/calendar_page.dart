import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../logic/controllers/period_controller.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final PeriodController controller = Get.find<PeriodController>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final int _baseline = Hive.box(
    'settings_box',
  ).get('baseline_cycle', defaultValue: 28);

  int _displayLimit = 10;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  bool _isPredictedDay(DateTime date) {
    if (controller.predictedStartDate.value.year == 0) return false;
    for (int i = 0; i < 6; i++) {
      DateTime pStart = controller.predictedStartDate.value.add(
        Duration(days: i * _baseline),
      );
      DateTime pEnd = pStart.add(const Duration(days: 4));
      if (_isDateInRange(date, pStart, pEnd)) return true;
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
      body: Obx(() {
        final allLogs = controller.allLogs.reversed.toList();
        final displayedLogs = allLogs.take(_displayLimit).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ),
                lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                daysOfWeekHeight: 32,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
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
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  selectedTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  prioritizedBuilder: (context, day, focusedDay) {
                    bool isActual = controller.allLogs.any(
                      (log) => _isDateInRange(day, log.startDate, log.endDate),
                    );
                    if (isActual)
                      return _buildStatusCircle(
                        context,
                        day,
                        Theme.of(context).colorScheme.errorContainer,
                      );
                    if (_isPredictedDay(day))
                      return _buildPredictedGhost(context, day);
                    return null;
                  },
                ),
              ),

              const Divider(
                height: 1,
                thickness: 0.8,
                indent: 20,
                endIndent: 20,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: _buildFullWidthPillLegend(context),
              ),

              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 4),
                  child: Text(
                    "Predictions are based on mathematics and logic.\nReal biology may vary.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(
                height: 1,
                thickness: 0.8,
                indent: 20,
                endIndent: 20,
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyInsightCard(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    const Text(
                      "RECORDED PERIODS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Swipe left to remove",
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (allLogs.isEmpty)
                      _buildEmptyState()
                    else ...[
                      ...displayedLogs
                          .map((log) => _buildDismissibleRangeItem(log))
                          .toList(),

                      if (allLogs.length > _displayLimit)
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _displayLimit += 10),
                            child: Text(
                              "Show More",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            "Nothing here yet",
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInsightCard() {
    bool isActual = controller.allLogs.any(
      (log) => _isDateInRange(_selectedDay!, log.startDate, log.endDate),
    );
    bool isPredicted = _isPredictedDay(_selectedDay!);

    String title = isActual
        ? "Period Day"
        : isPredicted
        ? "Predicted Window"
        : "Regular Day";
    String desc = isActual
        ? "Flow recorded for this date."
        : isPredicted
        ? "Expect your cycle to begin soon."
        : "No flow recorded.";
    Color color = isActual
        ? Theme.of(context).colorScheme.error
        : isPredicted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    IconData icon = isActual
        ? Icons.water_drop
        : isPredicted
        ? Icons.auto_awesome
        : Icons.calendar_today;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM dd').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleRangeItem(dynamic log) {
    return Dismissible(
      key: Key(log.startDate.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Delete Record?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("Remove this range from history?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  "DELETE",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (direction) async {
        // delete the selected cycle
        await controller.deletePeriodLog(log);
        // Simplified snackbar with glassmorphic design
        Get.rawSnackbar(
          messageText: Center(
            child: Text(
              "Record Removed",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.fromLTRB(
            60,
            40,
            60,
            0,
          ), // More compact horizontally
          borderRadius: 30,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.errorContainer.withOpacity(0.4),
          duration: const Duration(milliseconds: 1500), // Faster duration
          barBlur: 15,
          padding: const EdgeInsets.symmetric(vertical: 10),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${DateFormat('MMM dd').format(log.startDate)} — ${DateFormat('MMM dd, yyyy').format(log.endDate)}",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            Icon(
              Icons.chevron_left,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthPillLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            Theme.of(context).colorScheme.primary.withOpacity(0.6),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isSolid ? color : null,
            shape: BoxShape.circle,
            border: !isSolid
                ? Border.all(color: color, width: 2.0)
                : (isPred ? Border.all(color: color.withOpacity(0.8)) : null),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusCircle(BuildContext context, DateTime day, Color color) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '${day.day}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // UI for predicted date in calendar
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
}
