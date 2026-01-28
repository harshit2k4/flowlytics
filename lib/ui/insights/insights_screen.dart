import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../logic/controllers/period_controller.dart';
import '../../core/constants/app_strings.dart';
import 'widgets/system_shield_card.dart';
import 'widgets/stat_pills.dart';

// Notification Dashboard
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 140,
            pinned: true,
            title: Text(
              AppStrings.getTimeBasedGreeting(controller.userName.value),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const SystemShieldCard(),
                  const SizedBox(height: 40),
                  _buildSectionHeader("Analysis Model"),
                  const SizedBox(height: 16),
                  _buildMLInsightCard(controller, colorScheme),
                  const SizedBox(height: 40),
                  _buildSectionHeader("Upcoming Prediction"),
                  const SizedBox(height: 16),
                  _buildUpcomingList(controller, colorScheme),
                  const SizedBox(height: 40),
                  _buildSectionHeader("Vitals"),
                  const SizedBox(height: 16),
                  const StatPills(),
                  const SizedBox(height: 60),
                  _buildFooter(colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLInsightCard(
    PeriodController controller,
    ColorScheme colorScheme,
  ) {
    return Obx(() {
      final logCount = controller.allLogs.length;
      String status;
      int confidence;
      String insightText;

      if (logCount == 0) {
        status = "IDLE";
        confidence = 0;
        insightText =
            "Engine ready. Log your first entry to begin building your data pattern.";
      } else if (logCount == 1) {
        status = "CALIBRATING";
        confidence = 65;
        insightText =
            "Initial entry recorded. A second log is required to activate projections.";
      } else {
        // Use the engine's calculated status and score instead of hardcoded value
        status = controller.confidenceStatus;
        confidence = controller.confidenceScore.value;
        insightText = controller.navigatorInsight.value.isEmpty
            ? "Your cycle history has established a reliable data baseline. Projections are now active."
            : controller.navigatorInsight.value;
      }

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.secondary.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ON-DEVICE ML",
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  "$confidence% Confidence • $status",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insightText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Data analysis is performed entirely using on-device ML algorithms.",
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUpcomingList(
    PeriodController controller,
    ColorScheme colorScheme,
  ) {
    return Obx(() {
      if (controller.allLogs.isEmpty) {
        return const Text(
          "Predictions will appear after your first log.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        );
      }
      return Column(
        children: List.generate(2, (index) {
          final date = controller.predictedStartDate.value.add(
            Duration(days: index * 28),
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Predicted Start",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('MMM dd').format(date),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
  );

  Widget _buildFooter(ColorScheme colorScheme) => Center(
    child: Column(
      children: [
        Text(
          AppStrings.secretNote,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}
