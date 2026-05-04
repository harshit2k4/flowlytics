import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../logic/services/hormone_engine.dart';
import '../../../core/constants/app_strings.dart';

class HormoneForecastCard extends StatelessWidget {
  final int currentCycleDay;
  final int averageCycleLength;

  const HormoneForecastCard({
    super.key,
    required this.currentCycleDay,
    required this.averageCycleLength,
  });

  // Calculates the current phase to pass to the Easter Egg dialog
  String _calculatePhase() {
    if (currentCycleDay <= 5) return "Menstrual Phase";

    int halfCycle = (averageCycleLength / 2).round();
    if (currentCycleDay <= halfCycle - 2) return "Follicular Phase";
    if (currentCycleDay <= halfCycle + 2) return "Ovulatory Phase";

    return "Luteal Phase";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme),
                const SizedBox(height: 24),
                _buildChartContainer(colorScheme),
                const SizedBox(height: 12),
                _buildPhaseTimeline(colorScheme),
                const SizedBox(height: 24),
                _buildPhaseLegend(colorScheme),
                const SizedBox(height: 12),
                _buildLegend(colorScheme),
                const Divider(height: 32, thickness: 0.5),
                _buildDisclaimer(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Biological Rhythm",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Cycle Day $currentCycleDay",
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        GestureDetector(
          // We pass the calculated phase to your custom dialog here
          onTap: () => _showEasterEgg(context, _calculatePhase()),
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.transparent,
            child: Icon(
              Icons.insights_rounded,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer(ColorScheme colorScheme) {
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: currentCycleDay.toDouble(),
                color: colorScheme.onSurface,
                strokeWidth: 2,
                dashArray: [4, 4],
              ),
            ],
          ),
          lineBarsData: [
            _generateHormoneLine(Colors.pinkAccent, "estrogen"),
            _generateHormoneLine(Colors.amber, "progesterone"),
            _generateHormoneLine(Colors.deepPurpleAccent, "testosterone"),
          ],
        ),
      ),
    );
  }

  LineChartBarData _generateHormoneLine(Color color, String type) {
    List<FlSpot> points = [];
    for (int i = 0; i <= averageCycleLength; i++) {
      final levels = HormoneEngine.calculateLevels(
        currentCycleDay: i,
        totalCycleLength: averageCycleLength,
      );
      double yValue = 0;
      if (type == "estrogen") yValue = levels.estrogen;
      if (type == "progesterone") yValue = levels.progesterone;
      if (type == "testosterone") yValue = levels.testosterone;

      points.add(FlSpot(i.toDouble(), yValue));
    }

    return LineChartBarData(
      spots: points,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.1), color.withOpacity(0)],
        ),
      ),
    );
  }

  Widget _buildPhaseTimeline(ColorScheme colorScheme) {
    return Row(
      children: [
        _phaseSegment(Icons.water_drop_outlined, 5, colorScheme),
        _phaseSegment(Icons.spa_outlined, 9, colorScheme),
        _phaseSegment(Icons.wb_sunny_outlined, 3, colorScheme),
        _phaseSegment(Icons.nightlight_round_outlined, 11, colorScheme),
      ],
    );
  }

  Widget _phaseSegment(IconData icon, int weight, ColorScheme colorScheme) {
    return Expanded(
      flex: weight,
      child: Column(
        children: [
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseLegend(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _phaseLegendItem(Icons.water_drop_outlined, "Menstrual"),
        _phaseLegendItem(Icons.spa_outlined, "Follicular"),
        _phaseLegendItem(Icons.wb_sunny_outlined, "Ovulatory"),
        _phaseLegendItem(Icons.nightlight_round_outlined, "Luteal"),
      ],
    );
  }

  Widget _phaseLegendItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendIcon("Estrogen", Colors.pinkAccent),
        _legendIcon("Progesterone", Colors.amber),
        _legendIcon("Testosterone", Colors.deepPurpleAccent),
      ],
    );
  }

  Widget _legendIcon(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDisclaimer(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "This graph provides mathematical modelling and prediction only based on biological patterns mapped to your history.",
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // Your exact custom easter egg implementation
  void _showEasterEgg(BuildContext context, String phase) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EasterEgg",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.secretNote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(thickness: 0.5),
                        ),
                        Text(
                          AppStrings.hormoneGraphEasterEgg,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            child: child,
          ),
        );
      },
    );
  }
}
