import 'package:flowlytics/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Legal Disclaimer",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formal Notice of Data Ownership
            _buildFormalHeader(context, "Data Ownership & Offline Policy"),
            _buildFormalText(
              "Flowlytics is an offline-first application. No data is transmitted to remote servers. "
              "Consequently, the user is the sole custodian of their data. Loss of device or "
              "forgetting security credentials will result in permanent, unrecoverable data loss.",
            ),

            const SizedBox(height: 32),

            // Medical Disclaimer
            _buildFormalHeader(context, "Medical Information Disclaimer"),
            _buildFormalText(AppStrings.medicalDisclaimer),

            const SizedBox(height: 32),

            // Data Export Disclaimer
            _buildFormalHeader(context, "Liability & Data Sharing"),
            _buildFormalText(AppStrings.legalDisclaimer),

            const SizedBox(height: 48),

            // Footer
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  AppStrings.secretNote,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFormalHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormalText(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        content,
        style: const TextStyle(
          height: 1.7,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
