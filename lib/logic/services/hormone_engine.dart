import 'dart:math';

/// A data model representing the three primary hormones
class HormoneLevels {
  final double estrogen;
  final double progesterone;
  final double testosterone;

  HormoneLevels({
    required this.estrogen,
    required this.progesterone,
    required this.testosterone,
  });
}

class HormoneEngine {
  /// Simulates hormonal fluctuations based on the current day and cycle length.
  /// Values are returned as a percentage (0.0 to 1.0).
  static HormoneLevels calculateLevels({
    required int currentCycleDay,
    required int totalCycleLength,
  }) {
    // Normalize the day into a 0.0 to 1.0 scale for the math functions
    double progress = currentCycleDay / totalCycleLength;

    // Estrogen Logic: Peaks sharply before ovulation (~45% through cycle)
    // and has a second, rounded peak during the luteal phase (~75%).
    double estrogenCurve =
        0.15 +
        0.7 * exp(-pow(progress - 0.45, 2) / 0.006) +
        0.3 * exp(-pow(progress - 0.75, 2) / 0.012);

    // Progesterone Logic: Remains very low until after ovulation,
    // then creates a large "mountain" in the luteal phase (~75%).
    double progesteroneCurve =
        0.05 + 0.8 * exp(-pow(progress - 0.75, 2) / 0.015);

    // Testosterone Logic: Has one single, sharp spike during the
    // ovulatory window to boost energy and libido.
    double testosteroneCurve =
        0.1 + 0.5 * exp(-pow(progress - 0.45, 2) / 0.003);

    return HormoneLevels(
      estrogen: estrogenCurve.clamp(0.0, 1.0),
      progesterone: progesteroneCurve.clamp(0.0, 1.0),
      testosterone: testosteroneCurve.clamp(0.0, 1.0),
    );
  }
}
