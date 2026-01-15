import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../data/models/period_log.dart';
import '../services/prediction_engine.dart';

enum PeriodStatus { wellness, preparation, active }

class PeriodController extends GetxController {
  final Box<PeriodLog> _logBox = Hive.box<PeriodLog>('period_box');
  late Box _settingsBox;

  var allLogs = <PeriodLog>[].obs;
  var predictedStartDate = DateTime.now().obs;
  var userName = "Beautiful Girl".obs;

  // check if its the first time app is launched
  var isFirstRun = true.obs;

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box('settings_box');

    // Check if onboarding was ever completed
    isFirstRun.value = _settingsBox.get(
      'has_completed_onboarding',
      defaultValue: true,
    );

    userName.value = _settingsBox.get(
      'user_name',
      defaultValue: "Beautiful Girl",
    );
    refreshData();
  }

  /// Onboarding screen check
  Future<void> completeOnboarding({
    required String name,
    required DateTimeRange? lastPeriod,
    required int usualCycle,
  }) async {
    // Save profile data
    await _settingsBox.put('user_name', name);
    userName.value = name;

    // Save the baseline cycle for ML
    await _settingsBox.put('baseline_cycle', usualCycle);

    // Save the initial period log if provided
    if (lastPeriod != null) {
      final newLog = PeriodLog(
        startDate: lastPeriod.start,
        endDate: lastPeriod.end,
        cycleLength: 0,
      );
      await _logBox.add(newLog);
    }

    // close db box
    await _settingsBox.put('has_completed_onboarding', false);
    isFirstRun.value = false;

    refreshData();
  }

  // PeriodStatus get currentStatus {
  //   final now = DateTime(
  //     DateTime.now().year,
  //     DateTime.now().month,
  //     DateTime.now().day,
  //   );

  //   // Check active period (Inclusive check)
  //   if (allLogs.isNotEmpty) {
  //     final last = allLogs.first;
  //     final start = DateTime(
  //       last.startDate.year,
  //       last.startDate.month,
  //       last.startDate.day,
  //     );
  //     final end = DateTime(
  //       last.endDate.year,
  //       last.endDate.month,
  //       last.endDate.day,
  //     );

  //     if (!now.isBefore(start) && !now.isAfter(end)) {
  //       return PeriodStatus.active;
  //     }
  //   }

  //   // check preparation window
  //   final pred = predictedStartDate.value;
  //   final predictionDate = DateTime(pred.year, pred.month, pred.day);
  //   final daysUntil = predictionDate.difference(now).inDays;

  //   if (daysUntil >= 0 && daysUntil <= 3) {
  //     return PeriodStatus.preparation;
  //   }

  //   return PeriodStatus.wellness;
  // }

  PeriodStatus get currentStatus {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Check active period
    if (allLogs.isNotEmpty) {
      final last = allLogs.first;
      final start = DateTime(
        last.startDate.year,
        last.startDate.month,
        last.startDate.day,
      );
      final end = DateTime(
        last.endDate.year,
        last.endDate.month,
        last.endDate.day,
      );

      if (!now.isBefore(start) && !now.isAfter(end)) {
        return PeriodStatus.active;
      }
    }

    // check preparation/overdue window
    final pred = predictedStartDate.value;
    final predictionDate = DateTime(pred.year, pred.month, pred.day);
    final daysUntil = predictionDate.difference(now).inDays;

    // FIX: Change 'daysUntil >= 0' to 'daysUntil <= 3'
    // If it's 3, 2, 1, 0, or -5 (overdue), it should show 'Preparation chips'
    if (daysUntil <= 3) {
      return PeriodStatus.preparation;
    }

    return PeriodStatus.wellness;
  }

  bool get isNearPeriod => currentStatus != PeriodStatus.wellness;

  void refreshData() {
    var logs = _logBox.values.toList();
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Healing Engine: Recalculate all gaps
    for (int i = 0; i < logs.length; i++) {
      if (i < logs.length - 1) {
        int gap = logs[i].startDate.difference(logs[i + 1].startDate).inDays;
        if (logs[i].cycleLength != gap) {
          logs[i].cycleLength = gap;
          logs[i].save();
        }
      } else if (logs[i].cycleLength != 0) {
        logs[i].cycleLength = 0;
        logs[i].save();
      }
    }

    allLogs.assignAll(logs);

    // Pass the baseline cycle to the engine if it exists
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);
    predictedStartDate.value = PredictionEngine.predictNextStart(
      allLogs,
      baseline,
    );
  }

  Future<void> savePeriod(DateTime start, DateTime end) async {
    final newLog = PeriodLog(startDate: start, endDate: end, cycleLength: 0);
    await _logBox.add(newLog);
    refreshData();
  }

  void updateName(String name) {
    userName.value = name;
    _settingsBox.put('user_name', name);
  }

  Future<void> wipeData() async {
    await _logBox.clear();
    await _settingsBox.clear();
    userName.value = "Beautiful Girl";
    isFirstRun.value = true; // Resets gate on wipe
    refreshData();
  }

  // Calculate current biological phase based on cycle day and baseline
  String get currentPhase {
    if (allLogs.isEmpty) return "Calibrating";

    // If period is active, always show Menstrual Phase
    if (currentStatus == PeriodStatus.active) return "Menstrual Phase";

    // Normalize dates to midnight to get precise day count
    final lastStart = allLogs.first.startDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(lastStart.year, lastStart.month, lastStart.day);

    // Day 1 is the start date
    final dayOfCycle = today.difference(startDay).inDays + 1;

    // Scale phases based on baseline cycle (default is 28)
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

    // Standard biological mapping scaled to user cycle length
    if (dayOfCycle <= 5) {
      return "Menstrual Phase";
    } else if (dayOfCycle <= (baseline / 2).round() - 2) {
      return "Follicular Phase";
    } else if (dayOfCycle <= (baseline / 2).round() + 2) {
      return "Ovulatory Phase";
    } else {
      return "Luteal Phase";
    }
  }
}
