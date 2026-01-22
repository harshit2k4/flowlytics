import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/security_controller.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final SecurityController _securityController = Get.find<SecurityController>();

  String _pin = "";
  String _tempPin = "";
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _recoveryInputController =
      TextEditingController();

  late String _viewState;
  Timer? _cooldownTimer;
  int _displayCooldown = 0;

  @override
  void initState() {
    super.initState();
    _viewState = _securityController.isLockEnabled.value
        ? 'verify'
        : 'setup_pin';
    _startCooldownListener();
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
    super.dispose();
  }

  void _showGlassSnackBar(String message, {bool isError = false}) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: (isError ? Colors.red : Colors.white).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  void _onNumberPress(String number) {
    if (_displayCooldown > 0 || _securityController.isHardLocked) return;
    if (_pin.length < 6) setState(() => _pin += number);

    if (_pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_viewState == 'verify') {
          if (_securityController.verifyPin(_pin)) {
            setState(() {
              _pin = "";
              _viewState = 'manage';
            });
          } else {
            setState(() => _pin = "");
            _showGlassSnackBar(
              _securityController.isHardLocked
                  ? "Locked. Use ID Verification."
                  : "Incorrect PIN",
              isError: true,
            );
          }
        } else if (_viewState == 'setup_pin') {
          _tempPin = _pin;
          setState(() {
            _pin = "";
            _viewState = 'confirm_pin';
          });
        } else if (_viewState == 'confirm_pin') {
          if (_pin == _tempPin) {
            setState(() => _viewState = 'setup_recovery');
          } else {
            setState(() => _pin = "");
            _showGlassSnackBar("PINs do not match", isError: true);
            setState(() => _viewState = 'setup_pin');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(colorScheme),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Expanded(child: _buildBody(colorScheme)),
                  if ([
                    'verify',
                    'setup_pin',
                    'confirm_pin',
                  ].contains(_viewState))
                    _buildNumericPad(colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    switch (_viewState) {
      case 'verify':
        return _buildLockScreen(colorScheme);
      case 'setup_pin':
        return _buildStatusHeader(
          "Create PIN",
          "Set a 6-digit access code",
          Icons.lock_outline,
        );
      case 'confirm_pin':
        return _buildStatusHeader(
          "Confirm PIN",
          "Repeat the code to confirm",
          Icons.lock_reset,
        );
      case 'setup_recovery':
        return _buildRecoveryForm(colorScheme, true);
      case 'recovery_flow':
        return _buildRecoveryForm(colorScheme, false);
      case 'manage':
        return _buildManageDashboard(colorScheme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildLockScreen(ColorScheme colorScheme) {
    bool isHard = _securityController.isHardLocked;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isHard ? Icons.gpp_bad : Icons.shield,
          size: 60,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          isHard ? "System Locked" : "Passcode Required",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (_displayCooldown > 0)
          Text(
            "Retry in $_displayCooldown seconds",
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            isHard
                ? "Use Identity Verification to reset"
                : "Enter your PIN to continue",
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 48),
        _buildPinDots(colorScheme),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => setState(() => _viewState = 'recovery_flow'),
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

  Widget _buildRecoveryForm(ColorScheme colorScheme, bool isSetup) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          _buildStatusHeader(
            isSetup ? "Security Question" : "Identity Check",
            isSetup
                ? "Recover access if you forget your PIN"
                : "Answer your question to unlock",
            Icons.fingerprint,
          ),
          const SizedBox(height: 40),
          if (!isSetup) ...[
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
            const SizedBox(height: 24),
          ],
          _buildGlassyField(
            isSetup ? _questionController : null,
            isSetup ? "Question" : null,
            isSetup ? "e.g. Favorite person" : null,
            colorScheme,
            isLabelOnly: !isSetup,
          ),
          if (isSetup) const SizedBox(height: 16),
          _buildGlassyField(
            isSetup ? _answerController : _recoveryInputController,
            "Your Answer",
            "Type here...",
            colorScheme,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton(
              onPressed: () {
                if (isSetup) {
                  _securityController.savePin(
                    _tempPin,
                    _questionController.text,
                    _answerController.text,
                  );
                  Get.back();
                  _showGlassSnackBar("Security Active");
                } else {
                  if (_securityController.verifyRecoveryAnswer(
                    _recoveryInputController.text,
                  )) {
                    setState(() {
                      _pin = "";
                      _viewState = 'setup_pin';
                    });
                    _showGlassSnackBar("Verified. Set new PIN.");
                  } else {
                    _showGlassSnackBar("Verification Failed", isError: true);
                  }
                }
              },
              child: Text(isSetup ? "Complete Setup" : "Verify & Reset"),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI REFINEMENTS ---

  Widget _buildNumericPad(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
                SizedBox(
                  width: 80,
                  height: 80,
                  child: IconButton(
                    onPressed: () => _showBiometricDisclaimer(colorScheme),
                    icon: Icon(
                      Icons.fingerprint,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                _buildNumBtn("0", colorScheme),
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

  Widget _buildGlassyField(
    TextEditingController? ctrl,
    String? label,
    String? hint,
    ColorScheme colorScheme, {
    bool isLabelOnly = false,
  }) {
    if (isLabelOnly) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String title, String sub, IconData icon) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 50, color: Get.theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        _buildPinDots(Get.theme.colorScheme),
      ],
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
            border: Border.all(
              color: index < _pin.length
                  ? Colors.transparent
                  : colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageDashboard(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 70, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "App Lock Active",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        _buildInfoBox(
          // "Biometric access is tied to your system. Disabling this reset all security data.",
          "Facial ID and Fingerprint authentication are provided by your device, not this app. By enabling biometric access, you agree that you alone are responsible for the security of your data, and Flowlytics bear no responsibility for misuse, compromise, or unauthorized access.",
          colorScheme,
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () =>
              _securityController.resetSecurity().then((_) => Get.back()),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 60),
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text(
            "Disable App Lock",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildInfoBox(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  void _showBiometricDisclaimer(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint, color: colorScheme.primary, size: 40),
                const SizedBox(height: 16),
                const Text(
                  "Biometric Link",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This allows using your phone's biometrics. Anyone with a fingerprint registered here can access all your data.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("I Accept"),
                ),
              ],
            ),
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
