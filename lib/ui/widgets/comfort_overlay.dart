import 'dart:ui';
import 'package:flowlytics/logic/controllers/period_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

/// This shows the supportive animated companion.
/// It adapts its message based on the user's current cycle status.
class ComfortOverlay extends StatelessWidget {
  final String status;

  const ComfortOverlay({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // --- PERSONALIZATION LOGIC ---
    final PeriodController periodController = Get.find<PeriodController>();
    final String name = periodController.userName.value.trim();
    final bool isCustomName = name.isNotEmpty && name != "Beautiful Girl";

    // --- YOUR ORIGINAL MESSAGES ---
    String title = "A GENTLE REMINDER";
    String message = isCustomName
        ? "$name, get ready, your periods are on the way. Stock up on pads and the food you love! 🍫"
        : "Get ready, your periods are on the way. Stock up on pads and the food you love! 🍫";

    if (status == 'active') {
      title = "YOU'RE DOING GREAT";
      message = isCustomName
          ? "$name, hang in there. Remember to stay hydrated and take it easy today. ☕"
          : "Hang in there, beautiful. Remember to stay hydrated and take it easy today. ☕";
    } else if (status == 'wellness') {
      title = "POWER PHASE";
      message = isCustomName
          ? "$name, you're in your power phase! You look glowing today; go conquer the world. ✨"
          : "You're in your power phase! You look glowing today; go conquer the world. ✨";
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // for the blur to show background
      body: Stack(
        children: [
          // Screen blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: colorScheme.surface.withOpacity(0.5)),
          ),

          // UI content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The Animation Container
                SizedBox(
                  height: 370,
                  child: Lottie.asset(
                    'assets/animations/cat_animation.json',
                    repeat: true,
                    frameRate: FrameRate.composition,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.spa_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // The Message Bubble
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Dismiss button
                SizedBox(
                  width: 160,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: StadiumBorder(),
                    ),
                    child: const Text(
                      "I'm ready",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
