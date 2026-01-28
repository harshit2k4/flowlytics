import 'dart:math';

import 'package:flowlytics/data/models/daily_log.dart';
import 'package:flowlytics/logic/controllers/security_controller.dart';
import 'package:flowlytics/logic/services/enhanced_navigator_engine.dart';
import 'package:flowlytics/logic/services/enhanced_prediction_engine.dart';
import 'package:flowlytics/logic/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../data/models/period_log.dart';

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

  // ML Observables (New Window & Confidence Logic)
  var navigatorInsight = "".obs;
  var isNavigatorActive = false.obs;

  // Likely Window & Ovulation from new algorithm
  var predictedWindowStart = DateTime.now().obs;
  var predictedWindowEnd = DateTime.now().obs;
  var predictedOvulation = DateTime.now().obs;
  var confidenceScore = 50.obs; // Default to medium confidence

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
      updateCycleReminder();
    }

    // populate mock data (remove before applying to production)
    // injectTestData();

    // load diverse dataset (remove before applying to production)
    // injectElenaTwoYearHistory();

    // load irregular data (remove before applying to production)
    // injectLunaTwoYearIrregular();
  }

  // Called whenever data changes to recalculate everything
  void refreshData() {
    // If no logs, set default and stop
    if (_logBox.isEmpty) {
      allLogs.clear();
      // Default to 28 days for empty state
      final defaultNext = DateTime.now().add(const Duration(days: 28));
      predictedStartDate.value = defaultNext;
      predictedWindowStart.value = defaultNext.subtract(
        const Duration(days: 1),
      );
      predictedWindowEnd.value = defaultNext.add(const Duration(days: 1));
      return;
    }

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

    // Run the new Bio-Intelligent prediction algorithm
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

    // Get the full Schema, not just a date
    final PredictionSchema schema = PredictionEngine.predict(allLogs, baseline);

    _baseMathPrediction = schema.predictedDate;

    // Update Observables from the Schema
    predictedStartDate.value = schema.predictedDate;
    predictedWindowStart.value = schema.windowStart;
    predictedWindowEnd.value = schema.windowEnd;
    predictedOvulation.value = schema.ovulationDate;
    confidenceScore.value = schema.confidenceScore;

    // Trigger Navigator (New algo)
    _runNavigator();

    // schedule reminder
    updateCycleReminder();
  }

  void refreshDailyLog() {
    // Safety Guard: If no period logs, don't try to run navigator logic
    if (_logBox.isEmpty) {
      todayLog.value = null;
      return;
    }

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
      userName: userName.value,
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

    // Set DB flag to false (meaning onboarding is NOT needed anymore)
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

    final securityController = Get.find<SecurityController>();
    await securityController.resetSecurity();

    userName.value = "Beautiful Girl";
    isFirstRun.value = true;
    todayLog.value = null;
    allLogs.clear();
    isNavigatorActive.value = false;
    navigatorInsight.value = "";
    confidenceScore.value = 50; // Reset confidence

    await _settingsBox.put('user_name', "Beautiful Girl");
    await _settingsBox.put('has_completed_onboarding', true);

    refreshData();
    refreshDailyLog();
    Get.offAllNamed('/');
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

  Future<void> deletePeriodLog(PeriodLog log) async {
    await log.delete();
    refreshData();
  }

  // Mock data for testing purpose only (remove before applying to production)
  Future<void> injectTestData() async {
    // Purge existing data for a clean test environment
    await _logBox.clear();
    await _dailyBox.clear();

    final DateTime now = DateTime.now();
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    // --- CASE 1-10: THE LONG-TERM HISTORY (PAGINATION & ML STABILITY) ---
    List<PeriodLog> historicalLogs = [];

    // Generating 10 stable logs moving backwards in time
    for (int i = 10; i >= 1; i--) {
      // Logic: Older cycles (i > 5) are 30 days apart. Recent (i <= 5) are 28.
      int cycleGap = (i > 5) ? 30 : 28;
      int daysAgo = i * cycleGap;

      historicalLogs.add(
        PeriodLog(
          startDate: todayMidnight.subtract(Duration(days: daysAgo + 33)),
          endDate: todayMidnight.subtract(Duration(days: daysAgo + 29)),
        ),
      );
    }

    for (var log in historicalLogs) {
      await _logBox.add(log);
    }

    // --- CASE 11: THE "RECENT STABLE" LOG ---
    await _logBox.add(
      PeriodLog(
        startDate: todayMidnight.subtract(const Duration(days: 26)),
        endDate: todayMidnight.subtract(const Duration(days: 22)),
      ),
    );

    // --- CASE 12: THE "ANOMALY" (DELETION & RE-CALIBRATION TEST) ---
    await _logBox.add(
      PeriodLog(
        startDate: todayMidnight.subtract(const Duration(days: 10)),
        endDate: todayMidnight.subtract(const Duration(days: 7)),
      ),
    );

    // ML Model trigger
    await _dailyBox.add(
      DailyLog(
        date: todayMidnight,
        flow: ["Spotting"],
        moods: ["Sensitive"],
        physical: ["Cramps", "Bloating"],
      ),
    );

    // App configs
    await _settingsBox.put('baseline_cycle', 28);
    await _settingsBox.put('user_name', "Alpha Tester");
    await _settingsBox.put('has_completed_onboarding', false);

    userName.value = "Test Mode"; // test user
    isFirstRun.value = false;

    // Refresh all systems
    refreshData();
    refreshDailyLog();

    debugPrint("Test data loaded");
    debugPrint("Total Logs: ${_logBox.length} (Pagination active)");
  }

  /// Mock data for testing purpose only (remove before applying to production)
  /// This covers most of the normal cases
  Future<void> injectElenaTwoYearHistory() async {
    await _logBox.clear();
    await _dailyBox.clear();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime runner = today.subtract(const Duration(days: 730));

    // 1. History: stable 28-day data leading up to 26 days ago
    for (int i = 0; i < 26; i++) {
      final periodStart = (i == 25)
          ? today.subtract(const Duration(days: 26))
          : runner;

      await _logBox.add(
        PeriodLog(
          startDate: periodStart,
          endDate: periodStart.add(const Duration(days: 5)),
        ),
      );

      if (i > 20) {
        await _dailyBox.add(
          DailyLog(
            date: periodStart.subtract(const Duration(days: 2)),
            moods: ["Sensitive"],
            skin: ["Breakouts"],
          ),
        );
      }
      runner = runner.add(const Duration(days: 28));
    }

    // 2. Today's Mood Log (Triggers -1 day nudge from Jan 29 -> Jan 28)
    await _dailyBox.add(
      DailyLog(date: today, moods: ["Sensitive", "Tired"], skin: ["Breakouts"]),
    );

    // 3. Update Settings and Observables
    await _settingsBox.put('user_name', "Elena");
    await _settingsBox.put('has_completed_onboarding', false);
    userName.value = "Elena";
    isFirstRun.value = false;

    refreshData();
    refreshDailyLog();
  }

  /// This covers irregular periods cases
  Future<void> injectLunaTwoYearIrregular() async {
    await _logBox.clear();
    await _dailyBox.clear();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime runner = today.subtract(const Duration(days: 730));

    // 1. History with Chaos (Triggers lower confidence)
    List<int> chaosGaps = [21, 45, 28, 32, 24, 50, 22, 38, 30, 42];
    int idx = 0;
    while (runner.isBefore(today.subtract(const Duration(days: 30)))) {
      await _logBox.add(
        PeriodLog(
          startDate: runner,
          endDate: runner.add(const Duration(days: 5)),
        ),
      );
      runner = runner.add(Duration(days: chaosGaps[idx % chaosGaps.length]));
      idx++;
    }

    // 2. Today's Safety Log (Cramps on Day 10 should NOT nudge)
    await _dailyBox.add(
      DailyLog(date: today, physical: ["Cramps"], moods: ["Energetic"]),
    );

    // 3. Update Settings and Observables
    await _settingsBox.put('user_name', "Luna");
    await _settingsBox.put('has_completed_onboarding', false);
    userName.value = "Luna";
    isFirstRun.value = false;

    refreshData();
    refreshDailyLog();
  }

  // scheduling notifications
  void updateCycleReminder() {
    if (!GetPlatform.isAndroid && !GetPlatform.isIOS) return;

    if (allLogs.isEmpty) {
      debugPrint("No period logs found. Skipping notification scheduling.");
      return;
    }

    final scheduledTime = DateTime(
      predictedStartDate.value.year,
      predictedStartDate.value.month,
      predictedStartDate.value.day - 2,
      9,
      0,
    );

    debugPrint("LOG: Notification set for: ${scheduledTime.toString()}");

    if (scheduledTime.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: 101,
        title: "Flowlytics Reminder",
        body: "Your period is predicted to start in 2 days.",
        scheduledDate: scheduledTime,
        payload: 'period_reminder',
      );
      debugPrint("Notification scheduled for: $scheduledTime");
    }
  }

  // Notification page UI elements
  // Now uses real Bio-Engine data
  double get mlConfidence => confidenceScore.value / 100.0;

  String get confidenceStatus {
    int score = confidenceScore.value;
    if (score < 50) return "CALIBRATING";
    if (score < 80) return "LEARNING";
    return "OPTIMIZED"; // High confidence (80+)
  }

  // update username in me screen
  void updateUserName(String newName) {
    if (newName.trim().isNotEmpty) {
      userName.value = newName.trim();
      _settingsBox.put('user_name', userName.value);
    }
  }

  // wipe all data (alternative of wipedata())
  Future<void> wipeAllData() async {
    // Clear Biological Data
    await _logBox.clear();
    await _dailyBox.clear();
    allLogs.clear();
    todayLog.value = null;

    // Clear Security Data
    final securityController = Get.find<SecurityController>();
    await securityController.resetSecurity();

    // Reset user info
    userName.value = "Beautiful Girl";
    await _settingsBox.put('user_name', "Beautiful Girl");
    confidenceScore.value = 50;
  }

  // sync data after logs are imported
  void syncImportedData() {
    refreshData(); // Reloads period history and runs predictions
    refreshDailyLog(); // Reloads today's check-in status
    debugPrint("UI Resynced: ${allLogs.length} periods restored.");
  }
}
