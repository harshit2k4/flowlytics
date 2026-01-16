import 'package:flowlytics/data/models/daily_log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../data/models/period_log.dart';
import '../services/prediction_engine.dart';
import '../services/navigator_engine.dart'; // Import the new Brain

enum PeriodStatus { wellness, preparation, active }

class PeriodController extends GetxController {
  final Box<PeriodLog> _logBox = Hive.box<PeriodLog>('period_box');
  late Box _settingsBox;
  final Box<DailyLog> _dailyBox = Hive.box<DailyLog>('daily_box');

  // Observables
  var todayLog = Rxn<DailyLog>();
  var allLogs = <PeriodLog>[].obs;
  var predictedStartDate = DateTime.now().obs;
  var userName = "Beautiful Girl".obs;
  var isFirstRun = true.obs;

  // ML Observables (New)
  var navigatorInsight = "".obs;
  var isNavigatorActive = false.obs;

  // Private store for the raw math prediction
  DateTime? _baseMathPrediction;

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box('settings_box');

    isFirstRun.value = _settingsBox.get(
      'has_completed_onboarding',
      defaultValue: true,
    );
    userName.value = _settingsBox.get(
      'user_name',
      defaultValue: "Beautiful Girl",
    );

    // Whenever userName changes, run _runNavigator
    ever(userName, (_) => _runNavigator());

    // Only run logic if onboarding is completed
    if (!isFirstRun.value) {
      refreshData();
      refreshDailyLog();
    }
  }

  // Called whenever data changes to recalculate everything
  void refreshData() {
    // Sort and heal history
    var logs = _logBox.values.toList();
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

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

    // Run Math Prediction (Math based algo)
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);
    _baseMathPrediction = PredictionEngine.predictNextStart(allLogs, baseline);

    // Default to math prediction
    predictedStartDate.value = _baseMathPrediction!;

    // Trigger Navigator (New algo)
    _runNavigator();
  }

  void refreshDailyLog() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      todayLog.value = _dailyBox.values.firstWhere(
        (log) =>
            log.date.year == today.year &&
            log.date.month == today.month &&
            log.date.day == today.day,
      );
    } catch (_) {
      todayLog.value = null;
    }

    // Whenever we load a daily log, check if it changes the prediction
    _runNavigator();
  }

  // Bridge between controller and ML engine
  void _runNavigator() {
    if (_baseMathPrediction == null) return;

    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

    final result = NavigatorEngine.analyze(
      mathPrediction: _baseMathPrediction!,
      todayLog: todayLog.value,
      history: allLogs,
      baselineCycle: baseline,
      userName: userName.value, // name goes here
    );

    predictedStartDate.value = result.adjustedDate;
    navigatorInsight.value = result.insight;
    isNavigatorActive.value = result.isShifted;
  }

  Future<void> completeOnboarding({
    required String name,
    required DateTimeRange? lastPeriod,
    required int usualCycle,
  }) async {
    await _settingsBox.put('user_name', name);
    userName.value = name;
    await _settingsBox.put('baseline_cycle', usualCycle);

    if (lastPeriod != null) {
      final newLog = PeriodLog(
        startDate: lastPeriod.start,
        endDate: lastPeriod.end,
        cycleLength: 0,
      );
      await _logBox.add(newLog);
    }

    await _settingsBox.put('has_completed_onboarding', false);
    isFirstRun.value = false;

    // run full engine
    refreshData();
    refreshDailyLog();
  }

  Future<void> savePeriod(DateTime start, DateTime end) async {
    final newLog = PeriodLog(startDate: start, endDate: end, cycleLength: 0);
    await _logBox.add(newLog);
    refreshData();
  }

  Future<void> saveDailyCheckIn({
    required List<String> selectedMoods,
    required List<String> selectedPhysical,
    required List<String> selectedSkin,
    required List<String> selectedFlow,
    required List<String> selectedSleep,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final newLog = DailyLog(
      date: today,
      moods: selectedMoods,
      physical: selectedPhysical,
      skin: selectedSkin,
      flow: selectedFlow,
      sleep: selectedSleep,
    );

    if (todayLog.value != null) {
      await todayLog.value!.delete();
    }

    await _dailyBox.add(newLog);
    refreshDailyLog();
  }

  Future<void> wipeData() async {
    await _logBox.clear();
    await _settingsBox.clear();
    await _dailyBox.clear();

    userName.value = "Beautiful Girl";
    isFirstRun.value = true;
    todayLog.value = null;
    isNavigatorActive.value = false;
    navigatorInsight.value = "";

    refreshData();
    refreshDailyLog();
  }

  void updateName(String name) {
    userName.value = name;
    _settingsBox.put('user_name', name);

    // Re-run the navigator so the insight string picks up the new name immediately
    _runNavigator();
  }

  // UI Logic
  PeriodStatus get currentStatus {
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

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

    final pred = predictedStartDate.value;
    final predictionDate = DateTime(pred.year, pred.month, pred.day);
    final daysUntil = predictionDate.difference(now).inDays;

    if (daysUntil <= 3) {
      return PeriodStatus.preparation;
    }

    return PeriodStatus.wellness;
  }

  bool get isNearPeriod => currentStatus != PeriodStatus.wellness;

  String get currentPhase {
    if (allLogs.isEmpty) return "Calibrating";
    if (currentStatus == PeriodStatus.active) return "Menstrual Phase";

    final lastStart = allLogs.first.startDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(lastStart.year, lastStart.month, lastStart.day);

    final dayOfCycle = today.difference(startDay).inDays + 1;
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

    if (dayOfCycle <= 5)
      return "Menstrual Phase";
    else if (dayOfCycle <= (baseline / 2).round() - 2)
      return "Follicular Phase";
    else if (dayOfCycle <= (baseline / 2).round() + 2)
      return "Ovulatory Phase";
    else
      return "Luteal Phase";
  }
}
