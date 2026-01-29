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
    required DateTime mathPrediction, // From the new prediction logic
    required DailyLog? todayLog,
    required List<PeriodLog> history,
    required int baselineCycle, // Keep for fallback, but rely on mathPrediction
    required String userName,
  }) {
    DateTime adjustedDate = mathPrediction;

    // Use first name for personalized feel
    String name = userName.trim().isEmpty || userName == "Beautiful Girl"
        ? "Beautiful"
        : userName.split(' ').first;

    String greeting = "Hey $name, ";

    if (todayLog == null) {
      return PredictionResult(
        adjustedDate: adjustedDate,
        insight: "",
        isShifted: false,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate "Days Away" from the mathematical prediction
    // Negative = We are past the predicted date
    // Positive = The period is in the future
    final daysUntilPredicted = mathPrediction.difference(today).inDays;

    // // Flow deciding algorithm (Immediate Override)
    // if (todayLog.flow.contains("Medium") || todayLog.flow.contains("Heavy")) {
    //   return PredictionResult(
    //     adjustedDate: today,
    //     insight:
    //         "${greeting}Flowlytics has synced your start date with today's log.",
    //     isShifted: true,
    //   );
    // }

    // // Spotting deciding algorithm (Luteal Safe)
    // // Rule: Only consider spotting if the user is within 5 days of the predicted date
    // // This prevents "Ovulation Spotting" (Day 14) from triggering a Period Start
    // bool isSpotting = todayLog.flow.contains("Spotting");
    // if (isSpotting && daysUntilPredicted <= 5 && daysUntilPredicted >= -2) {
    //   return PredictionResult(
    //     adjustedDate: today,
    //     insight:
    //         "${greeting}Flowlytics detected early signals and updated your start date.",
    //     isShifted: true,
    //   );
    // }

    // // Physical symptoms deciding algorithm (2-Day Shift)
    // // If the user feels "Cramps" or "Bloating" AND is very close to the date (within 4 days)
    // bool hasPmsPain = todayLog.physical.any(
    //   (s) => ["Cramps", "Backache", "Bloating"].contains(s),
    // );

    // if (hasPmsPain && daysUntilPredicted <= 4 && daysUntilPredicted > 0) {
    //   // Check if we haven't already shifted it to today
    //   if (adjustedDate.isAfter(today)) {
    //     return PredictionResult(
    //       adjustedDate: mathPrediction.subtract(const Duration(days: 2)),
    //       insight:
    //           "${greeting}your physical symptoms suggest your cycle might arrive 2 days earlier.",
    //       isShifted: true,
    //     );
    //   }
    // }

    // // Mood/Skin deciding algorithm (1-Day Nudge)
    // // These are softer signals, so we check them further out (within 6 days)
    // bool hasPmsSecondary =
    //     todayLog.moods.any(
    //       (s) => ["Sensitive", "Anxious", "Tired"].contains(s),
    //     ) ||
    //     todayLog.skin.any((s) => ["Breakouts", "Oily"].contains(s));

    // // if (hasPmsSecondary && daysUntilPredicted <= 6 && daysUntilPredicted > 1) {
    // if (hasPmsSecondary && daysUntilPredicted <= 6 && daysUntilPredicted > 0) {
    //   return PredictionResult(
    //     adjustedDate: mathPrediction.subtract(const Duration(days: 1)),
    //     insight:
    //         "${greeting}skin and mood patterns suggest your cycle is approaching.",
    //     isShifted: true,
    //   );
    // }

    // // Default: No Change
    // return PredictionResult(
    //   adjustedDate: adjustedDate,
    //   insight: "",
    //   isShifted: false,
    // );
    // --- 1. FLOW & SPOTTING (Immediate 100% Override) ---
    // If there is actual flow OR spotting, the period starts TODAY regardless of math.
    bool hasStarted =
        todayLog.flow.contains("Medium") ||
        todayLog.flow.contains("Heavy") ||
        todayLog.physical.contains("Spotting");

    if (hasStarted) {
      return PredictionResult(
        adjustedDate: today,
        insight:
            "${greeting}your symptoms indicate your cycle has started today.",
        isShifted: true,
      );
    }

    // --- 2. PHYSICAL PAIN (2-Day Shift) ---
    bool hasPmsPain = todayLog.physical.any(
      (s) => ["Cramps", "Backache", "Bloating"].contains(s),
    );

    // Logic: If within window (4 days) OR overdue (daysUntilPredicted < 0)
    if (hasPmsPain && (daysUntilPredicted <= 4)) {
      if (adjustedDate.isAfter(today)) {
        return PredictionResult(
          adjustedDate: mathPrediction.subtract(const Duration(days: 2)),
          insight:
              "${greeting}your physical symptoms suggest your cycle might arrive 2 days earlier.",
          isShifted: true,
        );
      }
    }

    // Mood or Skin status (1-Day Adjustment)
    bool hasPmsSecondary =
        todayLog.moods.any(
          (s) => ["Sensitive", "Anxious", "Tired"].contains(s),
        ) ||
        todayLog.skin.any((s) => ["Breakouts", "Oily"].contains(s));

    if (hasPmsSecondary && daysUntilPredicted <= 6 && daysUntilPredicted >= 0) {
      return PredictionResult(
        adjustedDate: mathPrediction.subtract(const Duration(days: 1)),
        insight:
            "${greeting}skin and mood patterns suggest your cycle is approaching.",
        isShifted: true,
      );
    }

    return PredictionResult(
      adjustedDate: adjustedDate,
      insight: "",
      isShifted: false,
    );
  }
}
