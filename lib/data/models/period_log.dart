import 'package:hive/hive.dart';

// Generate 'period_log.g.dart' file by executing this command
// flutter pub run build_runner build --delete-conflicting-outputs

part 'period_log.g.dart';

@HiveType(typeId: 0) // Hive uses IDs to find data
class PeriodLog extends HiveObject {
  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime endDate;

  @HiveField(2)
  final int cycleLength; // Days between this and the previous period

  PeriodLog({
    required this.startDate,
    required this.endDate,
    this.cycleLength = 28, // Default standard
  });
}
