import '../../data/models/daily_log.dart';
import '../../data/models/period_log.dart';

class PredictionResult {
  final DateTime adjustedDate;
  final String insight;
  final bool isShifted;

  PredictionResult({
    required this.adjustedDate,
    required this.insight,
    required this.isShifted,
  });
}

class NavigatorEngine {
  static PredictionResult analyze({
    required DateTime mathPrediction,
    required DailyLog? todayLog,
    required List<PeriodLog> history,
    required int baselineCycle,
    required String userName,
  }) {
    DateTime adjustedDate = mathPrediction;
    String insight = "";
    bool isShifted = false;

    // A sophisticated greeting
    String name = userName.split(' ').first;
    String greeting = "Hey $name, ";

    if (todayLog == null)
      return PredictionResult(
        adjustedDate: adjustedDate,
        insight: insight,
        isShifted: false,
      );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStart = history.isNotEmpty
        ? DateTime(
            history.first.startDate.year,
            history.first.startDate.month,
            history.first.startDate.day,
          )
        : today.subtract(Duration(days: baselineCycle));

    final dayOfCycle = today.difference(lastStart).inDays + 1;
    final daysUntilMath = mathPrediction.difference(today).inDays;

    // Flow
    if (todayLog.flow.contains("Medium") || todayLog.flow.contains("Heavy")) {
      return PredictionResult(
        adjustedDate: today,
        insight:
            "${greeting}Flowlytics Bio Intelligence has synced your cycle start with today's logged intensity.",
        isShifted: true,
      );
    }

    // Spotting
    if (todayLog.flow.contains("Spotting") &&
        dayOfCycle > (baselineCycle - 10)) {
      if (daysUntilMath > 0) {
        return PredictionResult(
          adjustedDate: today,
          insight:
              "${greeting}Flowlytics Bio Intelligence has updated your start date based on detected spotting signals.",
          isShifted: true,
        );
      }
    }

    // Physical (2-Day Nudge)
    bool hasPmsPain = todayLog.physical.any(
      (s) => ["Cramps", "Backache", "Tender", "Bloating"].contains(s),
    );
    if (hasPmsPain && dayOfCycle > (baselineCycle - 7)) {
      if (daysUntilMath > 2) {
        return PredictionResult(
          adjustedDate: mathPrediction.subtract(const Duration(days: 2)),
          insight:
              "${greeting}Flowlytics Bio Intelligence has adjusted your timeline by 2 days based on physical shifts.",
          isShifted: true,
        );
      }
    }

    // Mood and Skin (1-Day Nudge)
    bool hasPmsSecondary =
        todayLog.moods.any(
          (s) => ["Sensitive", "Anxious", "Tired"].contains(s),
        ) ||
        todayLog.skin.any((s) => ["Breakouts", "Oily"].contains(s));
    if (hasPmsSecondary && dayOfCycle > (baselineCycle - 5)) {
      if (daysUntilMath > 1) {
        return PredictionResult(
          adjustedDate: mathPrediction.subtract(const Duration(days: 1)),
          insight:
              "${greeting}Flowlytics Bio Intelligence has refined your prediction by 1 day based on skin and mood patterns.",
          isShifted: true,
        );
      }
    }

    return PredictionResult(
      adjustedDate: adjustedDate,
      insight: insight,
      isShifted: isShifted,
    );
  }
}
