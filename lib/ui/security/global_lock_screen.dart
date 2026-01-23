/**
 * This is a stripped-down version of AppLock screen. 
 * It removes the "Back" button and "Setup" logic, strictly focusing on the Unlock and Cooldown UI.
 */
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/security_controller.dart';

class GlobalLockScreen extends StatefulWidget {
  const GlobalLockScreen({super.key});

  @override
  State<GlobalLockScreen> createState() => _GlobalLockScreenState();
}

class _GlobalLockScreenState extends State<GlobalLockScreen> {
  final SecurityController _securityController = Get.find<SecurityController>();
  String _pin = "";

  // Recovery State
  bool _isRecovering = false;
  final TextEditingController _recoveryInputController =
      TextEditingController();
  // Inline error state instead of Snackbar for foolproof visibility
  String? _recoveryError;

  // Cooldown UI
  Timer? _cooldownTimer;
  int _displayCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startCooldownListener();

    // Only auto-trigger if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_securityController.useBiometrics.value) {
        _triggerBiometric();
      }
    });
  }

  Future<void> _triggerBiometric() async {
    await _securityController.authenticateUser();
  }

  void _startCooldownListener() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final rem = _securityController.getRemainingCooldownSeconds();
      if (rem != _displayCooldown) setState(() => _displayCooldown = rem);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _recoveryInputController.dispose();
    super.dispose();
  }

  void _onNumberPress(String number) {
    if (_displayCooldown > 0 ||
        _securityController.isHardLocked ||
        _isRecovering)
      return;

    if (_pin.length < 6) setState(() => _pin += number);

    if (_pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_securityController.verifyPin(_pin)) {
          setState(() => _pin = "");
        } else {
          setState(() => _pin = "");
          // Optional haptic feedback
        }
      });
    }
  }

  // Helper to cleanly reset recovery state
  void _closeRecovery() {
    setState(() {
      _isRecovering = false;
      _recoveryInputController.clear();
      _recoveryError = null; // Clear error
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            _buildBackground(colorScheme),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Expanded(
                      child: _isRecovering
                          ? _buildRecoveryUI(colorScheme)
                          : _buildLockUI(colorScheme),
                    ),
                    // Only show pad if NOT recovering
                    if (!_isRecovering) _buildNumericPad(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockUI(ColorScheme colorScheme) {
    bool isHard = _securityController.isHardLocked;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isHard ? Icons.gpp_bad : Icons.lock,
          size: 60,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          isHard ? "Security Lockdown" : "Flowlytics Locked",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (_displayCooldown > 0)
          Text(
            "Try again in $_displayCooldown seconds",
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            isHard
                ? "Too many attempts. Verify Identity."
                : "Enter PIN to access your data",
            style: const TextStyle(color: Colors.grey),
          ),

        const SizedBox(height: 48),
        _buildPinDots(colorScheme),
        const SizedBox(height: 32),

        TextButton(
          onPressed: () {
            setState(() {
              _isRecovering = true;
              _recoveryInputController.clear();
              _recoveryError = null;
            });
          },
          child: Text(
            "Forgot PIN?",
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryUI(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          IconButton(
            onPressed: _closeRecovery,
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 20),
          const Text(
            "Identity Verification",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            "Answer your security question to unlock.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          const Text(
            "QUESTION",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _securityController.securityQuestion,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              // Highlight red if error
              border: _recoveryError != null
                  ? Border.all(color: Colors.red.withOpacity(0.5))
                  : null,
            ),
            child: TextField(
              // ValueKey ensures the TextField is totally replaced on rebuilds,
              // breaking the connection to the OS keyboard buffer to stop text duplication.
              key: const ValueKey("recovery_field"),
              controller: _recoveryInputController,
              decoration: const InputDecoration(
                labelText: "Your Answer",
                border: InputBorder.none,
              ),
              onChanged: (_) {
                if (_recoveryError != null)
                  setState(() => _recoveryError = null);
              },
            ),
          ),

          // Inline Error Message
          if (_recoveryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _recoveryError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: () {
                if (_securityController.verifyRecoveryAnswer(
                  _recoveryInputController.text,
                )) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _recoveryInputController.clear();
                  setState(() {
                    _isRecovering = false;
                    _pin = "";
                    _recoveryError = null;
                  });
                } else {
                  // Clear immediately on error so old text doesn't persist
                  _recoveryInputController.clear();
                  setState(() {
                    _recoveryError = "Incorrect Answer. Try again.";
                  });
                }
              },
              child: const Text("Unlock App"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericPad(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          for (var row in [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((n) => _buildNumBtn(n, colorScheme)).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // LEFT SLOT: Biometrics
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Obx(() {
                    bool visible =
                        _securityController.canCheckBiometrics.value &&
                        _securityController.useBiometrics.value;

                    // Use Visibility to maintain layout size perfectly without drawing pixels
                    return Visibility(
                      visible: visible,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: IconButton(
                        onPressed: _displayCooldown > 0
                            ? null
                            : () => _securityController.authenticateUser(),
                        icon: Icon(
                          Icons.fingerprint,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  }),
                ),

                _buildNumBtn("0", colorScheme),

                // RIGHT SLOT: Backspace
                SizedBox(
                  width: 80,
                  height: 80,
                  child: IconButton(
                    onPressed: () {
                      if (_pin.isNotEmpty)
                        setState(
                          () => _pin = _pin.substring(0, _pin.length - 1),
                        );
                    },
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String n, ColorScheme colorScheme) {
    bool disabled = _displayCooldown > 0 || _securityController.isHardLocked;
    return InkResponse(
      onTap: disabled ? null : () => _onNumberPress(n),
      radius: 40,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Text(
          n,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: disabled ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(ColorScheme colorScheme) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: colorScheme.primary.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}
