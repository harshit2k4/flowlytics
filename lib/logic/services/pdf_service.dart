import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/daily_log.dart';
import '../controllers/period_controller.dart';
import '../../ui/widgets/glass_snackbar.dart';

class PdfService {
  static Future<void> generateWellnessReport(
    BuildContext context,
    PeriodController controller,
  ) async {
    try {
      final pdf = pw.Document();

      // Offline Fonts
      final fontData = await rootBundle.load(
        "assets/fonts/CrimsonText-Regular.ttf",
      );
      final fontBoldData = await rootBundle.load(
        "assets/fonts/CrimsonText-Bold.ttf",
      );
      final fontItalicData = await rootBundle.load(
        "assets/fonts/CrimsonText-Italic.ttf",
      );

      final baseFont = pw.Font.ttf(fontData);
      final boldFont = pw.Font.ttf(fontBoldData);
      final italicFont = pw.Font.ttf(fontItalicData);

      // Data Prep
      final String rawName = controller.userName.value;
      final String name = (rawName.isEmpty || rawName == "Beautiful Girl")
          ? "My Wellness"
          : rawName;
      final String fullTimestamp = DateFormat(
        "EEEE, MMMM d, yyyy 'at' hh:mm a",
      ).format(DateTime.now());

      // History Filtering (Latest 24 logs)
      final historicalLogs = controller.allLogs.take(24).toList();

      // Vibe Data Fetching
      final dailyBox = Hive.box<DailyLog>('daily_box');
      final recentDailyLogs = dailyBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final displayedVibes = recentDailyLogs
          .take(30)
          .toList(); // Up to a month of moods

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            italic: italicFont,
          ),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(60),
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        "Notice: This personal summary contains sensitive information. Flowlytics operates as an offline tool; once exported, Flowlytics assumes no responsibility for data security. \n${AppStrings.medicalDisclaimer}",
                        style: const pw.TextStyle(
                          fontSize: 6.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      "Page ${context.pageNumber} of ${context.pagesCount}",
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // HEADER
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "${name.toUpperCase()}'S PERSONAL SUMMARY",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      "A private record of historical wellness observations.",
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      fullTimestamp,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Container(height: 0.5, color: PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // SECTION 1: CYCLE NARRATIVE
              _buildSectionHeader("Historical Entries"),
              _buildCycleTable(historicalLogs, controller),

              pw.SizedBox(height: 40),

              // SECTION 2: DAILY OBSERVATIONS (Moods restored)
              if (displayedVibes.isNotEmpty) ...[
                _buildSectionHeader("Daily Observations"),
                pw.Text(
                  "Summary of logged moods, energy, and physical symptoms.",
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildVibeTable(displayedVibes),
              ],
            ];
          },
        ),
      );

      final String safeName = name
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${safeName}_Personal_Summary',
      );
    } catch (e) {
      if (context.mounted) {
        GlassSnackbar.show(
          context,
          "Export failed.",
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, width: 20, color: PdfColors.black),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildCycleTable(
    List historicalLogs,
    PeriodController controller,
  ) {
    return pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        top: pw.BorderSide(width: 0.8),
        bottom: pw.BorderSide(width: 0.8),
        horizontalInside: pw.BorderSide(width: 0.1, color: PdfColors.grey400),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      data: List<List<String>>.generate(historicalLogs.length, (index) {
        final log = historicalLogs[index];
        String interval = "--";
        if (index < controller.allLogs.length - 1) {
          interval =
              "${log.startDate.difference(controller.allLogs[index + 1].startDate).inDays.abs()} Days";
        }
        final int duration = log.endDate.difference(log.startDate).inDays + 1;

        return [
          DateFormat('MMM dd, yyyy').format(log.startDate),
          DateFormat('MMM dd, yyyy').format(log.endDate),
          "$duration Days",
          interval,
        ];
      }),
      headers: ['START DATE', 'END DATE', 'DURATION', 'INTERVAL'],
    );
  }

  static pw.Widget _buildVibeTable(List<DailyLog> logs) {
    return pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        top: pw.BorderSide(width: 0.8),
        bottom: pw.BorderSide(width: 0.8),
        horizontalInside: pw.BorderSide(width: 0.1, color: PdfColors.grey400),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      data: logs.map((log) {
        String vibes = [
          if (log.moods.isNotEmpty) log.moods.join(", "),
          if (log.physical.isNotEmpty) log.physical.join(", "),
        ].join(" • ");
        return [
          DateFormat('MMM dd').format(log.date),
          vibes.isEmpty ? "Balanced" : vibes,
          log.flow.isNotEmpty ? log.flow.first : "—",
        ];
      }).toList(),
      headers: ['DATE', 'MOOD & PHYSICAL VIBE', 'FLOW'],
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1),
      },
    );
  }
}
