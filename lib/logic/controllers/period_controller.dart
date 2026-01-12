import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../data/models/period_log.dart';
import '../services/prediction_engine.dart';

class PeriodController extends GetxController {
  // Access the box opened in main.dart
  final Box<PeriodLog> _box = Hive.box<PeriodLog>('period_box');

  // Observable list of logs - the UI will track this
  var allLogs = <PeriodLog>[].obs;

  // Observable prediction - the UI will track this too
  var predictedStartDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  // Pull data from Hive and ask the Engine to calculate
  void refreshData() {
    // Get all logs from database
    allLogs.assignAll(_box.values.toList());

    // Sort them so newest is first
    allLogs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Ask the Engine: "Based on these logs, when is the next one?"
    predictedStartDate.value = PredictionEngine.predictNextStart(allLogs);
  }

  // Add a new period
  Future<void> savePeriod(DateTime start, DateTime end) async {
    int calculatedCycle = 28;

    if (allLogs.isNotEmpty) {
      // Calculate the gap between current new start and the previous start
      calculatedCycle = start.difference(allLogs.first.startDate).inDays;
    }

    final newLog = PeriodLog(
      startDate: start,
      endDate: end,
      cycleLength: calculatedCycle,
    );

    await _box.add(newLog); // Save to disk
    refreshData(); // Update the UI immediately
  }
}
