import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flowlytics/ui/nav_wrapper.dart';
import '../../../logic/controllers/period_controller.dart';
import '../../../logic/services/notification_service.dart';

class NotificationPermissionScreen extends StatelessWidget {
  final String name;
  final DateTimeRange? lastPeriod;
  final int usualCycle;

  const NotificationPermissionScreen({
    super.key,
    required this.name,
    required this.lastPeriod,
    required this.usualCycle,
  });

  // Brand detection
  String _getDisplayIdentity() {
    if (Platform.isIOS) return "iPhone";
    if (Platform.isLinux) return "Linux Desktop";
    if (Platform.isMacOS) return "macOS";

    if (Platform.isAndroid) {
      final version = Platform.operatingSystemVersion.toLowerCase();
      // Expanded keywords to catch even hidden manufacturer names
      if (version.contains("xiaomi") ||
          version.contains("miui") ||
          version.contains("poco") ||
          version.contains("redmi") ||
          version.contains("hyperos"))
        return "Xiaomi";
      if (version.contains("samsung")) return "Samsung";
      if (version.contains("oppo") || version.contains("coloros"))
        return "Oppo";
      if (version.contains("vivo") || version.contains("funtouch"))
        return "Vivo";
      if (version.contains("huawei") || version.contains("emui"))
        return "Huawei";
      if (version.contains("google") || version.contains("pixel"))
        return "Google Pixel";

      return "Android Device";
    }
    return "Generic Device";
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 54,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Stay Prepared",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Flowlytics uses precise reminders to help you stay ahead of your cycle.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Core Permissions Card
                      _buildUniformCard(
                        context,
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.2,
                        ),
                        borderColor: theme.colorScheme.primary.withOpacity(0.4),
                        child: Column(
                          children: [
                            _permissionRow(
                              context,
                              Icons.alarm,
                              "EXACT ALARMS",
                              "Ensures reminders arrive exactly at 9:00 AM.",
                            ),
                            const SizedBox(height: 16),
                            _permissionRow(
                              context,
                              Icons.directions_run,
                              "BACKGROUND RUN",
                              "Calculates cycles even when app is closed.",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Optimization Card (Android Only)
                      if (Platform.isAndroid)
                        GestureDetector(
                          onTap: () => _showSettingsGuide(context),
                          child: _buildUniformCard(
                            context,
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.3,
                            ),
                            borderColor: theme.colorScheme.primary.withOpacity(
                              0.2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 20,
                                      color: Colors.amber[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "SYSTEM OPTIMIZATION",
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Your device may block reminders to save battery. Tap to enable 'Auto-start' and 'No Restrictions'.",
                                  style: TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Display system ID
                      _buildDevicePill(context),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () async {
                          if (Platform.isAndroid || Platform.isIOS) {
                            await NotificationService().requestPermissions();
                          }
                          _complete(controller);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Enable & Continue",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _complete(controller),
                      child: Text(
                        "Maybe Later",
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniformCard(
    BuildContext context, {
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildDevicePill(BuildContext context) {
    final theme = Theme.of(context);
    final identity = _getDisplayIdentity();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Platform.isAndroid
                ? Icons.android
                : (Platform.isIOS ? Icons.apple : Icons.computer),
            size: 16,
            color: Platform.isAndroid
                ? Colors.green[700]
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            "Running on $identity",
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(desc, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text("Device Guide"),
          content: const Text(
            "To ensure reminders arrive on time:\n\n1. Enable 'Auto-start'\n2. Set Battery to 'No Restrictions'",
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("Close")),
            FilledButton(
              onPressed: () {
                openAppSettings();
                Get.back();
              },
              child: const Text("Settings"),
            ),
          ],
        ),
      ),
    );
  }

  void _complete(PeriodController controller) async {
    await controller.completeOnboarding(
      name: name,
      lastPeriod: lastPeriod,
      usualCycle: usualCycle,
    );
    Get.offAll(() => const NavWrapper());
  }
}
