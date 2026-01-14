import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../logic/controllers/period_controller.dart';
import '../../data/models/period_log.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PeriodController controller = Get.find<PeriodController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              "Analytics",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Obx(() {
                // Ignore the 'reference' log (cycleLength 0)
                final validLogs = controller.allLogs
                    .where((l) => l.cycleLength > 0)
                    .toList()
                    .reversed
                    .toList();

                if (validLogs.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cycle Duration",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildMD3BarChart(context, validLogs),
                    const SizedBox(height: 40),
                    _buildGlassyStatsGrid(context, validLogs),
                    const SizedBox(height: 24),
                    _buildReassuranceFooter(context),
                    const SizedBox(height: 40),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMD3BarChart(BuildContext context, List<PeriodLog> logs) {
    double avgCycle =
        logs.map((l) => l.cycleLength).reduce((a, b) => a + b) / logs.length;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 45,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.secondaryContainer,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "${rod.toY.toInt()} Days",
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "C${v.toInt() + 1}",
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              if ((value - avgCycle).abs() < 0.5) {
                return FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.5),
                  strokeWidth: 2,
                  dashArray: [4, 4],
                );
              }
              return const FlLine(color: Colors.transparent);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: logs.asMap().entries.map((entry) {
            int days = entry.value.cycleLength;
            // MD3 Logic: Use Error role for outliers, Primary for normal
            bool isOutlier = days < 21 || days > 35;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: days.toDouble().clamp(0, 45),
                  color: isOutlier
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 45,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGlassyStatsGrid(BuildContext context, List<PeriodLog> logs) {
    double avg =
        logs.map((l) => l.cycleLength).reduce((a, b) => a + b) / logs.length;

    return Row(
      children: [
        Expanded(
          child: _buildGlassyCard(
            context,
            "Logged",
            "${logs.length}",
            Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassyCard(
            context,
            "Avg Cycle",
            "${avg.round()}d",
            Icons.timelapse_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassyCard(
    BuildContext context,
    String label,
    String val,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassuranceFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Cycles outside 21-35 days are colored for awareness. This is often temporary.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.auto_graph_rounded,
          size: 80,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(height: 24),
        const Text(
          "Generating Insights...",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "A minimum of two logged periods is required for cycle consistency tracking by the ML algorithm.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ],
    );
  }
}
