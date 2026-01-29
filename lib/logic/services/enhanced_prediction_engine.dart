import 'dart:math';
import '../../data/models/period_log.dart';

class PredictionSchema {
  final DateTime predictedDate;
  final DateTime windowStart; // -Sigma
  final DateTime windowEnd; // +Sigma
  final DateTime ovulationDate;
  final int confidenceScore; // 1-100 based on regularity
  final int averageCycleLength;

  PredictionSchema({
    required this.predictedDate,
    required this.windowStart,
    required this.windowEnd,
    required this.ovulationDate,
    required this.confidenceScore,
    required this.averageCycleLength,
  });
}

class PredictionEngine {
  /// Main Engine: Returns not just a date, but a full cycle schema
  static PredictionSchema predict(List<PeriodLog> logs, int baselineCycle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (logs.isEmpty) {
      DateTime next = today.add(Duration(days: baselineCycle));
      return PredictionSchema(
        predictedDate: next,
        windowStart: next.subtract(const Duration(days: 1)),
        windowEnd: next.add(const Duration(days: 1)),
        ovulationDate: next.subtract(const Duration(days: 14)),
        confidenceScore: 50,
        averageCycleLength: baselineCycle,
      );
    }

    // Sort Newest to Oldest
    List<PeriodLog> sortedLogs = List.from(logs);
    sortedLogs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Dynamically calculate cycle lengths
    List<int> calculatedLengths = [];
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      int diff = sortedLogs[i].startDate
          .difference(sortedLogs[i + 1].startDate)
          .inDays;
      // Filter outliers
      if (diff >= 15 && diff <= 50) {
        calculatedLengths.add(diff);
      }
    }

    // Fallback if no valid lengths found
    int calculatedAvg = calculatedLengths.isEmpty
        ? baselineCycle
        : _calculateWeightedMean(calculatedLengths, baselineCycle);

    double deviation = calculatedLengths.isEmpty
        ? 1.5
        : _calculateStandardDeviation(calculatedLengths, calculatedAvg);

    int windowDays = deviation.round().clamp(1, 4);

    // 4. Generate dates based on the MOST RECENT log
    final lastStart = sortedLogs.first.startDate;
    final lastStartMidnight = DateTime(
      lastStart.year,
      lastStart.month,
      lastStart.day,
    );

    DateTime predicted = lastStartMidnight.add(Duration(days: calculatedAvg));
    DateTime ovulation = predicted.subtract(const Duration(days: 14));

    return PredictionSchema(
      predictedDate: predicted,
      windowStart: predicted.subtract(Duration(days: windowDays)),
      windowEnd: predicted.add(Duration(days: windowDays)),
      ovulationDate: ovulation,
      confidenceScore: _calculateConfidence(
        deviation,
        calculatedLengths.length,
      ),
      averageCycleLength: calculatedAvg,
    );
  }

  static int _calculateWeightedMean(List<int> lengths, int baseline) {
    if (lengths.isEmpty) return baseline;

    // Take up to 6 recent cycles
    // Core logic: Cycle 1 (Newest) gets more weight than Cycle 6
    List<int> recent = lengths.take(6).toList();
    double totalWeight = 0;
    double weightedSum = 0;

    for (int i = 0; i < recent.length; i++) {
      // Weight decreases: 1.0, 0.8, 0.6...
      double weight = 1.0 - (i * 0.1);
      if (weight < 0.1) weight = 0.1;

      weightedSum += recent[i] * weight;
      totalWeight += weight;
    }

    return (weightedSum / totalWeight).round();
  }

  static double _calculateStandardDeviation(List<int> lengths, int mean) {
    // Default deviation for low data
    if (lengths.length < 2) return 1.5;

    double sumSquaredDiffs = 0;
    for (var len in lengths) {
      sumSquaredDiffs += pow(len - mean, 2);
    }

    return sqrt(sumSquaredDiffs / lengths.length);
  }

  static int _calculateConfidence(double deviation, int count) {
    if (count < 3) return 40; // Calibrating

    if (deviation < 1.0) return 95; // Extremely stable (Elena)
    if (deviation < 2.0) return 85; // Very stable
    if (deviation < 4.0) return 65; // Moderate/Irregular (Luna)
    if (deviation < 7.0) return 45; // Highly irregular
    return 30; // Chaos
  }
}
