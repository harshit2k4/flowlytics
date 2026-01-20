import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../logic/controllers/period_controller.dart';

class StatPills extends StatelessWidget {
  const StatPills({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();

    return Obx(() {
      final hasLogs = controller.allLogs.isNotEmpty;
      final avg = hasLogs ? _calculateAverage(controller).toString() : "--";
      final totalLogs = controller.allLogs.length.toString();

      return Row(
        children: [
          _buildPill(
            context,
            "Avg. Cycle",
            "$avg Days",
            Icons.history_rounded,
            Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildPill(
            context,
            "Data Points",
            "$totalLogs Cycles",
            Icons.bar_chart_rounded,
            Colors.purple,
          ),
        ],
      );
    });
  }

  Widget _buildPill(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAverage(PeriodController controller) {
    if (controller.allLogs.length < 2) return 28;
    int totalDays = 0;
    for (int i = 0; i < controller.allLogs.length - 1; i++) {
      totalDays += controller.allLogs[i].startDate
          .difference(controller.allLogs[i + 1].startDate)
          .inDays
          .abs();
    }
    return (totalDays / (controller.allLogs.length - 1)).round();
  }
}
