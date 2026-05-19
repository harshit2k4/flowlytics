import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/controllers/security_controller.dart';

/// Reusable re-authentication gate for destructive or sensitive actions.
///
/// If the user has App Lock enabled, [require] shows a PIN prompt and
/// resolves to `true` only if the PIN is verified. If App Lock is not
/// enabled, there is nothing to re-check against, so it resolves to
/// `true` immediately.
///
/// Intended for any action that should not be reachable with a single
/// accidental tap on an unlocked device (e.g. wiping all data). Not tied
/// to any single screen so it can be reused wherever that need comes up.
class SecurityReauthGate {
  static Future<bool> require(
    BuildContext context, {
    String title = "Confirm Identity",
    String message = "Enter your PIN to continue.",
  }) async {
    final securityController = Get.find<SecurityController>();

    if (!securityController.isLockEnabled.value) {
      return true;
    }

    final bool? verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinReauthDialog(title: title, message: message),
    );

    return verified ?? false;
  }
}

class _PinReauthDialog extends StatefulWidget {
  final String title;
  final String message;

  const _PinReauthDialog({required this.title, required this.message});

  @override
  State<_PinReauthDialog> createState() => _PinReauthDialogState();
}

class _PinReauthDialogState extends State<_PinReauthDialog> {
  final SecurityController _securityController = Get.find<SecurityController>();
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text;

    if (pin.isEmpty) {
      setState(() => _error = "Enter your PIN.");
      return;
    }

    // verifyPin() refuses every attempt, including a correct one, while a
    // cooldown or hard lock is active. Report that state accurately
    // instead of letting it surface as "Incorrect PIN".
    if (_securityController.isHardLocked) {
      _pinController.clear();
      setState(
        () => _error = "Too many attempts. Use Forgot PIN on the lock screen.",
      );
      return;
    }

    final int cooldown = _securityController.getRemainingCooldownSeconds();
    if (cooldown > 0) {
      _pinController.clear();
      setState(
        () => _error = "Too many attempts. Try again in $cooldown seconds.",
      );
      return;
    }

    final bool success = _securityController.verifyPin(pin);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      _pinController.clear();
      setState(() => _error = "Incorrect PIN. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: "PIN",
              counterText: "",
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        FilledButton(onPressed: _submit, child: const Text("Confirm")),
      ],
    );
  }
}
