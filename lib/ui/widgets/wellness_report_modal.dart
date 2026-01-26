import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:flowlytics/logic/services/pdf_service.dart';
import 'package:flowlytics/ui/insights/widgets/stat_pills.dart';
import '../../logic/controllers/period_controller.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/glass_snackbar.dart';

class WellnessReportModal extends StatefulWidget {
  const WellnessReportModal({super.key});

  @override
  State<WellnessReportModal> createState() => _WellnessReportModalState();
}

class _WellnessReportModalState extends State<WellnessReportModal> {
  final RxBool isGenerating = false.obs;
  final ScrollController _scrollController = ScrollController();

  final RxBool showTopArrow = false.obs;
  final RxBool showBottomArrow = false.obs;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to check if we need a down arrow initially
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollListener());
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    showTopArrow.value = _scrollController.offset > 10;

    // Only show bottom arrow if the content is actually scrollable and not at the end
    bool isScrollable = _scrollController.position.maxScrollExtent > 0;
    showBottomArrow.value =
        isScrollable &&
        (_scrollController.offset <
            (_scrollController.position.maxScrollExtent - 10));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();
    final colorScheme = Theme.of(context).colorScheme;

    final String timestamp = DateFormat(
      "EEEE, MMM d, yyyy 'at' hh:mm a",
    ).format(DateTime.now());
    final String rawName = controller.userName.value;
    final String displayName = (rawName.isEmpty || rawName == "Beautiful Girl")
        ? "My Wellness Overview"
        : "$rawName's Overview";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.85, // Prevents full screen
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // FIXED HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showTopArrow.value ? 0.4 : 0.0,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT AREA
                Flexible(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            const StatPills(),
                            const SizedBox(height: 24),
                            _buildDataTable(context, controller),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Obx(
                        () => AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showBottomArrow.value ? 0.4 : 0.0,
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FOOTER
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.medicalDisclaimer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isGenerating.value
                                ? null
                                : () async {
                                    isGenerating.value = true;
                                    try {
                                      await PdfService.generateWellnessReport(
                                        context,
                                        controller,
                                      );
                                      if (context.mounted) {
                                        GlassSnackbar.show(
                                          context,
                                          "Summary exported successfully.",
                                          icon: Icons
                                              .check_circle_outline_rounded,
                                        );
                                      }
                                    } finally {
                                      isGenerating.value = false;
                                    }
                                  },
                            icon: isGenerating.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.share_rounded, size: 20),
                            label: Text(
                              isGenerating.value
                                  ? "Processing..."
                                  : "Export & Share PDF",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
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

  Widget _buildDataTable(BuildContext context, PeriodController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final logs = controller.allLogs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Recent Cycles",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: logs.isEmpty
              ? _buildEmptyState(colorScheme)
              : Column(
                  children: logs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final log = entry.value;
                    final isLast = index == logs.length - 1;

                    String cycleLength = "--";
                    if (index < controller.allLogs.length - 1) {
                      final nextLog = controller.allLogs[index + 1];
                      cycleLength =
                          "${log.startDate.difference(nextLog.startDate).inDays.abs()} Days";
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(log.startDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Start Date",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildDataPoint(
                                  context,
                                  "5 Days",
                                  "Duration",
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildDataPoint(
                                  context,
                                  cycleLength,
                                  "Cycle Gap",
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colorScheme.onSurface.withOpacity(0.05),
                          ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDataPoint(BuildContext context, String value, String label) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A soft, boutique-style icon container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined, // Book/History icon
              color: colorScheme.primary.withOpacity(0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Your journey starts here",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Once you log your first cycle, your personal wellness summary will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
