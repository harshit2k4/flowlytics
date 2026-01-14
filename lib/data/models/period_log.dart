import 'package:hive/hive.dart';

// run this command to generate part files
// flutter pub run build_runner build --delete-conflicting-outputs
part 'period_log.g.dart';

@HiveType(typeId: 0)
class PeriodLog extends HiveObject {
  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime endDate;

  @HiveField(2)
  int cycleLength; // Do not use 'final' so that it allows historical correction

  PeriodLog({
    required this.startDate,
    required this.endDate,
    this.cycleLength = 0, // Set default to 0 for cleaner filtering
  });
}
