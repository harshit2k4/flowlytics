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
  static final _iv = enc.IV.fromUtf8(SecurityConfig.backupIv);

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
      final encrypted = encrypter.encrypt(jsonEncode(data), iv: _iv);
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
          await file.writeAsBytes(encrypted.bytes, flush: true);
          debugPrint("Backup: Saved to ${file.path}");
          return true;
        }
      } else {
        // Mobile fallback using Share Sheet
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/backup.flytx');
        await file.writeAsBytes(encrypted.bytes);
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
      final Uint8List encryptedBytes =
          result.files.single.bytes ??
          await File(result.files.single.path!).readAsBytes();

      debugPrint(
        "Backup: File loaded (${encryptedBytes.length} bytes). Decrypting...",
      );

      final encrypter = enc.Encrypter(enc.AES(_key));
      final decrypted = encrypter.decrypt(
        enc.Encrypted(encryptedBytes),
        iv: _iv,
      );

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
}
