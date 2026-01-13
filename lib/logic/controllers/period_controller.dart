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

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box('settings_box');
    userName.value = _settingsBox.get(
      'user_name',
      defaultValue: "Beautiful Girl",
    );
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
    predictedStartDate.value = PredictionEngine.predictNextStart(allLogs);
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
    refreshData();
  }
}
