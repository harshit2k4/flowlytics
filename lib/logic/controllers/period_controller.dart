import 'dart:math';
import 'package:flowlytics/data/models/daily_log.dart';
import 'package:flowlytics/logic/controllers/security_controller.dart';
import 'package:flowlytics/logic/services/enhanced_navigator_engine.dart';
import 'package:flowlytics/logic/services/enhanced_prediction_engine.dart';
import 'package:flowlytics/logic/services/notification_service.dart';
import 'package:flowlytics/ui/nav_wrapper.dart';
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

  // ML Observables
  var navigatorInsight = "".obs;
  var isNavigatorActive = false.obs;

  // Prediction Windows
  var predictedWindowStart = DateTime.now().obs;
  var predictedWindowEnd = DateTime.now().obs;
  var predictedOvulation = DateTime.now().obs;
  var confidenceScore = 50.obs;
  var averageCycleLength = 28.obs;

  // Private store for raw math
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

    ever(userName, (_) => _runNavigator());

    if (!isFirstRun.value) {
      refreshData();
      refreshDailyLog();
      updateCycleReminder();
    }

    // injectElenaFullYear();
    // injectLunaFullYear();
  }

  // Called whenever data changes to recalculate everything
  void refreshData() {
    if (_logBox.isEmpty) {
      allLogs.clear();
      final defaultNext = DateTime.now().add(const Duration(days: 28));
      predictedStartDate.value = defaultNext;
      predictedWindowStart.value = defaultNext.subtract(
        const Duration(days: 1),
      );
      predictedWindowEnd.value = defaultNext.add(const Duration(days: 1));
      averageCycleLength.value = 28;
      return;
    }

    var logs = _logBox.values.toList();
    // Sort Newest First
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Re-calculate gaps and save them so the charts can see them
    for (int i = 0; i < logs.length; i++) {
      int calculatedGap = 0;
      if (i < logs.length - 1) {
        // Gap between this period and the one before it
        calculatedGap = logs[i].startDate
            .difference(logs[i + 1].startDate)
            .inDays;
      }

      // Only save if the data actually changed to optimize performance
      if (logs[i].cycleLength != calculatedGap) {
        logs[i].cycleLength = calculatedGap;
        logs[i].save();
      }
    }

    allLogs.assignAll(logs);

    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);
    final schema = PredictionEngine.predict(allLogs, baseline);

    predictedStartDate.value = schema.predictedDate;
    predictedWindowStart.value = schema.windowStart;
    predictedWindowEnd.value = schema.windowEnd;
    predictedOvulation.value = schema.ovulationDate;
    confidenceScore.value = schema.confidenceScore;
    averageCycleLength.value = schema.averageCycleLength;

    _baseMathPrediction = schema.predictedDate;
    _runNavigator();

    updateCycleReminder();
  }

  void refreshDailyLog() {
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
    _runNavigator();
  }

  // Bridge between controller and ML engine
  // void _runNavigator() {
  //   if (_baseMathPrediction == null) return;

  //   final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

  //   final result = NavigatorEngine.analyze(
  //     mathPrediction: _baseMathPrediction!,
  //     todayLog: todayLog.value,
  //     history: allLogs,
  //     baselineCycle: baseline,
  //     userName: userName.value,
  //   );

  //   predictedStartDate.value = result.adjustedDate;
  //   navigatorInsight.value = result.insight;
  //   isNavigatorActive.value = result.isShifted;
  // }

  // void _runNavigator() {
  //   // Use predictedStartDate as a fallback to ensure it always runs
  //   final DateTime mathBase = _baseMathPrediction ?? predictedStartDate.value;

  //   final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

  //   final result = NavigatorEngine.analyze(
  //     mathPrediction: mathBase,
  //     todayLog: todayLog.value, // This is crucial - it must be reactive
  //     history: allLogs,
  //     baselineCycle: baseline,
  //     userName: userName.value,
  //   );

  //   // Apply the Bio-Intelligence results to the observables
  //   predictedStartDate.value = result.adjustedDate;
  //   navigatorInsight.value = result.insight;
  //   isNavigatorActive.value = result.isShifted;

  //   // STRICT LOG: This helps you debug in the console
  //   debugPrint(
  //     "Navigator Active: ${result.isShifted} | Insight: ${result.insight}",
  //   );
  // }

  void _runNavigator() {
    final DateTime mathBase = _baseMathPrediction ?? predictedStartDate.value;
    final int baseline = _settingsBox.get('baseline_cycle', defaultValue: 28);

    final result = NavigatorEngine.analyze(
      mathPrediction: mathBase,
      todayLog: todayLog.value,
      history: allLogs,
      baselineCycle: baseline,
      userName: userName.value,
    );

    debugPrint("------------------------------------------");
    debugPrint("🤖 BIO-ENGINE AUDIT: ${userName.value}");
    debugPrint("📅 Math Prediction: ${mathBase.toString().split(' ').first}");
    debugPrint(
      "🎯 Navigator Result: ${result.adjustedDate.toString().split(' ').first}",
    );
    debugPrint("⚡ Shifted Active: ${result.isShifted}");
    if (result.isShifted) debugPrint("📝 Insight: ${result.insight}");
    debugPrint("------------------------------------------");

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
    // For manual save, we default cycleLength to 0 until the next log
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
      final last = allLogs.first; // Since we sort Newest First
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

    if (daysUntil <= 3 && daysUntil >= 0) {
      return PeriodStatus.preparation;
    }
    return PeriodStatus.wellness;
  }

  bool get isNearPeriod => currentStatus != PeriodStatus.wellness;

  String get currentPhase {
    if (allLogs.isEmpty) return "Calibrating";
    if (currentStatus == PeriodStatus.active) return "Menstrual Phase";

    final lastStart = allLogs.first.startDate; // Newest log
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

  Future<void> injectElenaFullYear() async {
    await wipeAllData();

    // 1. Force state to "Not First Run" so main.dart shows NavWrapper
    await _settingsBox.put('has_completed_onboarding', false);
    isFirstRun.value = false;

    await _settingsBox.put('user_name', "Elena");
    userName.value = "Elena";

    final DateTime today = DateTime(2026, 1, 28);
    DateTime runner = DateTime(2026, 1, 1);

    // 2. Inject logs with cycleLength for the Charts
    for (int i = 0; i < 13; i++) {
      await _logBox.add(
        PeriodLog(
          startDate: runner,
          endDate: runner.add(const Duration(days: 5)),
          cycleLength: 28,
        ),
      );
      runner = runner.subtract(const Duration(days: 28));
    }

    final elenaSymptoms = DailyLog(
      date: today,
      moods: ["Sensitive", "Tired"],
      skin: ["Breakouts"],
    );
    await _dailyBox.put('2026-01-28', elenaSymptoms);

    todayLog.value = elenaSymptoms;
    refreshData();

    debugPrint("✅ Elena Injection Complete.");

    // Navigate directly to the Widget to avoid Route generator error
    Get.offAll(() => const NavWrapper());
  }

  Future<void> injectLunaFullYear() async {
    await wipeAllData();

    await _settingsBox.put('has_completed_onboarding', false);
    isFirstRun.value = false;

    await _settingsBox.put('user_name', "Luna");
    userName.value = "Luna";

    final DateTime today = DateTime(2026, 1, 28);
    DateTime runner = DateTime(2025, 12, 25);
    List<int> chaoticGaps = [
      35,
      24,
      42,
      28,
      31,
      39,
      22,
      45,
      30,
      29,
      36,
      33,
      28,
    ];

    for (int i = 0; i < 13; i++) {
      int gap = chaoticGaps[i];
      await _logBox.add(
        PeriodLog(
          startDate: runner,
          endDate: runner.add(const Duration(days: 5)),
          cycleLength: gap,
        ),
      );
      runner = runner.subtract(Duration(days: gap));
    }

    final lunaSymptoms = DailyLog(
      date: today,
      physical: ["Spotting", "Cramps"],
    );
    await _dailyBox.put('2026-01-28', lunaSymptoms);

    todayLog.value = lunaSymptoms;
    refreshData();

    debugPrint("✅ Luna Injection Complete.");

    // Navigate directly to the Widget to avoid Route generator error
    Get.offAll(() => const NavWrapper());
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
    return "OPTIMIZED";
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
    await _logBox.clear();
    await _dailyBox.clear();
    allLogs.clear();
    todayLog.value = null;

    // Reset User
    await _settingsBox.put('user_name', "Beautiful Girl");
    confidenceScore.value = 50;

    // Security reset if needed
    try {
      final securityController = Get.find<SecurityController>();
      await securityController.resetSecurity();
    } catch (_) {}
  }

  // sync data after logs are imported
  void syncImportedData() {
    refreshData(); // Reloads period history and runs predictions
    refreshDailyLog(); // Reloads today's check-in status
    debugPrint("UI Resynced: ${allLogs.length} periods restored.");
  }
}
