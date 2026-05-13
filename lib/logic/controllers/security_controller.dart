import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth

class SecurityController extends GetxController with WidgetsBindingObserver {
  final _settingsBox = Hive.box('settings_box');
  final LocalAuthentication _auth = LocalAuthentication(); // Auth instance

  var isLocked = false.obs;
  var isLockEnabled = false.obs;
  var useBiometrics = false.obs;
  var failedAttempts = 0.obs;

  // Hardware capabilities
  var canCheckBiometrics = false.obs;

  // Cooldown Tracking
  var lockoutEndTime = Rxn<DateTime>();

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    isLockEnabled.value = _settingsBox.get(
      'is_lock_enabled',
      defaultValue: false,
    );
    useBiometrics.value = _settingsBox.get(
      'use_biometrics',
      defaultValue: false,
    );
    failedAttempts.value = _settingsBox.get('failed_attempts', defaultValue: 0);

    // Load saved lockout time
    final savedTime = _settingsBox.get('lockout_end_time');
    if (savedTime != null) {
      lockoutEndTime.value = DateTime.parse(savedTime);
    }

    // Check hardware support immediately
    await _checkBiometricSupport();

    if (isLockEnabled.value) isLocked.value = true;
  }

  // --- BIOMETRIC LOGIC ---

  Future<void> _checkBiometricSupport() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();
      canCheckBiometrics.value = canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint("Biometric support check failed: $e");
      canCheckBiometrics.value = false;
    }
  }

  // Future<bool> authenticateUser() async {
  //   // 1. Security Check: Don't allow biometrics if user is in cooldown
  //   if (getRemainingCooldownSeconds() > 0) return false;

  //   // 2. Hardware Check
  //   if (!canCheckBiometrics.value || !useBiometrics.value) return false;

  //   try {
  //     final bool didAuthenticate = await _auth.authenticate(
  //       localizedReason: 'Scan to unlock Flowlytics',
  //       options: const AuthenticationOptions(
  //         stickyAuth:
  //             true, // Keeps prompt active if app goes background briefly
  //         biometricOnly: true, // Don't allow device PIN (fallback to App PIN)
  //       ),
  //     );

  //     if (didAuthenticate) {
  //       _resetAttempts();
  //       isLocked.value = false;
  //       return true;
  //     }
  //   } on PlatformException catch (e) {
  //     debugPrint("Auth Error: $e");
  //     // If error (e.g. user canceled), we just return false and let them use PIN
  //     return false;
  //   }
  //   return false;
  // }

  Future<bool> authenticateUser({bool force = false}) async {
    // 1. Security Check: Never allow during cooldown
    if (getRemainingCooldownSeconds() > 0) return false;

    // 2. Hardware Check
    if (!canCheckBiometrics.value) return false;

    // 3. Preference Check:
    // Respect user setting UNLESS we are forcing it for initial setup verification
    if (!force && !useBiometrics.value) return false;

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Verify identity for Flowlytics',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        _resetAttempts();
        // Unlock the app if we were at the global lock screen
        if (isLocked.value) isLocked.value = false;
        return true;
      }
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
      return false;
    }
    return false;
  }

  void toggleBiometrics(bool value) {
    useBiometrics.value = value;
    _settingsBox.put('use_biometrics', value);
  }

  // --- EXISTING LOGIC ---

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isLockEnabled.value && state == AppLifecycleState.paused) {
      isLocked.value = true;
    }
  }

  String get securityQuestion =>
      _settingsBox.get('security_question', defaultValue: "No question set");

  bool get isHardLocked => failedAttempts.value >= 7;

  int getRemainingCooldownSeconds() {
    if (lockoutEndTime.value == null) return 0;
    final diff = lockoutEndTime.value!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool verifyPin(String inputPin) {
    if (getRemainingCooldownSeconds() > 0) return false;

    final storedHash = _settingsBox.get('app_pin');
    if (_hashPin(inputPin) == storedHash) {
      _resetAttempts();
      isLocked.value = false;
      return true;
    } else {
      failedAttempts.value++;
      _settingsBox.put('failed_attempts', failedAttempts.value);
      _calculateCooldown();
      return false;
    }
  }

  void _calculateCooldown() {
    int seconds = 0;
    if (failedAttempts.value == 3)
      seconds = 30;
    else if (failedAttempts.value == 4)
      seconds = 60;
    else if (failedAttempts.value == 5)
      seconds = 300;
    else if (failedAttempts.value == 6)
      seconds = 600;

    if (seconds > 0) {
      final end = DateTime.now().add(Duration(seconds: seconds));
      lockoutEndTime.value = end;
      _settingsBox.put('lockout_end_time', end.toIso8601String());
    }
  }

  void _resetAttempts() {
    failedAttempts.value = 0;
    _settingsBox.put('failed_attempts', 0);
    lockoutEndTime.value = null;
    _settingsBox.delete('lockout_end_time');
  }

  bool verifyRecoveryAnswer(String inputAnswer) {
    final storedAnswerHash = _settingsBox.get('security_answer');
    if (_hashPin(inputAnswer.toLowerCase().trim()) == storedAnswerHash) {
      _resetAttempts();
      isLocked.value = false;
      return true;
    }
    return false;
  }

  Future<void> savePin(String pin, String question, String answer) async {
    await _settingsBox.put('app_pin', _hashPin(pin));
    await _settingsBox.put('security_question', question);
    await _settingsBox.put(
      'security_answer',
      _hashPin(answer.toLowerCase().trim()),
    );
    await _settingsBox.put('is_lock_enabled', true);
    isLockEnabled.value = true;
    _resetAttempts();
  }

  Future<void> resetSecurity() async {
    await _settingsBox.delete('app_pin');
    await _settingsBox.delete('security_question');
    await _settingsBox.delete('security_answer');
    await _settingsBox.put('is_lock_enabled', false);
    // Also reset biometric preference
    await _settingsBox.put('use_biometrics', false);
    useBiometrics.value = false;

    isLockEnabled.value = false;
    isLocked.value = false;
    _resetAttempts();
  }

  String _hashPin(String pin) {
    const String salt = "flowlytics_security_core_2024_@#!";
    return sha256.convert(utf8.encode(pin + salt)).toString();
  }
}
