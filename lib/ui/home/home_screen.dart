import 'dart:ui';
import 'package:flowlytics/core/constants/app_strings.dart';
import 'package:flowlytics/ui/pages/calendar_page.dart';
import 'widgets/daily_checkin_sheet.dart';
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
              // calendar view
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () => Get.to(() => const CalendarPage()),
                  tooltip: "View History",
                ),
              ),
              // notification view
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
                  Obx(() => _buildPhaseInsightCard(context, controller)),
                  const SizedBox(height: 32),
                  Obx(() => _buildCircularProgress(context, controller)),
                  const SizedBox(height: 32),
                  _buildDailyVibeCard(context, controller),
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

  // Widget _buildMLInsightCard(
  //   BuildContext context,
  //   PeriodController controller,
  // ) {
  //   bool isLearning = controller.allLogs.length < 3;
  //   String modelName = isLearning
  //       ? "Biological Average"
  //       : "Personalized ML (Weighted)";
  //   return Card(
  //     elevation: 0,
  //     color: Theme.of(context).colorScheme.surfaceContainerLow,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(24),
  //       side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(24.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(
  //                 Icons.bolt,
  //                 size: 20,
  //                 color: Theme.of(context).colorScheme.primary,
  //               ),
  //               const SizedBox(width: 8),
  //               Text(
  //                 "INTELLIGENCE",
  //                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
  //                   letterSpacing: 1.2,
  //                   color: Theme.of(context).colorScheme.primary,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             "Active Model: $modelName",
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             isLearning
  //                 ? "The engine is currently using global health averages. It will switch to Personalized ML after ${3 - controller.allLogs.length} more logs."
  //                 : "The system is now using your unique history to provide higher accuracy predictions.",
  //             style: Theme.of(context).textTheme.bodyMedium,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMLInsightCard(
    BuildContext context,
    PeriodController controller,
  ) {
    // Check if Navigator is Active (Highest Priority)
    if (controller.isNavigatorActive.value) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BIO INTELLIGENCE",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.8,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Text(
              //   controller.navigatorInsight.value,
              //   style: const TextStyle(
              //     fontWeight: FontWeight.w600,
              //     fontSize: 16,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Text(
              //   "Prediction has been adjusted based on your symptoms.",
              //   style: Theme.of(context).textTheme.bodySmall,
              // ),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.4, // Line height for readability
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: _buildProfessionalInsight(
                    controller.navigatorInsight.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default State (Learning or Standard)
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
                  "BIO INTELLIGENCE",
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
                  ? "The engine is using global averages. It will switch to Personalized ML after ${3 - controller.allLogs.length} more logs."
                  : "The system is using your unique history for high-accuracy predictions.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Older implementation
  // Widget _buildPhaseInsightCard(
  //   BuildContext context,
  //   PeriodController controller,
  // ) {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(24),
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //       child: Container(
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: Theme.of(
  //             context,
  //           ).colorScheme.primaryContainer.withOpacity(0.15),
  //           borderRadius: BorderRadius.circular(24),
  //           border: Border.all(
  //             color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
  //           ),
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Icon(
  //                 Icons.spa_rounded, // Material 3 wellness icon
  //                 color: Theme.of(context).colorScheme.primary,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     "BIOLOGICAL STATUS",
  //                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
  //                       letterSpacing: 1.5,
  //                       fontWeight: FontWeight.bold,
  //                       color: Theme.of(context).colorScheme.primary,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     controller.currentPhase,
  //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPhaseInsightCard(
    BuildContext context,
    PeriodController controller,
  ) {
    final phase = controller.currentPhase;

    IconData phaseIcon;
    String phaseSubtitle;

    switch (phase) {
      case "Menstrual Phase":
        phaseIcon = Icons.bedtime_rounded;
        phaseSubtitle = "Time to rest and prioritize comfort.";
        break;
      case "Follicular Phase":
        phaseIcon = Icons.wb_sunny_rounded;
        phaseSubtitle = "Energy is rising. A great time for new goals!";
        break;
      case "Ovulatory Phase":
        phaseIcon = Icons.auto_awesome;
        phaseSubtitle = "You are at your biological peak glow.";
        break;
      case "Luteal Phase":
        phaseIcon = Icons.self_improvement_rounded;
        phaseSubtitle = "Be gentle with yourself. Focus inward.";
        break;
      default:
        phaseIcon = Icons.spa_rounded;
        phaseSubtitle = "Your personal wellness insight.";
    }

    return GestureDetector(
      onDoubleTap: () => _showEasterEgg(context, phase),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            // Increased padding from 20 to 26 for a more "airy" feel
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slightly larger icon container to match increased padding
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    phaseIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26, // Increased from 24
                  ),
                ),
                const SizedBox(
                  width: 20,
                ), // Increased spacing between icon and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "CURRENT BIOLOGY",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8), // Slightly larger gap
                      Text(
                        phase,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          fontSize:
                              22, // Slightly increased for a bolder presence
                        ),
                      ),
                      const SizedBox(height: 6), // Slightly larger gap
                      Text(
                        "“$phaseSubtitle”",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                          height:
                              1.4, // More line height for better readability
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyVibeCard(
    BuildContext context,
    PeriodController controller,
  ) {
    return Obx(() {
      final hasLogged = controller.todayLog.value != null;
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final colorScheme = Theme.of(context).colorScheme;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!hasLogged)
              BoxShadow(
                // For light mode use primary color for a subtle glow effect
                color: colorScheme.primary.withOpacity(isDarkMode ? 0.15 : 0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            // Performance note:
            // keeping blur slightly lower on the home card helps smoothness
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                // gradient for light and dark mode visiblity
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface.withOpacity(
                      hasLogged ? 0.4 : (isDarkMode ? 0.8 : 0.95),
                    ),
                    colorScheme.surface.withOpacity(
                      hasLogged ? 0.2 : (isDarkMode ? 0.6 : 0.85),
                    ),
                  ],
                ),
                border: Border.all(
                  // Dynamically styled border
                  // Stronger primary-tinted border in light mode,
                  // subtle white in dark mode
                  color: isDarkMode
                      ? Colors.white.withOpacity(hasLogged ? 0.05 : 0.2)
                      : colorScheme.primary.withOpacity(hasLogged ? 0.1 : 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon container with soft glow
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          hasLogged
                              ? Icons.favorite_rounded
                              : Icons.add_reaction_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasLogged
                                  ? "Vibe Recorded"
                                  : "How are you feeling?",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    // Ensure text is punchy in light mode
                                    color: colorScheme.onSurface.withOpacity(
                                      0.9,
                                    ),
                                  ),
                            ),
                            Text(
                              hasLogged
                                  ? "Your biology is being mapped"
                                  : "Tap to log your mood & symptoms",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openVibeSheet(),
                      style: FilledButton.styleFrom(
                        // To create a visual distinction between
                        // 'Call to action' and 'Edit'
                        backgroundColor: hasLogged
                            ? colorScheme.secondaryContainer.withOpacity(0.8)
                            : colorScheme.primary,
                        foregroundColor: hasLogged
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onPrimary,
                        elevation: hasLogged ? 0 : 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        hasLogged ? "Edit Today's Log" : "Check-in Now",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<TextSpan> _buildProfessionalInsight(String fullText) {
    if (!fullText.contains(',')) return [TextSpan(text: fullText)];

    // Splits "Hey [Name]," from the rest
    final parts = fullText.split(', ');
    return [
      TextSpan(
        text: parts[0] + ", ",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ), // Bold the "Hey [Name],"
      ),
      TextSpan(
        text: parts[1],
        style: const TextStyle(
          fontWeight: FontWeight.w400,
        ), // Professional weight for the rest
      ),
    ];
  }

  void _openVibeSheet() {
    Get.bottomSheet(
      const DailyCheckinSheet(),
      isScrollControlled: true, // Crucial for DraggableScrollableSheet to work
      backgroundColor: Colors.transparent,
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

  // hidden easter egg popup
  void _showEasterEgg(BuildContext context, String phase) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EasterEgg",
      barrierColor: Colors.black.withOpacity(
        0.4,
      ), // Subtle dimming of the background
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              // Deep frosted glass effect
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
                      mainAxisSize:
                          MainAxisSize.min, // Shrinks box to fit content
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 16),

                        // The secret one liner note
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

                        // Biological tip for current phase
                        Text(
                          AppStrings.getPhaseDetailedInfo(phase),
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
        // Smooth fade and scale-up animation
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
