import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlassSnackbar {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle,
  }) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 3),
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
                  icon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
