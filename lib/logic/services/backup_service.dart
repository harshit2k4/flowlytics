import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flowlytics/keys/security_config.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/period_log.dart';

class BackupService {
  static final _key = enc.Key.fromUtf8(SecurityConfig.backupKey);

  // The original, fixed IV. Only used to read backups exported before the
  // random-IV format existed. Never used to encrypt anything new.
  static final _legacyIv = enc.IV.fromUtf8(SecurityConfig.backupIv);

  // Current file layout: [4-byte marker][16-byte random IV][ciphertext].
  // Files without this marker are treated as the original layout: the
  // whole file is ciphertext, encrypted with the fixed legacy IV above.
  // The marker doubles as a format version, so a future change can use a
  // different one (e.g. FLX3) without breaking this check.
  static final List<int> _formatMarker = utf8.encode('FLX2');
  static const int _ivLength = 16;

  static Future<bool> exportLogs() async {
    debugPrint("Backup: Export process started");
    try {
      final periodBox = Hive.box<PeriodLog>('period_box');
      final dailyBox = Hive.box<DailyLog>('daily_box');

      final data = {
        'type': 'flowlytics_backup',
        'periods': periodBox.values
            .map(
              (e) => {
                'start': e.startDate.toIso8601String(),
                'end': e.endDate.toIso8601String(),
              },
            )
            .toList(),
        'daily': dailyBox.values
            .map(
              (e) => {
                'date': e.date.toIso8601String(),
                'moods': e.moods,
                'physical': e.physical,
                'skin': e.skin,
                'flow': e.flow,
                'sleep': e.sleep,
              },
            )
            .toList(),
      };

      final encrypter = enc.Encrypter(enc.AES(_key));

      // A new random IV for every export. An IV is not secret, it only has
      // to be unique per encryption, so it travels inside the file. Reusing
      // one fixed IV made the start of every backup ever exported encrypt
      // to identical bytes.
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypted = encrypter.encrypt(jsonEncode(data), iv: iv);
      final Uint8List outputBytes = Uint8List.fromList([
        ..._formatMarker,
        ...iv.bytes,
        ...encrypted.bytes,
      ]);
      debugPrint(
        "Backup: Encryption successful (${_key.bytes.length * 8} bits)",
      );

      if (Platform.isLinux) {
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Encrypted Backup',
          fileName: 'my_cycle_logs.flytx',
          type: FileType.any,
        );

        if (outputPath != null) {
          final file = File(
            outputPath.endsWith('.flytx') ? outputPath : '$outputPath.flytx',
          );
          await file.writeAsBytes(outputBytes, flush: true);
          debugPrint("Backup: Saved to ${file.path}");
          return true;
        }
      } else {
        // Mobile fallback using Share Sheet
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/backup.flytx');
        await file.writeAsBytes(outputBytes);
        final result = await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Backup');
        return result.status == ShareResultStatus.success;
      }
      return false;
    } catch (e, stack) {
      debugPrint("Backup Error: $e\n$stack");
      return false;
    }
  }

  static Future<bool> importLogs() async {
    debugPrint("Backup: Import process started");
    try {
      // Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true, // Crucial for Android/iOS to read bytes directly
      );

      if (result == null) {
        debugPrint("Backup: User cancelled file picking");
        return false;
      }

      // Get the encrypted bytes:
      // First try bytes directly (Mobile/Web)
      // then fallback to reading the path (Desktop)
      final Uint8List fileBytes =
          result.files.single.bytes ??
          await File(result.files.single.path!).readAsBytes();

      debugPrint(
        "Backup: File loaded (${fileBytes.length} bytes). Decrypting...",
      );

      // Pick the layout: current files start with the format marker and
      // carry their own IV; anything else is a backup from before that
      // existed and uses the fixed legacy IV over the whole file.
      final bool hasMarker = _startsWithMarker(fileBytes);
      final enc.IV iv;
      final Uint8List cipherBytes;

      if (hasMarker && fileBytes.length > _formatMarker.length + _ivLength) {
        final ivStart = _formatMarker.length;
        final cipherStart = ivStart + _ivLength;
        iv = enc.IV(
          Uint8List.fromList(fileBytes.sublist(ivStart, cipherStart)),
        );
        cipherBytes = Uint8List.fromList(fileBytes.sublist(cipherStart));
      } else {
        iv = _legacyIv;
        cipherBytes = fileBytes;
      }

      final encrypter = enc.Encrypter(enc.AES(_key));
      final decrypted = encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);

      final Map<String, dynamic> data = jsonDecode(decrypted);

      // Validation: Ensure it's a Flowlytics file
      if (data['type'] != 'flowlytics_backup') {
        debugPrint("Backup: Invalid file type");
        return false;
      }

      final periodBox = Hive.box<PeriodLog>('period_box');
      final dailyBox = Hive.box<DailyLog>('daily_box');

      // Wipe current data before restoration
      await periodBox.clear();
      await dailyBox.clear();

      // Restore Periods
      for (var p in data['periods']) {
        await periodBox.add(
          PeriodLog(
            startDate: DateTime.parse(p['start']),
            endDate: DateTime.parse(p['end']),
          ),
        );
      }

      // Restore Daily Logs
      for (var d in data['daily']) {
        await dailyBox.add(
          DailyLog(
            date: DateTime.parse(d['date']),
            moods: List<String>.from(d['moods']),
            physical: List<String>.from(d['physical']),
            skin: List<String>.from(d['skin']),
            flow: List<String>.from(d['flow']),
            sleep: List<String>.from(d['sleep'] ?? []),
          ),
        );
      }

      debugPrint(
        "Backup: Restoration successful. ${periodBox.length} periods restored.",
      );
      return true;
    } catch (e, stack) {
      debugPrint("Backup Import Error: $e");
      debugPrint("STACKTRACE: $stack");
      return false;
    }
  }

  static bool _startsWithMarker(Uint8List bytes) {
    if (bytes.length < _formatMarker.length) return false;
    for (int i = 0; i < _formatMarker.length; i++) {
      if (bytes[i] != _formatMarker[i]) return false;
    }
    return true;
  }
}
