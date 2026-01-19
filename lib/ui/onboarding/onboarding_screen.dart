import 'dart:ui';
import 'package:flowlytics/ui/notifications/notification_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../logic/controllers/period_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PeriodController controller = Get.find<PeriodController>();

  int _currentPage = 0;
  bool _disclaimerAccepted = false;

  String _name = "";
  DateTimeRange? _lastPeriod;
  int _usualCycle = 28;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (_disclaimerAccepted) {
        _finishOnboarding();
      } else {
        // Glassmorphic Snackbar
        Get.rawSnackbar(
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor:
              Colors.transparent, // Transparent to show the glass effect
          duration: const Duration(seconds: 3),
          messageText: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Please acknowledge the health disclaimer to continue",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    // controller.completeOnboarding(
    //   name: _name.isEmpty ? "Beautiful Girl" : _name,
    //   lastPeriod: _lastPeriod,
    //   usualCycle: _usualCycle,
    // );
    Get.to(
      () => NotificationPermissionScreen(
        name: _name.isEmpty ? "Beautiful Girl" : _name,
        lastPeriod: _lastPeriod,
        usualCycle: _usualCycle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _currentPage == 0, // Prevents the app from exiting from other screens
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _previousPage(); // Goes to previous onboarding slide instead of closing
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Theme.of(context).colorScheme.surface),
            ),
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomeStep(),
                _buildIdentityStep(),
                _buildPeriodStep(),
                _buildBaselineStep(),
              ],
            ),
            _buildTopProgress(),
            // Back Button
            if (_currentPage > 0)
              Positioned(
                top: 60,
                left: 20,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      top: 5,
                    ), // Uniform mobile padding
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _previousPage,
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _nextPage,
          label: Text(_currentPage == 3 ? "Start Journey" : "Continue"),
          icon: Icon(
            _currentPage == 3 ? Icons.favorite_rounded : Icons.arrow_forward,
          ),
        ),
      ),
    );
  }

  Widget _buildTopProgress() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
        child: LinearProgressIndicator(
          value: (_currentPage + 1) / 4,
          borderRadius: BorderRadius.circular(10),
          minHeight: 6,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  // First page: Welcome screen
  Widget _buildWelcomeStep() {
    return _buildStepLayout(
      icon: Icons.auto_awesome_rounded,
      title: "Flowlytics for You",
      description:
          "Flowlytics uses on-device adaptive Machine Learning algorithm to learn your body's unique patterns.\n\nNo clouds, no tracking, just a smart companion that lives entirely on your device.",
    );
  }

  // Second Page: Get name of user (optional)
  Widget _buildIdentityStep() {
    return _buildStepLayout(
      icon: Icons.favorite_border_rounded,
      title: "Heya! Beautiful Girl",
      description:
          "Every journey is personal. What should Flowlytics call you?",
      content: TextField(
        onChanged: (v) => _name = v,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Enter your name",
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Third Page: Get last known period duration from user (optional)
  Widget _buildPeriodStep() {
    return _buildStepLayout(
      icon: Icons.spa_rounded,
      title: "Your History",
      description:
          "To help the algorithm start learning, tell us when your last period was.",
      content: Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _lastPeriod = picked);
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              _lastPeriod == null ? "Select Dates" : "Recorded Perfectly",
            ),
          ),
          if (_lastPeriod != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                "${_lastPeriod!.start.day}/${_lastPeriod!.start.month} to ${_lastPeriod!.end.day}/${_lastPeriod!.end.month}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Fourth Page: Get cycle length of user and show health disclaimer
  Widget _buildBaselineStep() {
    return _buildStepLayout(
      icon: Symbols.query_stats_rounded,
      title: "The Baseline",
      description:
          "How many days does your cycle usually last? The algorithm will use this to calibrate your first predictions.",
      content: Column(
        children: [
          Text(
            "$_usualCycle Days",
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Slider(
            value: _usualCycle.toDouble(),
            min: 20,
            max: 40,
            divisions: 20,
            onChanged: (v) => setState(() => _usualCycle = v.toInt()),
          ),
          const SizedBox(height: 30),
          // THE DISCLAIMER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _disclaimerAccepted,
                  onChanged: (v) =>
                      setState(() => _disclaimerAccepted = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    "I understand that these are mathematical predictions and real biology may vary.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page layout design
  Widget _buildStepLayout({
    required IconData icon,
    required String title,
    required String description,
    Widget? content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 30),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          if (content != null) ...[const SizedBox(height: 40), content],
        ],
      ),
    );
  }
}
