import 'dart:ui';
import 'package:flowlytics/ui/security/security_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    final controller = Get.find<PeriodController>();
    _nameController = TextEditingController(text: controller.userName.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();
    final securityController = Get.find<SecurityController>();

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

                  // HEADER (Avatar & Name)
                  _buildProfileHeader(context, controller),

                  const SizedBox(height: 32),

                  // SYSTEM STATUS
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

                  const SizedBox(height: 32),

                  // PREFERENCES
                  _buildSectionHeader("Preferences"),
                  _buildSettingsGroup(context, [
                    _buildTile(
                      context,
                      Icons.notifications_active_outlined,
                      "Notifications",
                      "Diagnostic & Reminders",
                      () => Get.to(() => const InsightsScreen()),
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
                      "Save encrypted .json",
                      () => Get.snackbar("Backup", "Export logic coming soon"),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildTile(
                      context,
                      Icons.file_download_rounded,
                      "Import Data",
                      "Restore from file",
                      () => Get.snackbar("Backup", "Import logic coming soon"),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // INFORMATION
                  _buildSectionHeader("Information"),
                  _buildSettingsGroup(context, [
                    _buildTile(
                      context,
                      Icons.info_outline_rounded,
                      "Software Info",
                      "Version & Details",
                      () => _showSoftwareInfo(context),
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
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
              await controller.wipeData();

              // Reset local UI state
              setState(() {
                _nameController.text = "Beautiful Girl";
                _isEditing = false;
              });

              Get.back();
              // Original snackbar logic
              Get.rawSnackbar(
                messageText: const Text(
                  "All data wiped",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black.withOpacity(0.8),
                borderRadius: 20,
                margin: const EdgeInsets.all(20),
              );
            },
            child: const Text("Wipe", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
