import '../../data/models/period_log.dart';

class PredictionEngine {
  static DateTime predictNextStart(List<PeriodLog> logs, int baselineCycle) {
    // Normalize "Today" to Midnight to avoid time-zone/hour drifts
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If no logs exist, use the user's specific baseline from onboarding
    if (logs.isEmpty) {
      return today.add(Duration(days: baselineCycle));
    }

    // Sort logs from newest to oldest
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Get cycle lengths, ignore 0 (The first log)
    List<int> validLengths = logs
        .map((l) => l.cycleLength)
        .where((len) => len > 0)
        .toList();

    // Use baselineCycle as the fallback if there is not enough gaps yet
    int predictedGap = _calculateWeightedMean(validLengths, baselineCycle);

    // Calculate prediction from the latest (midnight) start date
    final lastStart = logs.first.startDate;
    final lastStartMidnight = DateTime(
      lastStart.year,
      lastStart.month,
      lastStart.day,
    );

    return lastStartMidnight.add(Duration(days: predictedGap));
  }

  static int _calculateWeightedMean(List<int> lengths, int baseline) {
    // If no valid gaps exist (example: only 1 log available), use the user's baseline
    if (lengths.isEmpty) return baseline;

    List<int> recent = lengths.take(6).toList();
    double totalWeight = 0;
    double weightedSum = 0;

    for (int i = 0; i < recent.length; i++) {
      double weight = 1.0 / (i + 1);
      weightedSum += recent[i] * weight;
      totalWeight += weight;
    }

    return (weightedSum / totalWeight).round();
  }
}
