import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../logic/controllers/period_controller.dart';
import '../../../logic/controllers/diagnostic_controller.dart';

class SystemShieldCard extends StatelessWidget {
  const SystemShieldCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Use find instead of put to maintain global state
    final diagController = Get.find<DiagnosticController>();
    final periodController = Get.find<PeriodController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(
      () => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: diagController.isTesting.value
                  ? colorScheme.error.withOpacity(0.2)
                  : colorScheme.primary.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: -4,
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: diagController.notificationsEnabled.value
                ? colorScheme.primary.withOpacity(0.08)
                : Colors.red.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  _buildIcon(colorScheme, diagController),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Notification Engine",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Verified: ${diagController.lastChecked.value}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showStatusPill(diagController),
                    child: _buildStatusBadge(diagController),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              diagController.isTesting.value
                  ? _buildProgressUI(colorScheme, diagController)
                  : _buildIdleButton(
                      diagController,
                      periodController,
                      colorScheme,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Conditional button UI for disabled state
  Widget _buildIdleButton(
    DiagnosticController diag,
    PeriodController period,
    ColorScheme colorScheme,
  ) {
    final isEnabled = diag.notificationsEnabled.value;
    final isMobile = GetPlatform.isMobile; // Check if platform is mobile

    if (!isEnabled && isMobile) {
      return Column(
        children: [
          const Text(
            "Notification is disabled. Please enable all notifications of Flowlytics in settings manually to run diagnostics.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_suggest_rounded),
              label: const Text("Go to settings"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        // Disable button click if not on mobile
        onPressed: isMobile
            ? () => diag.startDiagnostic(period.userName.value)
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.bolt_rounded),
        label: Text(
          isMobile
              ? "Run System Check (15s)"
              : "System checks unavailable on desktop",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme, DiagnosticController controller) {
    final enabled = controller.notificationsEnabled.value;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.primary.withOpacity(0.08)
            : Colors.red.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        enabled ? Icons.sync_lock_rounded : Icons.notifications_off_rounded,
        color: enabled ? colorScheme.primary : Colors.redAccent,
      ),
    );
  }

  Widget _buildStatusBadge(DiagnosticController controller) {
    final enabled = controller.notificationsEnabled.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        enabled ? "ACTIVE" : "DISABLED",
        style: TextStyle(
          color: enabled ? Colors.green : Colors.redAccent,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressUI(
    ColorScheme colorScheme,
    DiagnosticController controller,
  ) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: controller.progress.value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.error,
          backgroundColor: colorScheme.error.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Kill app & lock screen now!",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            Text(
              "${controller.secondsRemaining.value}s",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showStatusPill(DiagnosticController controller) {
    if (!controller.notificationsEnabled.value) return;
    HapticFeedback.selectionClick();
    Get.rawSnackbar(
      messageText: const Text(
        "Notifications Active",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.9),
      borderRadius: 50,
      margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      duration: const Duration(seconds: 2),
    );
  }
}
