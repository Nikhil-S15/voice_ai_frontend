import 'package:flutter/material.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class ExportReportScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const ExportReportScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Report: $fileName'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export Contents', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildReportItem(
                    'Patient Profiles',
                    'Complete demographic and assessment data',
                  ),
                  _buildReportItem(
                    'Voice Recordings',
                    'All audio files in WAV format',
                  ),
                  _buildReportItem(
                    'VHI Scores',
                    'Voice Handicap Index analysis',
                  ),
                  _buildReportItem(
                    'Risk Factors',
                    'Identified risk factors and severity levels',
                  ),
                  _buildReportItem(
                    'Clinical Notes Template',
                    'Structured format for doctor annotations',
                  ),
                  _buildReportItem(
                    'Metadata',
                    'Export date, time range, and system information',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implement file sharing functionality
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(title, style: AppTextStyles.bodyBold),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
