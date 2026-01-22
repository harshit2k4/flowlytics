/** 
 * This is the "Interceptor." It sits between the App and the Operating System. 
 * It checks isLocked and decides whether to show the App or the Lock Screen.
*/

import 'package:flowlytics/ui/security/global_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/security_controller.dart';

class SecurityGuard extends StatelessWidget {
  final Widget? child;

  const SecurityGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // If the child is null (shouldn't happen in builder), return empty
    if (child == null) return const SizedBox.shrink();

    final securityController = Get.find<SecurityController>();

    return Stack(
      children: [
        // The Actual App (Navigator, Pages, Dialogs)
        child!,

        // The Lock Screen Overlay
        // Obx listens to the lock state changes instantly
        Obx(() {
          if (securityController.isLocked.value) {
            return const GlobalLockScreen();
          } else {
            // When unlocked, remove overlay completely so touches go through
            return const SizedBox.shrink();
          }
        }),
      ],
    );
  }
}
