import 'dart:math';
import '../../data/models/period_log.dart';

class PredictionSchema {
  final DateTime predictedDate;
  final DateTime windowStart; // -Sigma
  final DateTime windowEnd; // +Sigma
  final DateTime ovulationDate;
  final int confidenceScore; // 1-100 based on regularity

  PredictionSchema({
    required this.predictedDate,
    required this.windowStart,
    required this.windowEnd,
    required this.ovulationDate,
    required this.confidenceScore,
  });
}

class PredictionEngine {
  /// Main Engine: Returns not just a date, but a full cycle schema
  static PredictionSchema predict(List<PeriodLog> logs, int baselineCycle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If the user is a new user then use manual baseline
    if (logs.isEmpty) {
      DateTime next = today.add(Duration(days: baselineCycle));
      return PredictionSchema(
        predictedDate: next,
        windowStart: next.subtract(const Duration(days: 1)),
        windowEnd: next.add(const Duration(days: 1)),
        ovulationDate: next.subtract(const Duration(days: 14)),
        confidenceScore: 50, // Moderate confidence for new users
      );
    }

    // Sort & Extract Data
    logs.sort((a, b) => b.startDate.compareTo(a.startDate));

    // FILTER: Exclude "Ghost" cycles (0 days) or extreme outliers (<15 or >50 days)
    // capable of ruining the average
    List<int> validLengths = logs
        .map((l) => l.cycleLength)
        .where((len) => len >= 21 && len <= 45)
        .toList();

    // The Core Prediction -> Calculate Weighted Mean
    int calculatedAvg = _calculateWeightedMean(validLengths, baselineCycle);

    // Adjustment System -> Calculate Standard Deviation
    double deviation = _calculateStandardDeviation(validLengths, calculatedAvg);
    // Min 1 day, Max 4 days window
    int windowDays = deviation.round().clamp(1, 4);

    // Generate dates
    final lastStart = logs.first.startDate;
    final lastStartMidnight = DateTime(
      lastStart.year,
      lastStart.month,
      lastStart.day,
    );

    DateTime predicted = lastStartMidnight.add(Duration(days: calculatedAvg));

    // Ovulation is typically 14 days before the next period
    DateTime ovulation = predicted.subtract(const Duration(days: 14));

    return PredictionSchema(
      predictedDate: predicted,
      windowStart: predicted.subtract(Duration(days: windowDays)),
      windowEnd: predicted.add(Duration(days: windowDays)),
      ovulationDate: ovulation,
      confidenceScore: _calculateConfidence(deviation, logs.length),
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
    // Confidence calculation: If deviation is low (regular cycles) and count is high, confidence is high
    if (count < 3) return 40; // Needs more data
    if (deviation < 2.0) return 90; // Very Regular
    if (deviation < 4.0) return 75; // Normal
    return 60; // Irregular
  }
}
