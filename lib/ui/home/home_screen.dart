import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/period_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _padsReady = false;
  bool _hydrated = false;
  bool _selfCare = false;
  bool _moodChecked = false;

  @override
  Widget build(BuildContext context) {
    final PeriodController controller = Get.find<PeriodController>();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text(
              "Flowlytics",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuoteCard(context),
                  const SizedBox(height: 32),
                  Obx(() => _buildCircularProgress(context, controller)),
                  const SizedBox(height: 40),
                  Obx(() => _buildSmartChipsSection(context, controller)),
                  const SizedBox(height: 32),
                  Obx(() => _buildMLInsightCard(context, controller)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text("Log Cycle"),
      ),
    );
  }

  Widget _buildSmartChipsSection(
    BuildContext context,
    PeriodController controller,
  ) {
    String title;
    List<Widget> chips;

    switch (controller.currentStatus) {
      case PeriodStatus.active:
        title = "Self Care";
        chips = [
          FilterChip(
            label: const Text("Cramp Relief"),
            selected: _selfCare,
            onSelected: (v) => setState(() => _selfCare = v),
          ),
          FilterChip(
            label: const Text("Rest Well"),
            selected: _moodChecked,
            onSelected: (v) => setState(() => _moodChecked = v),
          ),
        ];
        break;
      case PeriodStatus.preparation:
        title = "Preparation";
        chips = [
          FilterChip(
            label: const Text("Pads Ready"),
            selected: _padsReady,
            onSelected: (v) => setState(() => _padsReady = v),
          ),
          FilterChip(
            label: const Text("Stay Hydrated"),
            selected: _hydrated,
            onSelected: (v) => setState(() => _hydrated = v),
          ),
        ];
        break;
      case PeriodStatus.wellness:
      default:
        title = "Daily Wellness";
        chips = [
          FilterChip(
            label: const Text("Hydration"),
            selected: _hydrated,
            onSelected: (v) => setState(() => _hydrated = v),
          ),
          FilterChip(
            label: const Text("Mood Check"),
            selected: _moodChecked,
            onSelected: (v) => setState(() => _moodChecked = v),
          ),
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildCircularProgress(
    BuildContext context,
    PeriodController controller,
  ) {
    final status = controller.currentStatus;
    final now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final daysUntil = controller.predictedStartDate.value
        .difference(now)
        .inDays;

    // Label Logic
    String topLabel = status == PeriodStatus.active ? "Status" : "Next in";
    String mainValue = status == PeriodStatus.active
        ? "Started"
        : (daysUntil <= 0 ? "Today" : "$daysUntil");

    String bottomLabel = "";
    if (status == PeriodStatus.active) {
      bottomLabel = "Today";
    } else if (daysUntil <= 0) {
      bottomLabel = ""; // Hides "Days" if the value is "Today"
    } else {
      bottomLabel = daysUntil == 1 ? "Day" : "Days"; // Singular vs Plural
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: status == PeriodStatus.active
                  ? 1.0
                  : (1.0 - (daysUntil.clamp(0, 28) / 28)),
              strokeWidth: 10,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(topLabel, style: Theme.of(context).textTheme.titleMedium),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mainValue,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (mainValue == "Today" || mainValue == "Started")
                        ? 44
                        : null,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (bottomLabel.isNotEmpty)
                Text(
                  bottomLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "“Self-care is a priority, not a luxury.”",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLInsightCard(
    BuildContext context,
    PeriodController controller,
  ) {
    bool isLearning = controller.allLogs.length < 3;
    String modelName = isLearning
        ? "Biological Average"
        : "Personalized ML (Weighted)";
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "INTELLIGENCE",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Active Model: $modelName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isLearning
                  ? "The engine is currently using global health averages. It will switch to Personalized ML after ${3 - controller.allLogs.length} more logs."
                  : "The system is now using your unique history to provide higher accuracy predictions.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context, PeriodController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      await controller.savePeriod(picked.start, picked.end);
      _showGlassySnackbar(context);
    }
  }

  void _showGlassySnackbar(BuildContext context) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Log added. ML updated.",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
