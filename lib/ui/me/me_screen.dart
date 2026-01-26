import 'package:flowlytics/core/theme/app_theme.dart';
import 'package:flowlytics/logic/controllers/theme_controller.dart';
import 'package:flowlytics/logic/services/backup_service.dart';
import 'package:flowlytics/ui/security/security_setup_screen.dart';
import 'package:flowlytics/ui/widgets/glass_snackbar.dart';
import 'package:flowlytics/ui/widgets/wellness_report_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../logic/controllers/period_controller.dart';
import '../../logic/controllers/security_controller.dart';
import '../insights/insights_screen.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  // PageController with viewportFraction for the "Peek" effect
  final PageController _pageController = PageController(
    viewportFraction:
        0.7, // Adjusted to make cards larger but still show siblings
  );
  final RxInt _focusedIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<PeriodController>();
    _nameController = TextEditingController(text: controller.userName.value);

    // Set initial focus based on the currently saved theme index
    final tc = Get.find<ThemeController>();
    final List<int> themeOrder = [0, 1, 3, 2];
    _focusedIndex.value = themeOrder.indexOf(tc.currentThemeIndex.value);

    // Jump to the saved theme page initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_focusedIndex.value);
      }
    });
  }

  // Helpers for labels and subtitles
  String _getThemeLabel(int themeIndex) {
    return [
      "Sky Breeze",
      "Solar Glow",
      "Classic Flow",
      "Mint Revival",
    ][themeIndex];
  }

  String _getThemeSubtitle(int themeIndex) {
    return [
      "Calm & Clarity",
      "Energy & Warmth",
      "Strength & Grace",
      "Fresh & Balanced",
    ][themeIndex];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();
    final securityController = Get.find<SecurityController>();
    final themeController = Get.find<ThemeController>();
    final List<int> themeOrder = [0, 1, 3, 2]; // Sky, Solar, Mint, Classic

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Obx(
              () => Text(
                controller.userName.value == "Beautiful Girl"
                    ? "Hello Beautiful Girl"
                    : "Hello ${controller.userName.value}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileHeader(context, controller),
                  const SizedBox(height: 32),
                  _buildSectionHeader("System Status"),
                  const SizedBox(height: 12),
                  Obx(() {
                    bool isMLActive = controller.allLogs.length >= 3;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfo(
                            context,
                            Icons.shield_outlined,
                            "Private",
                            "Local Data",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCompactInfo(
                            context,
                            Icons.memory_outlined,
                            "Engine",
                            isMLActive ? "Weighted ML" : "Bio Average",
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),
                  _buildSectionHeader("App Mood"),

                  // Mood Carousel with PageView for "Peek" effect
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: themeOrder.length,
                      onPageChanged: (i) => _focusedIndex.value = i,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        int themeIdx = themeOrder[index];
                        return Obx(() {
                          // Dynamic scaling for the focused card
                          double scale = _focusedIndex.value == index
                              ? 1.0
                              : 0.9;
                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween(begin: scale, end: scale),
                            builder: (context, double val, child) {
                              return Transform.scale(
                                scale: val,
                                child: _buildMoodCard(
                                  themeIdx,
                                  _getThemeLabel(themeIdx),
                                  _getThemeSubtitle(themeIdx),
                                  themeController,
                                ),
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),

                  // Intuitive Scroll Dots
                  const SizedBox(height: 16),
                  Center(
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(themeOrder.length, (index) {
                          bool isFocused = _focusedIndex.value == index;
                          Color activeColor = themeController.getSeedColor(
                            themeOrder[index],
                          );

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isFocused ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? activeColor
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isFocused
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.3),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader("Preferences"),
                  _buildSettingsGroup(context, [
                    _buildTile(
                      context,
                      Icons.notifications_active_outlined,
                      "Notifications",
                      "Diagnostic & Reminders",
                      () => Get.to(() => const InsightsScreen()),
                      iconColor: Colors.pinkAccent,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // PRIVACY & SECURITY
                  _buildSectionHeader("Privacy & Security"),
                  _buildSettingsGroup(context, [
                    Obx(
                      () => _buildTile(
                        context,
                        Icons.lock_person_outlined,
                        "App Lock",
                        securityController.isLockEnabled.value
                            ? "Secured"
                            : "Protect your data",
                        // () => Get.snackbar(
                        //   "App Lock",
                        //   "PIN Setup Screen coming next!",
                        () => Get.to(() => const SecuritySetupScreen()),
                        iconColor: Colors.indigoAccent,
                        trailing: securityController.isLockEnabled.value
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // BACKUP (Import/Export)
                  _buildSectionHeader("Backup"),
                  _buildSettingsGroup(context, [
                    _buildTile(
                      context,
                      Icons.upload_file_rounded,
                      "Export Data",
                      "Save encrypted .flytx",
                      () async {
                        // 1. Show the Security Warning before exporting
                        bool proceed = await _showSecurityWarning(context);
                        if (!proceed) return;

                        // 2. Trigger the actual export
                        bool success = await BackupService.exportLogs();
                        if (success && mounted) {
                          GlassSnackbar.show(
                            context,
                            "Backup saved!",
                            icon: Icons.check_circle_rounded,
                          );
                        }
                      },
                      iconColor: Colors.orange,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildTile(
                      context,
                      Icons.file_download_rounded,
                      "Import Data",
                      "Restore from file",
                      () async {
                        // 1. Run the import service
                        bool success = await BackupService.importLogs();

                        if (success) {
                          // 2. THIS IS THE FIX: Tell the controller to reload Hive into the UI
                          controller.syncImportedData();

                          if (mounted) {
                            GlassSnackbar.show(
                              context,
                              "Logs restored!",
                              icon: Icons.history_edu_rounded,
                            );
                          }
                        } else {
                          if (mounted) {
                            GlassSnackbar.show(
                              context,
                              "Import failed",
                              icon: Icons.error_outline,
                            );
                          }
                        }
                      },
                      iconColor: Colors.teal,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // INFORMATION
                  _buildSectionHeader("Information"),
                  _buildSettingsGroup(context, [
                    _buildTile(
                      context,
                      Icons.picture_as_pdf_rounded,
                      "Health Summary",
                      "View your journey summary",
                      () {
                        // TODO: Implement PDF generation logic
                        GlassSnackbar.show(
                          context,
                          "Generating your summary...",
                          icon: Icons.hourglass_empty_rounded,
                        );
                      },
                      iconColor: Colors.deepOrangeAccent,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildTile(
                      context,
                      Icons.info_outline_rounded,
                      "Software Info",
                      "Version & Details",
                      () => _showSoftwareInfo(context),
                      iconColor: Colors.blueAccent,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildTile(
                      context,
                      Icons.description_outlined,
                      "OSS Licenses",
                      "Open source credits",
                      // Flutter license page
                      () => showLicensePage(
                        context: context,
                        applicationName: "Flowlytics",
                        applicationVersion: "0.1.0",
                        applicationIcon: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.red,
                        ),
                      ),
                      iconColor: Colors.purple,
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Wipe data zone
                  _buildSectionHeader("Danger Zone", color: Colors.red),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        "Wipe Everything",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Permanent deletion",
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () => _showDeleteDialog(context, controller),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // FOOTER
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Made with ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Icon(Icons.favorite, color: Colors.red, size: 16),
                        Text(
                          " by Someone special",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSecurityWarning(BuildContext context) async {
    final settingsBox = Hive.box('settings_box');
    bool hideWarning = settingsBox.get(
      'hide_export_warning',
      defaultValue: false,
    );

    if (hideWarning) return true;

    bool dontShowAgain = false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text("Security Warning"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Share your critical health data with only those whom you fully trust. Flowlytics is not responsible for any misuse of data once exported.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) =>
                            setState(() => dontShowAgain = val!),
                      ),
                      const Expanded(
                        child: Text(
                          "I understand, don't show again",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dontShowAgain)
                      settingsBox.put('hide_export_warning', true);
                    Get.back(result: true);
                  },
                  child: const Text("Proceed"),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Widget _buildMoodCard(
    int index,
    String title,
    String subtitle,
    ThemeController tc,
  ) {
    return Obx(() {
      final isSelected = tc.currentThemeIndex.value == index;
      final seed = AppTheme.getSeedColor(index);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return GestureDetector(
        onTap: () => tc.changeTheme(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          width: 160,
          // Vertical margins ensure the outer shadow has room to fade naturally
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? seed.withOpacity(isDark ? 0.25 : 0.12)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(32),
            // Subtle definition for both light and dark mode
            border: Border.all(
              color: isSelected
                  ? seed
                  : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08)),
              width: 1.5,
            ),
            // Soft falloff with a larger blur to prevent "boxy" cuts
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: seed.withOpacity(isDark ? 0.3 : 0.15),
                      blurRadius: 25,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    // Clean depth for Light Mode unselected cards
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -15,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: seed.withOpacity(isSelected ? 0.12 : 0.04),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // IMPROVED: Barely-there Inner Glow
                      Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: seed,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: seed.withOpacity(
                                      0.15,
                                    ), // Very subtle bloom
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: isSelected
                              ? seed
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? seed.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(Icons.check_circle, size: 20, color: seed),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Header section
  Widget _buildProfileHeader(
    BuildContext context,
    PeriodController controller,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.favorite_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text("Heya!", style: TextStyle(fontSize: 16)),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40), // Balance the icon button
            _isEditing
                ? Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      maxLength: 15,
                      onSubmitted: (val) {
                        controller.updateName(val);
                        setState(() => _isEditing = false);
                      },
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                      ),
                    ),
                  )
                : Flexible(
                    child: Obx(
                      () => Text(
                        controller.userName.value,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
            IconButton(
              onPressed: () {
                if (_isEditing) {
                  controller.updateName(_nameController.text);
                }
                setState(() => _isEditing = !_isEditing);
                if (_isEditing) _focusNode.requestFocus();
              },
              icon: Icon(
                _isEditing ? Icons.check_circle : Icons.edit_outlined,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Info Card
  Widget _buildCompactInfo(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          FittedBox(
            child: Text(sub, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color ?? Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    VoidCallback? onTap, {
    Widget? trailing,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = iconColor ?? colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // Matches the StatPill logic exactly
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: accentColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showSoftwareInfo(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Flowlytics",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Text(
              "Version 0.1.0 (Stable)",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              "Flowlytics is a self learning privacy-first periods tracker.\nYour data never leaves this device.",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Get.back(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PeriodController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Wipe?"),
        content: const Text(
          "This acts as an emergency reset. All logs and your name's history will be deleted.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Get.back();
              // Perform the data wipe
              await controller.wipeData();
              // Check if the widget is still in the tree before calling setState
              if (!mounted) return;

              setState(() {
                _nameController.text = "Beautiful Girl";
                _isEditing = false;
              });

              // Use the global glassy snackbar
              GlassSnackbar.show(
                context,
                "All data wiped",
                icon: Icons.delete_sweep_rounded,
              );
            },
            child: const Text("Wipe", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
