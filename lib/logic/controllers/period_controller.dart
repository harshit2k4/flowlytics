import 'package:flowlytics/data/models/daily_log.dart';
import 'package:flowlytics/logic/services/notification_service.dart';
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
      updateCycleReminder();
    }

    // populate mock data (remove before sending to production)
    // injectTestData();
  }

  // Called whenever data changes to recalculate everything
  void refreshData() {
    // If no logs, set default and stop
    if (_logBox.isEmpty) {
      allLogs.clear();
      predictedStartDate.value = DateTime.now().add(const Duration(days: 28));
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

    // Run Math Prediction (Math based algo)
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);
    _baseMathPrediction = PredictionEngine.predictNextStart(allLogs, baseline);

    // Default to math prediction
    predictedStartDate.value = _baseMathPrediction!;

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

    userName.value = "Beautiful Girl";
    isFirstRun.value = true;
    todayLog.value = null;
    isNavigatorActive.value = false;
    navigatorInsight.value = "";

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
    // 1. Delete from Hive
    // Since PeriodLog extends HiveObject, it knows its own key.
    await log.delete();

    // 2. Recalibrate the entire System
    // This will:
    // - Re-fetch the list from Hive (now missing the deleted log)
    // - Re-sort them (just in case)
    // - Re-calculate 'cycleLength' for the remaining logs (fixing gaps)
    // - Re-run PredictionEngine (Math)
    // - Re-run NavigatorEngine (ML Insight)
    refreshData();

    // Now the UI updates automatically via Obx variables
  }

  // Mock data for testing purpose only (remove before applying to production)
  /// Populates the database with a dummy dataset of 12 records.
  /// Designed to test UI pagination (Show More), ML Weighted Mean reliability,
  /// and biological anomaly handling.
  Future<void> injectTestData() async {
    // Purge existing data for a clean test environment
    await _logBox.clear();
    await _dailyBox.clear();

    final DateTime now = DateTime.now();
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    // --- CASE 1-10: THE LONG-TERM HISTORY (PAGINATION & ML STABILITY) ---
    // Create a year's worth of data.
    // Notice the subtle 'Drift': older cycles are 30 days, recent ones are 28.
    // This tests if the ML correctly prioritizes the recent 28-day trend.
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
    // This is the current reference point for the 'Home' screen cycle day.
    await _logBox.add(
      PeriodLog(
        startDate: todayMidnight.subtract(const Duration(days: 26)),
        endDate: todayMidnight.subtract(const Duration(days: 22)),
      ),
    );

    // --- CASE 12: THE "ANOMALY" (DELETION & RE-CALIBRATION TEST) ---
    // An irregular, short cycle (only 10 days since the last one).
    // This will trigger 'Case 12' at the top of the list.
    // TEST: Delete this to see the "Show More" button shift and ML heal.
    await _logBox.add(
      PeriodLog(
        startDate: todayMidnight.subtract(const Duration(days: 10)),
        endDate: todayMidnight.subtract(const Duration(days: 7)),
      ),
    );

    // ML Model trigger
    // Applied 'Spotting' log for today to verify NavigatorEngine overrides.
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

  // scheduling notifications
  void updateCycleReminder() {
    // no notification implementation for non mobile devices
    if (!GetPlatform.isAndroid && !GetPlatform.isIOS) return;

    if (allLogs.isEmpty) {
      // There will be no logs if user skipped date entry in onboarding
      debugPrint("No period logs found. Skipping notification scheduling.");
      return;
    }

    final reminderDate = predictedStartDate.value.subtract(
      const Duration(days: 2),
    );

    // final scheduledTime = DateTime(
    //   reminderDate.year,
    //   reminderDate.month,
    //   reminderDate.day - 2, // remove -2
    //   22, // change to 8
    //   0,
    // );

    // debugPrint("LOG: Notification set for: ${scheduledTime.toString()}");

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
      );
      debugPrint("Notification scheduled for: $scheduledTime");
    }
  }

  // Notification page UI elements
  double get mlConfidence {
    if (allLogs.isEmpty) return 0.0;
    if (allLogs.length == 1) return 0.65; // Initial guess
    if (allLogs.length < 4) return 0.85; // Building patterns
    return 0.96; // High confidence
  }

  String get confidenceStatus {
    if (allLogs.isEmpty) return "CALIBRATING";
    if (allLogs.length < 3) return "LEARNING";
    return "OPTIMIZED";
  }
}
