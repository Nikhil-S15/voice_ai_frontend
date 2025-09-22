import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/admin/patient.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class EnhancedAdminDashboardScreen extends StatefulWidget {
  const EnhancedAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedAdminDashboardScreen> createState() =>
      _EnhancedAdminDashboardScreenState();
}

class _EnhancedAdminDashboardScreenState
    extends State<EnhancedAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _patientSearchQuery = '';
  bool _isLoading = false;
  bool _loadingPatients = false;
  Map<String, dynamic> _stats = {};
  List<dynamic> _patients = [];
  List<dynamic> _filteredPatients = [];
  Map<String, dynamic> _voiceAnalysis = {};
  List<dynamic> _voiceRecordings = [];
  // List<Map<String, dynamic>> _patients = [];
  // List<Map<String, dynamic>> _filteredPatients = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStatistics(),
      _loadPatientAnalysisData(),
      _loadVoiceAnalysisData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStatistics() async {
    try {
      final response = await ApiService.getAdminStatistics();
      if (response['success'] == true) {
        setState(() => _stats = response['data'] ?? {});
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load statistics: $e');
    }
  }

  Future<void> _loadPatientAnalysisData() async {
    setState(() => _loadingPatients = true);
    try {
      final response = await ApiService.getPatientAnalysisData(
        startDate: _startDate,
        endDate: _endDate,
        patientId: _patientSearchQuery.isNotEmpty ? _patientSearchQuery : null,
      );
      if (response['success'] == true) {
        setState(() {
          _patients = response['data'] ?? [];
          _filteredPatients = _patients;
        });
      } else {
        _showErrorSnackBar(
            response['message'] ?? 'Failed to load patient data');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading patient data: $e');
    } finally {
      setState(() => _loadingPatients = false);
    }
  }

  Future<void> _loadVoiceAnalysisData() async {
    try {
      final response = await ApiService.getVoiceAnalysisSummary(
        startDate: _startDate, // Remove .toIso8601String()
        endDate: _endDate, // Remove .toIso8601String()
      );
      if (response['success'] == true) {
        setState(() => _voiceAnalysis = response['data'] ?? {});
      }

      // Load voice recordings
      final recordingsResponse = await ApiService.getVoiceRecordingsAdmin(
        startDate: _startDate, // Remove .toIso8601String()
        endDate: _endDate, // Remove .toIso8601String()
      );
      if (recordingsResponse['success'] == true) {
        setState(() => _voiceRecordings = recordingsResponse['data'] ?? []);
      }
    } catch (e) {
      print('Error loading voice analysis: $e');
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _patientSearchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final patientInfo = patient['patient'] ?? {};
          final name =
              patientInfo['participantName']?.toString().toLowerCase() ?? '';
          final id =
              patientInfo['participantId']?.toString().toLowerCase() ?? '';
          final userId = patientInfo['userId']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              id.contains(query.toLowerCase()) ||
              userId.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPatientAnalysisData();
      _loadVoiceAnalysisData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadPatientAnalysisData();
    _loadVoiceAnalysisData();
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Total Patients',
                  _stats['totalUsers'],
                  Icons.people,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'With Voice Data',
                  _stats['completionAnalysis']?['withVoiceRecordings'],
                  Icons.mic,
                  Colors.green,
                ),
                _buildStatCard(
                  'High Priority',
                  _getHighPriorityCount(),
                  Icons.priority_high,
                  Colors.red,
                ),
                _buildStatCard(
                  'Total Recordings',
                  _stats['totalVoiceRecordings'],
                  Icons.audio_file,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Completion Analysis',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildCompletionChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_stats['vhiScores'] != null) _buildVHIDistributionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or participant ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterPatients('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _filterPatients,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? 'All dates'
                          : '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                      style: AppTextStyles.bodyText,
                    ),
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDateFilter,
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _showDateRangePicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPatientAnalysisData,
                  ),
                ],
              ),
              if (_filteredPatients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_filteredPatients.length} patients found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loadingPatients
              ? const Center(child: CircularProgressIndicator())
              : _filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _patientSearchQuery.isNotEmpty
                                ? 'No patients match your search'
                                : 'No patients found',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_patientSearchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterPatients('');
                              },
                              child: const Text('Clear search'),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPatientAnalysisData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) =>
                            _buildPatientCard(_filteredPatients[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  // Add this method to your _EnhancedAdminDashboardScreenState class

  Widget _buildPatientCard(Map<String, dynamic> patientData) {
    final patient = patientData['patient'] ?? {};
    final summary = patientData['assessmentSummary'] ?? {};
    final voiceAnalysis = patientData['voiceAnalysis'] ?? {};
    final completeness = summary['completenessScore'] ?? 0;
    final priority = _calculatePriority(patientData);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewPatientDetails(patient['userId']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        _getPriorityColor(priority).withOpacity(0.2),
                    child: Text(
                      (patient['participantName'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['participantName'] ?? 'Unknown',
                          style: AppTextStyles.bodyBold,
                        ),
                        Text(
                          'ID: ${patient['participantId'] ?? patient['userId'] ?? 'N/A'}',
                          style: AppTextStyles.bodyText.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewPatientDetails(patient['userId']);
                          break;
                        case 'export':
                          _exportPatientData(
                            patient['userId'],
                            patient['participantName'],
                          );
                          break;
                        case 'delete':
                          _confirmDeletePatient(
                            patient['userId'],
                            patient['participantName'],
                          );
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility, size: 20),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'export',
                        child: ListTile(
                          leading: Icon(Icons.download, size: 20),
                          title: Text('Export Data'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading:
                              Icon(Icons.delete, size: 20, color: Colors.red),
                          title: Text('Delete Patient',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  ),
                  _buildPriorityChip(priority),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.person,
                      '${patient['age'] ?? 'N/A'}, ${patient['gender'] ?? 'N/A'}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.date_range,
                      DateFormat('MMM dd, yyyy').format(
                        DateTime.parse(
                          patient['registrationDate'] ??
                              DateTime.now().toIso8601String(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assessment Progress',
                          style: AppTextStyles.bodyText,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: completeness / 100.0,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completeness >= 80
                                ? Colors.green
                                : completeness >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completeness% Complete',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Voice Recordings', style: AppTextStyles.bodyText),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.mic, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                                '${summary['totalRecordings'] ?? 0} recordings'),
                          ],
                        ),
                        Text(
                          '${((voiceAnalysis['totalDuration'] ?? 0) / 60000).toStringAsFixed(1)} min total',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewPatientDetails(patient['userId']),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportPatientData(
                        patient['userId'],
                        patient['participantName'],
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
// Add these methods to your _EnhancedAdminDashboardScreenState class

// Show confirmation dialog before deleting a patient
  void _confirmDeletePatient(String? patientId, String? patientName) {
    if (patientId == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Patient'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this patient?',
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
                        'Patient: ${patientName ?? 'Unknown'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ID: $patientId'),
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
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'This action will permanently delete:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• All patient demographic information'),
                      Text('• Complete health history and assessments'),
                      Text('• Voice Handicap Index (VHI) scores'),
                      Text('• All voice recordings and audio files'),
                      Text('• GRBAS ratings and evaluations'),
                      Text('• Cancer assessment data'),
                      Text('• Clinical notes and recommendations'),
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
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please type "DELETE" to confirm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    // This will be handled in the StatefulWidget
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type DELETE to confirm',
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
            StatefulBuilder(
              builder: (context, setState) {
                String confirmationText = '';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            confirmationText = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'DELETE',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed:
                          confirmationText.trim().toUpperCase() == 'DELETE'
                              ? () {
                                  Navigator.of(context).pop();
                                  _deletePatient(patientId, patientName);
                                }
                              : null,
                      icon: Icon(Icons.delete_forever, size: 18),
                      label: Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

// Delete patient from backend
  Future<void> _deletePatient(String patientId, String? patientName) async {
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
      final response = await ApiService.deletePatient(patientId);

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['success'] == true) {
        _showSuccessSnackBar(
            'Patient "${patientName ?? patientId}" has been permanently deleted');

        // Refresh the patient list
        await _loadPatientAnalysisData();

        // Also refresh statistics
        await _loadStatistics();
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

// Alternative method for bulk delete (if needed)
  void _showBulkDeleteDialog(List<String> selectedPatientIds) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Multiple Patients'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete ${selectedPatientIds.length} patients?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'This will permanently delete ALL DATA for ${selectedPatientIds.length} patients',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('This action cannot be undone!'),
                    ],
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
              onPressed: () {
                Navigator.of(context).pop();
                _bulkDeletePatients(selectedPatientIds);
              },
              icon: Icon(Icons.delete_forever, size: 18),
              label: Text('Delete All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

// Bulk delete functionality (if needed)
  Future<void> _bulkDeletePatients(List<String> patientIds) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting ${patientIds.length} patients...'),
                SizedBox(height: 8),
                Text(
                  'This may take a while',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );

    int successCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    for (String patientId in patientIds) {
      try {
        final response = await ApiService.deletePatient(patientId);
        if (response['success'] == true) {
          successCount++;
        } else {
          errorCount++;
          errors.add('${patientId}: ${response['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        errorCount++;
        errors.add('${patientId}: ${e.toString()}');
      }
    }

    // Close loading dialog
    Navigator.of(context).pop();

    // Show results
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bulk Delete Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successCount > 0)
                Text(
                  '✓ Successfully deleted: $successCount patients',
                  style: TextStyle(color: Colors.green),
                ),
              if (errorCount > 0) ...[
                Text(
                  '✗ Failed to delete: $errorCount patients',
                  style: TextStyle(color: Colors.red),
                ),
                if (errors.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text('Errors:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...errors.take(5).map((error) => Text(
                        '• $error',
                        style: TextStyle(fontSize: 12),
                      )),
                  if (errors.length > 5)
                    Text('... and ${errors.length - 5} more errors'),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Refresh data
                _loadPatientAnalysisData();
                _loadStatistics();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (successCount > 0) {
      _showSuccessSnackBar('$successCount patients deleted successfully');
    }
  }

  Widget _buildVoiceAnalysisTab() {
    return RefreshIndicator(
      onRefresh: _loadVoiceAnalysisData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Analysis Overview', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            _buildVoiceStatsGrid(),
            const SizedBox(height: 16),
            _buildVoiceQualityAnalysis(),
            const SizedBox(height: 16),
            _buildTaskTypeDistribution(),
            const SizedBox(height: 16),
            _buildHighPriorityVoiceCases(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Export for Clinical Analysis',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Complete Clinical Export',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export includes:',
                    style: AppTextStyles.bodyBold,
                  ),
                  const SizedBox(height: 8),
                  const Text('• Complete patient profiles and assessments'),
                  const Text('• Voice recordings in high-quality WAV format'),
                  const Text('• Comprehensive CSV reports for analysis'),
                  const Text('• PDF clinical reports for review'),
                  const Text('• VHI scores and risk factor analysis'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Range',
                              style: AppTextStyles.bodyBold,
                            ),
                            Text(
                              _startDate == null
                                  ? 'All data (no filter)'
                                  : '${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                              style: AppTextStyles.bodyText,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                        onPressed: _showDateRangePicker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportClinicalData,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        _isLoading ? 'Exporting...' : 'Export Clinical Data',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickExportOptions(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value?.toString() ?? '0',
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart() {
    final completion = _stats['completionAnalysis'] ?? {};
    final fully = completion['fullyCompleted'] ?? 0;
    final partial = completion['partiallyCompleted'] ?? 0;
    final minimal = completion['minimal'] ?? 0;
    final total = fully + partial + minimal;

    if (total == 0) {
      return const Center(child: Text('No completion data available'));
    }

    return Column(
      children: [
        Row(
          children: [
            if (fully > 0)
              Expanded(
                flex: fully,
                child: Container(height: 8, color: Colors.green),
              ),
            if (partial > 0)
              Expanded(
                flex: partial,
                child: Container(height: 8, color: Colors.orange),
              ),
            if (minimal > 0)
              Expanded(
                flex: minimal,
                child: Container(height: 8, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Complete', fully, Colors.green, total),
            _buildLegendItem('Partial', partial, Colors.orange, total),
            _buildLegendItem('Minimal', minimal, Colors.red, total),
          ],
        ),
      ],
    );
  }

  Widget _buildVHIDistributionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Handicap Index Distribution',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildVHIChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildVHIChart() {
    final vhiScores = _stats['vhiScores'] ?? {};
    final mild = vhiScores['mild'] ?? 0;
    final moderate = vhiScores['moderate'] ?? 0;
    final severe = vhiScores['severe'] ?? 0;
    final total = mild + moderate + severe;

    if (total == 0) {
      return const Center(child: Text('No VHI data available'));
    }

    return Column(
      children: [
        Row(
          children: [
            if (mild > 0)
              Expanded(
                flex: mild,
                child: Container(height: 8, color: Colors.green),
              ),
            if (moderate > 0)
              Expanded(
                flex: moderate,
                child: Container(height: 8, color: Colors.orange),
              ),
            if (severe > 0)
              Expanded(
                flex: severe,
                child: Container(height: 8, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Mild', mild, Colors.green, total),
            _buildLegendItem('Moderate', moderate, Colors.orange, total),
            _buildLegendItem('Severe', severe, Colors.red, total),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, int total) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
        Text('$count ($percentage%)', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildVoiceStatsGrid() {
    final summary =
        _voiceRecordings.isNotEmpty ? _voiceRecordings[0]['summary'] ?? {} : {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Recordings',
          summary['totalRecordings'] ?? _stats['totalVoiceRecordings'] ?? 0,
          Icons.mic,
          Colors.blue,
        ),
        _buildStatCard(
          'Avg Duration',
          '${(summary['totalDuration'] ?? 0) ~/ 1000 ~/ 60} min',
          Icons.timer,
          Colors.green,
        ),
        _buildStatCard(
          'Patients',
          summary['totalPatients'] ??
              _stats['completionAnalysis']?['withVoiceRecordings'] ??
              0,
          Icons.people,
          AppColors.primary,
        ),
        _buildStatCard(
          'Languages',
          (summary['languageDistribution'] as Map?)?.length ?? 1,
          Icons.language,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildVoiceQualityAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recording Quality Analysis',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_voiceRecordings.isEmpty)
              const Center(child: Text('No voice recordings data available'))
            else
              Column(
                children: [
                  _buildQualityMetric('Good Quality',
                      '${_calculateGoodQualityPercentage()}%', Colors.green),
                  _buildQualityMetric('Average Duration',
                      '${_calculateAverageDuration()} seconds', Colors.blue),
                  _buildQualityMetric('Total Duration',
                      '${_calculateTotalDuration()} minutes', Colors.orange),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTypeDistribution() {
    if (_voiceRecordings.isEmpty) return const SizedBox.shrink();

    final taskTypes = <String, int>{};
    for (final recording in _voiceRecordings) {
      final taskType = recording['taskType']?.toString() ?? 'Unknown';
      taskTypes[taskType] = (taskTypes[taskType] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Type Distribution',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            ...taskTypes.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value} recordings'),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighPriorityVoiceCases() {
    final highPriorityPatients = _patients
        .where((patient) => _calculatePriority(patient) == 'High')
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'High Priority Voice Cases',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            if (highPriorityPatients.isEmpty)
              const Center(child: Text('No high priority cases'))
            else
              ...highPriorityPatients.take(5).map((patientData) {
                final patient = patientData['patient'] ?? {};
                final summary = patientData['assessmentSummary'] ?? {};
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(patient['participantName'] ?? 'Unknown'),
                  subtitle: Text(_getPriorityReason(patientData)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _viewPatientDetails(patient['userId']),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Targeted Export Options',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickExportButton(
                  'High Priority Only',
                  Icons.priority_high,
                  Colors.red,
                  () => _exportFilteredPatients('high_priority'),
                ),
                _buildQuickExportButton(
                  'Voice Data Only',
                  Icons.mic,
                  Colors.blue,
                  () => _exportFilteredPatients('voice_only'),
                ),
                _buildQuickExportButton(
                  'Incomplete Cases',
                  Icons.warning,
                  Colors.orange,
                  () => _exportFilteredPatients('incomplete'),
                ),
                _buildQuickExportButton(
                  'Recent (7 days)',
                  Icons.access_time,
                  Colors.green,
                  () => _exportFilteredPatients('recent'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'moderate':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 1,
      ),
    );
  }

  // Helper methods
  int _getHighPriorityCount() {
    return _patients
        .where((patient) => _calculatePriority(patient) == 'High')
        .length;
  }

  String _calculatePriority(Map<String, dynamic> patientData) {
    final summary = patientData['assessmentSummary'] ?? {};
    final voiceAnalysis = patientData['voiceAnalysis'] ?? {};
    final completeness = summary['completenessScore'] ?? 0;
    final totalRecordings = summary['totalRecordings'] ?? 0;

    // High priority conditions
    if (completeness < 30) return 'High';
    if (totalRecordings == 0 && completeness < 80) return 'High';

    // Check for VHI severity if available
    final timeline = patientData['timeline'] as List? ?? [];
    for (final event in timeline) {
      if (event['type'] == 'VHI Assessment') {
        final vhiData = event['data'] ?? {};
        final totalScore = vhiData['totalScore'];
        if (totalScore != null && totalScore > 60) return 'High';
      }
    }

    // Moderate priority conditions
    if (completeness < 70) return 'Moderate';
    if (totalRecordings > 0 && totalRecordings < 3) return 'Moderate';

    return 'Low';
  }

  String _getPriorityReason(Map<String, dynamic> patientData) {
    final summary = patientData['assessmentSummary'] ?? {};
    final completeness = summary['completenessScore'] ?? 0;
    final totalRecordings = summary['totalRecordings'] ?? 0;

    if (completeness < 30) {
      return 'Incomplete assessment ($completeness% complete)';
    }
    if (totalRecordings == 0) {
      return 'No voice recordings available';
    }

    final timeline = patientData['timeline'] as List? ?? [];
    for (final event in timeline) {
      if (event['type'] == 'VHI Assessment') {
        final vhiData = event['data'] ?? {};
        final totalScore = vhiData['totalScore'];
        if (totalScore != null && totalScore > 60) {
          return 'Severe voice handicap (VHI: $totalScore)';
        }
      }
    }

    return 'Requires clinical attention';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Calculation methods for voice analysis
  String _calculateGoodQualityPercentage() {
    if (_voiceRecordings.isEmpty) return '0';

    int goodQuality = 0;
    for (final recording in _voiceRecordings) {
      final duration = recording['durationSeconds'] ?? 0;
      // Consider recordings with duration > 3 seconds as good quality
      if (duration > 3) goodQuality++;
    }

    return ((goodQuality / _voiceRecordings.length) * 100).toStringAsFixed(1);
  }

  String _calculateAverageDuration() {
    if (_voiceRecordings.isEmpty) return '0';

    int totalDuration = 0;
    for (final recording in _voiceRecordings) {
      totalDuration += (recording['durationSeconds'] ?? 0) as int;
    }

    return (totalDuration / _voiceRecordings.length).toStringAsFixed(1);
  }

  String _calculateTotalDuration() {
    if (_voiceRecordings.isEmpty) return '0';

    int totalDuration = 0;
    for (final recording in _voiceRecordings) {
      totalDuration += (recording['durationSeconds'] ?? 0) as int;
    }

    return (totalDuration / 60).toStringAsFixed(1);
  }

  // Action methods
  void _viewPatientDetails(String? patientId) {
    if (patientId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedPatientDetailScreen(
          patientId: patientId,
          patientName: _getPatientNameById(patientId),
        ),
      ),
    ).then((result) {
      // This will execute when the detail screen is popped
      if (result == true) {
        _showSuccessSnackBar('Patient data refreshed after deletion');
        _loadPatientAnalysisData();
        _loadStatistics();
        _loadVoiceAnalysisData();
      }
    });
  }

  String? _getPatientNameById(String patientId) {
    try {
      final patient = _patients.firstWhere(
        (p) => (p['patient']?['userId'] ?? '').toString() == patientId,
        orElse: () => null,
      );
      return patient?['patient']?['participantName']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportPatientData(
      String? patientId, String? patientName) async {
    if (patientId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.exportPatientData(patientId);
      if (response['success'] == true) {
        _showSuccessSnackBar(
            'Patient data for ${patientName ?? 'patient'} exported successfully');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportClinicalData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.exportComprehensiveData(
        startDate: _startDate ?? DateTime(2020), // Provide default
        endDate: _endDate ?? DateTime.now(), // Provide default
        audioFormat: 'wav',
        sampleRate: 44100,
        includeAudio: true,
      );

      if (response['success'] == true) {
        _showSuccessSnackBar('Clinical data exported successfully');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportFilteredPatients(String filterType) async {
    setState(() => _isLoading = true);
    try {
      DateTime? startDate = _startDate;
      DateTime? endDate = _endDate;

      // Set date range for recent exports
      if (filterType == 'recent') {
        endDate = DateTime.now();
        startDate = endDate.subtract(const Duration(days: 7));
      }

      final response = await ApiService.exportFilteredPatients(
        startDate: startDate,
        endDate: endDate,
        priority: filterType == 'high_priority' ? 'High' : null,
        hasVoiceRecordings: filterType == 'voice_only' ? true : null,
        minCompleteness: filterType == 'incomplete' ? 0 : null,
        maxCompleteness: filterType == 'incomplete' ? 70 : null,
      );

      if (response['success'] == true) {
        _showSuccessSnackBar('Filtered data exported successfully');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Export failed');
      }
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Utility methods
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            const Text('Clinical Dashboard', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadInitialData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Patients'),
            Tab(icon: Icon(Icons.mic), text: 'Voice Analysis'),
            Tab(icon: Icon(Icons.download), text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPatientsTab(),
          _buildVoiceAnalysisTab(),
          _buildExportTab(),
        ],
      ),
    );
  }
}
