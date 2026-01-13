import '../../data/models/period_log.dart';

class PredictionEngine {
  static const int _defaultCycleLength = 28;

  static DateTime predictNextStart(List<PeriodLog> logs) {
    // Normalize "Today" to Midnight to avoid time-zone/hour drifts
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (logs.isEmpty) {
      return today.add(const Duration(days: _defaultCycleLength));
    }

    // Sort logs Newest -> Oldest
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Get cycle lengths, ignore 0 (The first log) to get only real calculated gaps
    List<int> validLengths = logs
        .map((l) => l.cycleLength)
        .where((len) => len > 0)
        .toList();

    int predictedGap = _calculateWeightedMean(validLengths);

    // Calculate prediction from the latest (midnight) start Date
    final lastStart = logs.first.startDate;
    final lastStartMidnight = DateTime(
      lastStart.year,
      lastStart.month,
      lastStart.day,
    );

    return lastStartMidnight.add(Duration(days: predictedGap));
  }

  static int _calculateWeightedMean(List<int> lengths) {
    // If no valid gaps exist (e.g. only 1 log ever), use 28 days
    if (lengths.isEmpty) return _defaultCycleLength;

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
