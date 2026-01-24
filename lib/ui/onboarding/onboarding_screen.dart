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

  // Total pages increased from 4 to 5
  final int _totalPages = 5;

  void _nextPage() {
    // Adjusted index for new total pages (Last index is now 4)
    if (_currentPage < _totalPages - 1) {
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
          backgroundColor: Colors.transparent,
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
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _previousPage();
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
                _buildSecurityInfoStep(),
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
                    padding: const EdgeInsets.only(left: 10, top: 5),
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
          // Updated condition for the last page index
          label: Text(
            _currentPage == _totalPages - 1 ? "Start Journey" : "Continue",
          ),
          icon: Icon(
            _currentPage == _totalPages - 1
                ? Icons.favorite_rounded
                : Icons.arrow_forward,
          ),
        ),
      ),
    );
  }

  Widget _buildTopProgress() {
    // Get the total available width for the progress bar
    double totalWidth =
        MediaQuery.of(context).size.width -
        120; // 120 accounts for horizontal padding (60+60)

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
        child: Container(
          height: 6,
          width: totalWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                // Calculate width: (Current Page + 1) / Total Pages
                width: totalWidth * ((_currentPage + 1) / _totalPages),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Welcome Screen
  Widget _buildWelcomeStep() {
    return _buildStepLayout(
      icon: Icons.auto_awesome_rounded,
      title: "Flowlytics for You",
      description:
          "Flowlytics uses on-device adaptive Machine Learning algorithm to learn your body's unique patterns.\n\nNo clouds, no tracking, just a smart companion that lives entirely on your device.",
    );
  }

  // Security Info Screen
  Widget _buildSecurityInfoStep() {
    return _buildStepLayout(
      icon: Icons.lock_outline_rounded,
      title: "Privacy & Security",
      description:
          "Your privacy is Flowlytics priority. An optional App Lock feature is available for you to enable at any time in:\n\nMe -> Privacy & Security -> App Lock",
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Security Disclaimer",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Please note that no app lock is 100% secured. If you choose to use Fingerprint or Facial ID, you are responsible for maintaining the security of those biometrics on your device.",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Identity Step
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

  // Period Step
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

  // Baseline Step
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
