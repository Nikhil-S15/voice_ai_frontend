import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io'; // Add this line
import 'package:path_provider/path_provider.dart'; // Add this line

class EnhancedPatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String? patientName;

  const EnhancedPatientDetailScreen({
    Key? key,
    required this.patientId,
    this.patientName,
  }) : super(key: key);

  @override
  State<EnhancedPatientDetailScreen> createState() =>
      _EnhancedPatientDetailScreenState();
}

class _EnhancedPatientDetailScreenState
    extends State<EnhancedPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isExporting = false;
  Map<String, dynamic> _patientProfile = {};
  Map<String, dynamic> _analysisNotes = {};
  List<dynamic> _voiceRecordings = [];

  // Add these new state variables for assessment data
  Map<String, dynamic> _cancerAssessments = {};
  Map<String, dynamic> _voiceHandicapIndex = {};
  List<dynamic> _grbasRatings = [];

  // Clinical notes form controllers
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _priorityLevel = 'Medium';

  // Form controllers for editing patient info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Increase tab count to include assessment tabs
    _tabController = TabController(length: 6, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _diagnosisController.dispose();
    _treatmentPlanController.dispose();
    _followUpController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Helper methods for type conversion
  Map<String, dynamic> _convertToTypedMap(dynamic map) {
    if (map is Map<String, dynamic>) return map;
    if (map is Map) return Map<String, dynamic>.from(map);
    return {};
  }

  List<dynamic> _convertToList(dynamic list) {
    if (list is List<dynamic>) return list;
    if (list is List) return List<dynamic>.from(list);
    return [];
  }

  // Helper to format array data to string
  String _formatArray(dynamic arrayData, {String emptyText = 'None'}) {
    if (arrayData == null) return emptyText;
    if (arrayData is List)
      return arrayData.isEmpty ? emptyText : arrayData.join(', ');
    if (arrayData is String) return arrayData.isEmpty ? emptyText : arrayData;
    return emptyText;
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await ApiService.getPatientDetailedProfile(widget.patientId);

      if (response['success'] == true) {
        setState(() {
          _patientProfile = _convertToTypedMap(response['data'] ?? {});
          _analysisNotes = _convertToTypedMap(response['analysisNotes'] ?? {});
          _voiceRecordings =
              _convertToList(_patientProfile['voiceRecordings'] ?? []);

          // Load assessment data
          _cancerAssessments =
              _convertToTypedMap(_patientProfile['cancerAssessments'] ?? {});
          _voiceHandicapIndex =
              _convertToTypedMap(_patientProfile['voiceHandicapIndex'] ?? {});
          _grbasRatings = _convertToList(_patientProfile['grbasRatings'] ?? []);
        });

        final basicInfo = _convertToTypedMap(_patientProfile['basicInfo']);
        _nameController.text = basicInfo['participantName']?.toString() ?? '';
        _ageController.text = basicInfo['age']?.toString() ?? '';
        _genderController.text = basicInfo['gender']?.toString() ?? '';
        _contactController.text = basicInfo['contactNumber']?.toString() ?? '';
        _emailController.text = basicInfo['email']?.toString() ?? '';
      } else {
        _showErrorSnackBar(
            response['message']?.toString() ?? 'Failed to load patient data');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FIXED: Proper field name formatting
  String _formatFieldName(String fieldName) {
    // Handle common field name conversions
    final Map<String, String> fieldNameMap = {
      'userId': 'User ID',
      'participantName': 'Participant Name',
      'contactNumber': 'Contact Number',
      'registrationDate': 'Registration Date',
      'diagnosisConfirmed': 'Diagnosis Confirmed',
      'treatmentType': 'Treatment Type',
      'functionalSubscore': 'Functional Subscore',
      'physicalSubscore': 'Physical Subscore',
      'emotionalSubscore': 'Emotional Subscore',
      'totalScore': 'Total Score',
      'dateCompleted': 'Date Completed',
      // Add more field mappings as needed
    };

    // Return mapped name if available
    if (fieldNameMap.containsKey(fieldName)) {
      return fieldNameMap[fieldName]!;
    }

    // Fallback: Convert camelCase to Title Case with spaces
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAllMapped(
            RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase())
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is List) return value.join(', ');
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'Not provided';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: 8),
                Text(title, style: AppTextStyles.titleMedium),
              ],
            ),
            SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Add these new tab content builders for assessment data

  Widget _buildCancerAssessmentsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (_cancerAssessments['oralCancer'] != null)
            _buildCancerAssessmentCard(
                'Oral Cancer Assessment', _cancerAssessments['oralCancer']),
          if (_cancerAssessments['larynxHypopharynx'] != null) ...[
            SizedBox(height: 16),
            _buildCancerAssessmentCard('Larynx/Hypopharynx Assessment',
                _cancerAssessments['larynxHypopharynx']),
          ],
          if (_cancerAssessments['pharynxCancer'] != null) ...[
            SizedBox(height: 16),
            _buildCancerAssessmentCard('Pharynx Cancer Assessment',
                _cancerAssessments['pharynxCancer']),
          ],
          if (_cancerAssessments.isEmpty)
            _buildEmptyState('No cancer assessments completed'),
        ],
      ),
    );
  }

  Widget _buildCancerAssessmentCard(String title, dynamic assessmentData) {
    final assessment = _convertToTypedMap(assessmentData);
    if (assessment.isEmpty) return SizedBox();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headlineSmall),
            SizedBox(height: 16),
            ...assessment.entries
                .where((entry) => entry.value != null)
                .map((entry) {
              return _buildInfoRow(
                _formatFieldName(entry.key), // FIXED: This now returns a String
                _formatValue(entry.value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVHITab() {
    if (_voiceHandicapIndex.isEmpty)
      return _buildEmptyState('No VHI assessment completed');

    final scores = _convertToTypedMap(_voiceHandicapIndex['scores']);
    final detailedScores =
        _convertToTypedMap(_voiceHandicapIndex['detailedScores']);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice Handicap Index (VHI)',
                      style: AppTextStyles.headlineSmall),
                  SizedBox(height: 16),
                  if (scores.isNotEmpty) ...[
                    Text('Scores',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildInfoRow('Functional', scores['functional']),
                    _buildInfoRow('Physical', scores['physical']),
                    _buildInfoRow('Emotional', scores['emotional']),
                    _buildInfoRow('Total', scores['total']),
                    SizedBox(height: 12),
                  ],
                  if (_voiceHandicapIndex['severity'] != null)
                    _buildInfoRow('Severity', _voiceHandicapIndex['severity']),
                  if (_voiceHandicapIndex['dateCompleted'] != null)
                    _buildInfoRow('Date Completed',
                        _formatDate(_voiceHandicapIndex['dateCompleted'])),
                ],
              ),
            ),
          ),
          if (detailedScores != null && detailedScores.isNotEmpty) ...[
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detailed Scores',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...detailedScores.entries.map((entry) {
                      return _buildInfoRow(
                        _formatFieldName(
                            entry.key), // FIXED: This now returns a String
                        _formatValue(entry.value),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGRBASTab() {
    if (_grbasRatings.isEmpty)
      return _buildEmptyState('No GRBAS ratings available');

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('GRBAS Ratings', style: AppTextStyles.headlineSmall),
          SizedBox(height: 16),
          ..._grbasRatings.asMap().entries.map((entry) {
            final index = entry.key;
            final rating = _convertToTypedMap(entry.value);
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rating ${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ...rating.entries
                        .where((entry) => entry.value != null)
                        .map((entry) {
                      return _buildInfoRow(
                        _formatFieldName(
                            entry.key), // FIXED: This now returns a String
                        _formatValue(entry.value),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Keep your existing methods for patient info, demographics, health history, etc.
  Widget _buildPatientInfo() {
    final basicInfo = _convertToTypedMap(_patientProfile['basicInfo']);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Patient Information', style: AppTextStyles.headlineSmall),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  onPressed: _editPatient,
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Name', basicInfo['participantName']),
            _buildInfoRow('Patient ID', basicInfo['userId']),
            _buildInfoRow('Age', basicInfo['age']),
            _buildInfoRow('Gender', basicInfo['gender']),
            _buildInfoRow('Contact', basicInfo['contactNumber']),
            _buildInfoRow('Email', basicInfo['email']),
            _buildInfoRow(
              'Registration Date',
              basicInfo['registrationDate'] != null
                  ? DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(basicInfo['registrationDate'].toString()),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographics() {
    final demographics = _convertToTypedMap(_patientProfile['demographics']);
    if (demographics.isEmpty)
      return _buildEmptyState('No demographic information available');

    final location = _convertToTypedMap(demographics['location']);
    final personalInfo = _convertToTypedMap(demographics['personalInfo']);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demographics', style: AppTextStyles.headlineSmall),
            SizedBox(height: 16),
            if (location.isNotEmpty) ...[
              Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildInfoRow('Country', location['country']),
              _buildInfoRow('State', location['state']),
              _buildInfoRow('District', location['district']),
              _buildInfoRow('City', location['city']),
              SizedBox(height: 12),
            ],
            if (personalInfo.isNotEmpty) ...[
              Text(
                'Personal Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildInfoRow('Education', personalInfo['education']),
              _buildInfoRow('Employment', personalInfo['employment']),
              _buildInfoRow('Occupation', personalInfo['occupation']),
              _buildInfoRow('Income', personalInfo['income']),
              _buildInfoRow('Marital Status', personalInfo['maritalStatus']),
              SizedBox(height: 12),
            ],
            _buildInfoRow(
              'Disability',
              _formatArray(demographics['disability']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthHistory() {
    final healthHistory = _convertToTypedMap(_patientProfile['healthHistory']);
    if (healthHistory.isEmpty)
      return _buildEmptyState('No health history available');

    final tobaccoUse = _convertToTypedMap(healthHistory['tobaccoUse']);
    final alcoholUse = _convertToTypedMap(healthHistory['alcoholUse']);
    final medical = _convertToTypedMap(healthHistory['medical']);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health History', style: AppTextStyles.headlineSmall),
            SizedBox(height: 16),
            if (tobaccoUse.isNotEmpty) ...[
              Text(
                'Tobacco Use',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildInfoRow('Status', tobaccoUse['status']),
              _buildInfoRow('Forms', _formatArray(tobaccoUse['forms'])),
              _buildInfoRow('Current Status', tobaccoUse['currentStatus']),
              SizedBox(height: 12),
            ],
            if (alcoholUse.isNotEmpty) ...[
              Text(
                'Alcohol Use',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildInfoRow('Status', alcoholUse['status']),
              _buildInfoRow('Frequency', alcoholUse['frequency']),
              _buildInfoRow('Rehabilitation', alcoholUse['rehabilitation']),
              SizedBox(height: 12),
            ],
            if (medical.isNotEmpty) ...[
              Text(
                'Medical Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildInfoRow('Conditions', _formatArray(medical['conditions'])),
              _buildInfoRow(
                'Medications',
                _formatArray(medical['medications']),
              ),
              _buildInfoRow('Allergies', medical['allergies']),
              SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceRecordings() {
    if (_voiceRecordings.isEmpty)
      return _buildEmptyState('No voice recordings available');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Voice Recordings (${_voiceRecordings.length})',
              style: AppTextStyles.headlineSmall,
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.download, color: AppColors.primary),
              onPressed: _showExportDialog,
              tooltip: 'Export all recordings',
            ),
          ],
        ),
        SizedBox(height: 16),
        ..._voiceRecordings.map((recording) {
          final rec = _convertToTypedMap(recording);
          return Card(
            child: ListTile(
              leading: Icon(Icons.audiotrack, color: AppColors.primary),
              title: Text(rec['taskType']?.toString() ?? 'Unknown Task'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration: ${rec['durationSeconds']?.toString() ?? 'N/A'} seconds',
                  ),
                  Text('Language: ${rec['language'] ?? 'N/A'}'),
                  if (rec['recordingDate'] != null)
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(rec['recordingDate'].toString()))}',
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.download, size: 20),
                    onPressed: () => _downloadRecording(
                      rec['id']?.toString() ?? '',
                      rec['taskType']?.toString() ?? '',
                      asWav: true,
                    ),
                    tooltip: 'Download as WAV',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildClinicalNotesForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Notes & Assessment',
              style: AppTextStyles.headlineSmall,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _treatmentPlanController,
              decoration: InputDecoration(
                labelText: 'Treatment Plan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _followUpController,
              decoration: InputDecoration(
                labelText: 'Follow-up Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priorityLevel,
              decoration: InputDecoration(
                labelText: 'Priority Level',
                border: OutlineInputBorder(),
              ),
              items: ['Low', 'Medium', 'High']
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _priorityLevel = value!),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes & Recommendations',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitClinicalNotes,
              child: Text('Save Clinical Notes'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method for assessment summary
  Widget _buildAssessmentSummaryCard() {
    final completeness = _analysisNotes['completenessPercentage'] ?? 0;
    final riskFactors = _convertToList(_analysisNotes['riskFactors'] ?? []);
    final recommendations =
        _convertToList(_analysisNotes['recommendations'] ?? []);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assessment Summary', style: AppTextStyles.headlineSmall),
            SizedBox(height: 16),
            _buildInfoRow('Completeness', '$completeness% complete'),
            SizedBox(height: 12),
            if (riskFactors.isNotEmpty) ...[
              Text('Risk Factors',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...riskFactors.map((factor) {
                final typedFactor = _convertToTypedMap(factor);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                      '• ${typedFactor['type']} (${typedFactor['severity']})'),
                );
              }).toList(),
              SizedBox(height: 12),
            ],
            if (recommendations.isNotEmpty) ...[
              Text('Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...recommendations.map((rec) {
                final typedRec = _convertToTypedMap(rec);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${typedRec['description']}'),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Export Patient Data'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose export options for ${widget.patientName ?? "this patient"}:',
                style: AppTextStyles.bodyText,
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: ListTile(
                  leading: Icon(Icons.archive, color: Colors.blue),
                  title: Text(
                    'Complete Package (Recommended)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('CSV + PDF + Voice recordings (WAV)'),
                  trailing: Icon(Icons.star, color: Colors.amber),
                  onTap: () {
                    Navigator.pop(context);
                    _exportCompletePackage();
                  },
                ),
              ),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text('Data Only (CSV)'),
                subtitle: Text('Patient data in spreadsheet format'),
                onTap: () {
                  Navigator.pop(context);
                  _exportDataOnly();
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Report Only (PDF)'),
                subtitle: Text('Clinical report for review'),
                onTap: () {
                  Navigator.pop(context);
                  _exportReportOnly();
                },
              ),
              if (_voiceRecordings.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.audiotrack, color: Colors.orange),
                  title: Text('Voice Recordings Only'),
                  subtitle: Text(
                    '${_voiceRecordings.length} recordings in WAV format',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportVoiceOnly();
                  },
                ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Export Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• CSV contains all patient data for analysis',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      '• PDF provides formatted clinical report',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      '• WAV files are optimized for voice analysis',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      '• Complete package recommended for clinical use',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCompletePackage() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportPatientData(
        widget.patientId,
        format: 'zip',
        includeAudio: true,
        audioFormat: 'wav',
      );
      print('📦 [FRONTEND] Export response received: ${response['success']}');
      print('📦 [FRONTEND] Export message: ${response['message']}');

      if (response['success'] == true) {
        await _saveFileToDevice(
          response['data'],
          response['fileName']?.toString() ?? 'patient_complete_export.zip',
          'Complete patient data exported successfully',
        );
      } else {
        _showErrorSnackBar(response['message']?.toString() ?? 'Export failed');
      }
    } catch (e) {
      print('💥 [FRONTEND] Export error: $e');
      _showErrorSnackBar('Export error: ${e.toString()}');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDataOnly() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportPatientData(
        widget.patientId,
        format: 'csv',
        includeAudio: false,
      );

      if (response['success'] == true) {
        await _saveFileToDevice(
          response['data'],
          'patient_${widget.patientId}_data.csv',
          'Patient data exported as CSV',
        );
      } else {
        _showErrorSnackBar(response['message']?.toString() ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export error: ${e.toString()}');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReportOnly() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportPatientData(
        widget.patientId,
        format: 'pdf',
        includeAudio: false,
      );

      if (response['success'] == true) {
        await _saveFileToDevice(
          response['data'],
          'patient_${widget.patientId}_report.pdf',
          'Clinical report exported as PDF',
        );
      } else {
        _showErrorSnackBar(response['message']?.toString() ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export error: ${e.toString()}');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportVoiceOnly() async {
    setState(() => _isExporting = true);
    try {
      final response = await ApiService.exportPatientData(
        widget.patientId,
        format: 'zip',
        includeAudio: true,
        audioFormat: 'wav',
      );

      if (response['success'] == true) {
        await _saveFileToDevice(
          response['data'],
          'patient_${widget.patientId}_voice_recordings.zip',
          'Voice recordings exported successfully',
        );
      } else {
        _showErrorSnackBar(response['message']?.toString() ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export error: ${e.toString()}');
    } finally {
      setState(() => _isExporting = false);
    }
  }

// Replace your entire _saveFileToDevice method with this:
  Future<void> _saveFileToDevice(
    dynamic data,
    String fileName,
    String successMessage,
  ) async {
    try {
      // Try to get Downloads directory first
      Directory downloadsDir;

      try {
        // For Android, try the public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');

        // If Downloads doesn't exist, fall back to external storage
        if (!await downloadsDir.exists()) {
          final Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            downloadsDir = Directory('${externalDir.path}/Downloads');
            await downloadsDir.create(recursive: true);
          } else {
            throw Exception('Cannot access storage');
          }
        }
      } catch (e) {
        // Final fallback to app documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        downloadsDir = appDocDir;
      }

      final File file = File('${downloadsDir.path}/$fileName');

      if (data is List<int>) {
        await file.writeAsBytes(data);
      } else if (data is Uint8List) {
        await file.writeAsBytes(data);
      } else {
        final bytes = utf8.encode(data.toString());
        await file.writeAsBytes(bytes);
      }

      _showSuccessSnackBar('$successMessage\nSaved to: ${file.path}');
    } catch (e) {
      // If direct file access fails, fall back to FileSaver
      try {
        String? path;
        if (data is List<int>) {
          path = await FileSaver.instance.saveFile(
            name: fileName.split('.').first,
            bytes: Uint8List.fromList(data),
            fileExtension: fileName.split('.').last,
            mimeType: _getMimeType(fileName),
          );
        } else {
          final bytes = utf8.encode(data.toString());
          path = await FileSaver.instance.saveFile(
            name: fileName.split('.').first,
            bytes: Uint8List.fromList(bytes),
            fileExtension: fileName.split('.').last,
            mimeType: _getMimeType(fileName),
          );
        }
        _showSuccessSnackBar('$successMessage\nSaved via FileSaver to: $path');
      } catch (fileSaverError) {
        _showErrorSnackBar('Failed to save file: ${fileSaverError.toString()}');
      }
    }
  }

  MimeType _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return MimeType.pdf;
      case 'zip':
        return MimeType.zip;
      case 'csv':
        return MimeType.text;
      case 'wav':
        return MimeType.other;
      default:
        return MimeType.other;
    }
  }

  Future<void> _downloadRecording(
    String recordingId,
    String taskType, {
    bool asWav = false,
  }) async {
    try {
      Map<String, dynamic> response;
      if (asWav) {
        response = await ApiService.downloadRecordingWav(recordingId);
      } else {
        response = await ApiService.downloadAdminRecording(recordingId);
      }

      if (response['success'] == true) {
        final fileName =
            '${widget.patientName ?? 'patient'}_${taskType.replaceAll(' ', '_')}_recording.${asWav ? 'wav' : 'mp3'}';
        await _saveFileToDevice(
          response['data'],
          fileName,
          'Recording downloaded successfully',
        );
      } else {
        _showErrorSnackBar(
          response['message']?.toString() ?? 'Download failed',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Download error: ${e.toString()}');
    }
  }

  void _editPatient() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit Patient Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _genderController,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _savePatientInfo,
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePatientInfo() async {
    final updates = {
      'participantName': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'gender': _genderController.text,
      'contactNumber': _contactController.text,
      'email': _emailController.text,
    };

    try {
      final response = await ApiService.updatePatientInfo(
        widget.patientId,
        updates,
      );
      if (response['success'] == true) {
        Navigator.pop(context);
        _showSuccessSnackBar('Patient information updated successfully');
        _loadPatientData();
      } else {
        _showErrorSnackBar(response['message']?.toString() ?? 'Update failed');
      }
    } catch (e) {
      _showErrorSnackBar('Update error: ${e.toString()}');
    }
  }

  Future<void> _submitClinicalNotes() async {
    try {
      final response = await ApiService.submitClinicalNotes(
        patientId: widget.patientId,
        diagnosis: _diagnosisController.text,
        treatmentPlan: _treatmentPlanController.text,
        followUpNotes: _followUpController.text,
        priorityLevel: _priorityLevel,
        recommendations:
            _notesController.text.isNotEmpty ? [_notesController.text] : null,
      );

      if (response['success'] == true) {
        _showSuccessSnackBar('Clinical notes saved successfully');
        _diagnosisController.clear();
        _treatmentPlanController.clear();
        _followUpController.clear();
        _notesController.clear();
        setState(() => _priorityLevel = 'Medium');
      } else {
        _showErrorSnackBar(
          response['message']?.toString() ?? 'Failed to save notes',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error saving notes: ${e.toString()}');
    }
  }

  Future<void> _analyzeVoiceProgression() async {
    try {
      final response = await ApiService.analyzePatientVoiceProgression(
        widget.patientId,
      );
      if (response['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Voice Analysis Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression Score: ${response['data']?['progressionScore']?.toStringAsFixed(1) ?? 'N/A'}%',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Recommendations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...(response['data']?['recommendations'] as List<dynamic>? ??
                          [])
                      .map((rec) => Text('• ${rec?.toString() ?? ""}'))
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar(
          response['message']?.toString() ?? 'Analysis failed',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Analysis error: ${e.toString()}');
    }
  }
// Add these methods to your _EnhancedPatientDetailScreenState class

// Add a delete button to the AppBar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName ?? 'Patient Details'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
            Tab(icon: Icon(Icons.medical_services), text: 'Cancer Assessments'),
            Tab(icon: Icon(Icons.voice_chat), text: 'VHI'),
            Tab(icon: Icon(Icons.assessment), text: 'GRBAS'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Recordings'),
            Tab(icon: Icon(Icons.medical_services), text: 'Clinical Notes'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'refresh':
                  _loadPatientData();
                  break;
                case 'delete':
                  _confirmDeletePatient();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download, size: 20),
                  title: Text('Export Patient Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh, size: 20),
                  title: Text('Refresh Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, size: 20, color: Colors.red),
                  title: Text(
                    'Delete Patient',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Your existing tab content here...
                // Overview Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPatientInfo(),
                      SizedBox(height: 16),
                      _buildDemographics(),
                      SizedBox(height: 16),
                      _buildHealthHistory(),
                      SizedBox(height: 16),
                      _buildAssessmentSummaryCard(),
                    ],
                  ),
                ),
                // Other tabs...
                _buildCancerAssessmentsTab(),
                _buildVHITab(),
                _buildGRBASTab(),
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: _buildVoiceRecordings(),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: _buildClinicalNotesForm(),
                ),
              ],
            ),
    );
  }

// Confirmation dialog for deleting patient from detail screen
  void _confirmDeletePatient() {
    final basicInfo = _convertToTypedMap(_patientProfile['basicInfo'] ?? {});
    final patientName =
        basicInfo['participantName']?.toString() ?? 'Unknown Patient';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String confirmationText = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    // FIX: Added Expanded here
                    child: Text(
                      'Delete Patient',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to permanently delete this patient?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient: $patientName',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis, // Added overflow
                          ),
                          Text(
                            'ID: ${widget.patientId}',
                            overflow: TextOverflow.ellipsis, // Added overflow
                          ),
                          if (basicInfo['age'] != null)
                            Text(
                              'Age: ${basicInfo['age']}',
                              overflow: TextOverflow.ellipsis, // Added overflow
                            ),
                          if (basicInfo['gender'] != null)
                            Text(
                              'Gender: ${basicInfo['gender']}',
                              overflow: TextOverflow.ellipsis, // Added overflow
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            // FIX: This Row might be causing overflow
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                // FIX: Added Expanded here
                                child: Text(
                                  'This will permanently delete:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ..._buildDeletionSummary(),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        // FIX: This Row might be causing overflow
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            // FIX: Added Expanded here
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Type "delete" to confirm:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          confirmationText = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Type delete to confirm',
                        errorText: confirmationText.isNotEmpty &&
                                confirmationText.toUpperCase() != 'DELETE'
                            ? 'Must type delete exactly'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: confirmationText.trim().toUpperCase() == 'DELETE'
                      ? () {
                          Navigator.of(context).pop();
                          _deleteCurrentPatient();
                        }
                      : null,
                  icon: Icon(Icons.delete_forever, size: 18),
                  label: Text('Delete Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Build a summary of what will be deleted
  List<Widget> _buildDeletionSummary() {
    List<Widget> items = [];

    items.add(Text(
      '• Patient demographic information',
      overflow: TextOverflow.ellipsis,
    ));

    if (_patientProfile['demographics'] != null) {
      items.add(Text(
        '• Complete demographic profile',
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (_patientProfile['healthHistory'] != null) {
      items.add(Text(
        '• Health history and lifestyle data',
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (_cancerAssessments.isNotEmpty) {
      int assessmentCount = 0;
      if (_cancerAssessments['oralCancer'] != null) assessmentCount++;
      if (_cancerAssessments['larynxHypopharynx'] != null) assessmentCount++;
      if (_cancerAssessments['pharynxCancer'] != null) assessmentCount++;
      items.add(Text(
        '• $assessmentCount cancer assessment(s)',
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (_voiceHandicapIndex.isNotEmpty) {
      items.add(Text(
        '• Voice Handicap Index (VHI) assessment',
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (_grbasRatings.isNotEmpty) {
      items.add(Text(
        '• ${_grbasRatings.length} GRBAS rating(s)',
        overflow: TextOverflow.ellipsis,
      ));
    }

    if (_voiceRecordings.isNotEmpty) {
      items.add(Text(
        '• ${_voiceRecordings.length} voice recording(s)',
        overflow: TextOverflow.ellipsis,
      ));
    }

    items.add(Text(
      '• All clinical notes and assessments',
      overflow: TextOverflow.ellipsis,
    ));

    return items;
  }

// Delete the current patient
  Future<void> _deleteCurrentPatient() async {
    final basicInfo = _convertToTypedMap(_patientProfile['basicInfo'] ?? {});
    final patientName =
        basicInfo['participantName']?.toString() ?? 'Unknown Patient';

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting patient data...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final response = await ApiService.deletePatient(widget.patientId);

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['success'] == true) {
        _showSuccessSnackBar(
            'Patient "$patientName" has been permanently deleted');

        // Navigate back to dashboard after successful deletion
        Navigator.of(context)
            .pop(true); // Return true to indicate deletion occurred
      } else {
        _showErrorSnackBar(
            response['message']?.toString() ?? 'Failed to delete patient');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      _showErrorSnackBar('Error deleting patient: ${e.toString()}');
    }
  }
}
