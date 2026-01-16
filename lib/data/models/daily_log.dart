import 'package:hive/hive.dart';

// run this command to generate part files
// flutter pub run build_runner build --delete-conflicting-outputs
part 'daily_log.g.dart';

@HiveType(typeId: 1)
class DailyLog extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<String> moods;

  @HiveField(2)
  final List<String> physical;

  @HiveField(3)
  final List<String> skin;

  @HiveField(4)
  final List<String> flow;

  @HiveField(5)
  final List<String> sleep;

  DailyLog({
    required this.date,
    this.moods = const [],
    this.physical = const [],
    this.skin = const [],
    this.flow = const [],
    this.sleep = const [],
  });
}
