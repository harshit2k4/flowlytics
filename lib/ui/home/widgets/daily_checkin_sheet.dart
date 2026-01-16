import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../logic/controllers/period_controller.dart';

class DailyCheckinSheet extends StatefulWidget {
  const DailyCheckinSheet({super.key});

  @override
  State<DailyCheckinSheet> createState() => _DailyCheckinSheetState();
}

class _DailyCheckinSheetState extends State<DailyCheckinSheet> {
  final PeriodController controller = Get.find<PeriodController>();

  List<String> selectedMoods = [];
  List<String> selectedPhysical = [];
  List<String> selectedSkin = [];
  List<String> selectedFlow = [];
  List<String> selectedSleep = [];

  @override
  void initState() {
    super.initState();
    if (controller.todayLog.value != null) {
      selectedMoods = List.from(controller.todayLog.value!.moods);
      selectedPhysical = List.from(controller.todayLog.value!.physical);
      selectedSkin = List.from(controller.todayLog.value!.skin);
      selectedFlow = List.from(controller.todayLog.value!.flow);
      selectedSleep = List.from(controller.todayLog.value!.sleep);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF121212).withOpacity(0.98)
                : Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: colorScheme.primary.withOpacity(isDarkMode ? 0.1 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  // Static header
                  RepaintBoundary(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "How are you, ${controller.userName.value.split(' ')[0]}?",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "How you're feeling today?",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      // For performance: Cache prevents jitter during scroll starts
                      cacheExtent: 1000,
                      addRepaintBoundaries: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                      children: [
                        // Isolated repaint boundaries for each chip group.
                        // This helps to improve performance by
                        // redrawing specific areas only
                        RepaintBoundary(
                          child: _buildSection(
                            context,
                            "Your Vibe",
                            AppStrings.moods,
                            selectedMoods,
                          ),
                        ),
                        RepaintBoundary(
                          child: _buildSection(
                            context,
                            "Physical Symptoms",
                            AppStrings.physical,
                            selectedPhysical,
                          ),
                        ),
                        RepaintBoundary(
                          child: _buildSection(
                            context,
                            "Skin Status",
                            AppStrings.skin,
                            selectedSkin,
                          ),
                        ),
                        RepaintBoundary(
                          child: _buildSection(
                            context,
                            "Flow Intensity",
                            AppStrings.flow,
                            selectedFlow,
                          ),
                        ),
                        RepaintBoundary(
                          child: _buildSection(
                            context,
                            "Sleep Quality",
                            AppStrings.sleep,
                            selectedSleep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Pinned Save Button (Kept out of ListView for focus)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await controller.saveDailyCheckIn(
                          selectedMoods: selectedMoods,
                          selectedPhysical: selectedPhysical,
                          selectedSkin: selectedSkin,
                          selectedFlow: selectedFlow,
                          selectedSleep: selectedSleep,
                        );
                        Get.back();
                        _showGlassySnackbar(context);
                      },
                      child: const Text(
                        "Save for Today",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> options,
    List<String> currentSelections,
  ) {
    final bool isSingleSelect =
        title.contains("Flow") ||
        title.contains("Sleep") ||
        title.contains("Skin");
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.5,
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = currentSelections.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (isSingleSelect) {
                    currentSelections.clear();
                    if (selected) currentSelections.add(option);
                  } else {
                    if (selected) {
                      currentSelections.add(option);
                    } else {
                      currentSelections.remove(option);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showGlassySnackbar(BuildContext context) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 3),
      messageText: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Vibe logged. You're doing great!",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
