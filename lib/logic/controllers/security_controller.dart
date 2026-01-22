import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityController extends GetxController with WidgetsBindingObserver {
  final _settingsBox = Hive.box('settings_box');

  var isLocked = false.obs;
  var isLockEnabled = false.obs;
  var useBiometrics = false.obs;
  var failedAttempts = 0.obs;

  // Cooldown Tracking
  var lockoutEndTime = Rxn<DateTime>();

  @override
  void onInit() {
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

    // PERSISTENCE: Load saved lockout time
    final savedTime = _settingsBox.get('lockout_end_time');
    if (savedTime != null) {
      lockoutEndTime.value = DateTime.parse(savedTime);
    }

    if (isLockEnabled.value) isLocked.value = true;
  }

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
      // PERSISTENCE: Save to Hive
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
    isLockEnabled.value = false;
    isLocked.value = false;
    _resetAttempts();
  }

  String _hashPin(String pin) {
    const String salt = "flowlytics_security_core_2024_@#!";
    return sha256.convert(utf8.encode(pin + salt)).toString();
  }
}
