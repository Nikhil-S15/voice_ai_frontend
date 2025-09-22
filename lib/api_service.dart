import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl =
      "https://voice-ai-chat-backend-4.onrender.com/api";
  // static const String baseUrl = "http://10.114.4.75:3000/api";
  // static const String baseUrl = "http://192.168.1.100:3000/api";
  // Alternative: "https://voice-ai-chat-backend-4.onrender.com/api";

  static String? _adminToken;
  // Add this method to your ApiService class

  /// ✅ CHECK IF USER IS LOGGED IN
  static Future<bool> isLoggedIn() async {
    if (_adminToken == null || _adminToken!.isEmpty) {
      return false;
    }
    return true;
  }

  /// ✅ ADMIN LOGIN
  static Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/admin/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true) {
        _adminToken = responseBody['token'];
      }
      return responseBody;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ LOGOUT
  static Future<void> logout() async {
    _adminToken = null;
  }

  /// ✅ GET ADMIN STATISTICS
  static Future<Map<String, dynamic>> getAdminStatistics() async {
    final url = Uri.parse('$baseUrl/admin/statistics');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET PATIENT ANALYSIS DATA FOR DOCTORS
  static Future<Map<String, dynamic>> getPatientAnalysisData({
    DateTime? startDate,
    DateTime? endDate,
    String? patientId,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    String url = '$baseUrl/admin/patient-analysis';
    final params = <String>[];
    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
    if (patientId != null && patientId.isNotEmpty)
      params.add('patientId=$patientId');
    params.add('sortBy=$sortBy');
    params.add('sortOrder=$sortOrder');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET DETAILED PATIENT PROFILE FOR DOCTOR REVIEW
  static Future<Map<String, dynamic>> getPatientDetailedProfile(
      String patientId) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      final responseData = jsonDecode(response.body);

      // Add debug logging to see what data is being returned
      print('Patient profile response: ${responseData['success']}');
      if (responseData['data'] != null) {
        print(
            'Cancer assessments: ${responseData['data']['cancerAssessments'] != null}');
        print('VHI: ${responseData['data']['voiceHandicapIndex'] != null}');
        print('GRBAS: ${responseData['data']['grbasRatings'] != null}');
      }

      return responseData;
    } catch (e) {
      print('Error fetching patient profile: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // api_service.dart - Add these enhanced methods with detailed logging

  /// ✅ EXPORT INDIVIDUAL PATIENT DATA WITH RECORDINGS (CSV + PDF + Audio)
  static Future<Map<String, dynamic>> exportPatientData(
    String patientId, {
    String format = 'zip',
    bool includeAudio = true,
    String audioFormat = 'wav',
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/admin/patient/$patientId/export?format=$format&includeAudio=$includeAudio&audioFormat=$audioFormat',
      );

      print('🔄 [EXPORT] Attempting export for patient: $patientId');
      print('🌐 [EXPORT] URL: $url');
      print('🔑 [EXPORT] Token available: ${_adminToken != null}');
      if (_adminToken != null) {
        print('🔑 [EXPORT] Token length: ${_adminToken!.length}');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      print('📡 [EXPORT] Response status: ${response.statusCode}');
      print('📡 [EXPORT] Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print(
          '✅ [EXPORT] Success! Data length: ${response.bodyBytes.length} bytes',
        );
        return {
          'success': true,
          'data': response.bodyBytes,
          'fileName': 'patient_${patientId}_export.$format',
        };
      } else {
        print('❌ [EXPORT] Failed with status: ${response.statusCode}');
        print('❌ [EXPORT] Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Export failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } catch (e) {
      print('💥 [EXPORT] Error: ${e.toString()}');
      // print('💥 [EXPORT] Stack trace: ${e.stackTrace}');
      return {
        'success': false,
        'message': 'Export error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // ✅ Download recording in WAV format
  static Future<Map<String, dynamic>> downloadRecordingWav(
    String recordingId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/admin/recordings/$recordingId/download-wav',
      );

      print(
          '🔄 [DOWNLOAD WAV] Attempting download for recording: $recordingId');
      print('🌐 [DOWNLOAD WAV] URL: $url');

      final response = await http.get(
        url,
        headers: {
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      print('📡 [DOWNLOAD WAV] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
            '✅ [DOWNLOAD WAV] Success! Data length: ${response.bodyBytes.length} bytes');
        return {
          'success': true,
          'data': response.bodyBytes,
          'fileName': 'recording_$recordingId.wav',
        };
      } else {
        print('❌ [DOWNLOAD WAV] Failed with status: ${response.statusCode}');

        // FIX: Safe substring handling
        String responsePreview = response.body;
        if (response.body.length > 100) {
          responsePreview = response.body.substring(0, 100) + '...';
        }
        print('❌ [DOWNLOAD WAV] Response body: $responsePreview');

        return {
          'success': false,
          'message': 'Download failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 [DOWNLOAD WAV] Error: ${e.toString()}');
      return {
        'success': false,
        'message': 'Download error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // ✅ Download admin recording
  static Future<Map<String, dynamic>> downloadAdminRecording(
    String recordingId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/admin/recordings/$recordingId/download');
      final response = await http.get(
        url,
        headers: {
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'fileName': 'recording_$recordingId.mp3',
        };
      } else {
        return {
          'success': false,
          'message': 'Download failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Download error: ${e.toString()}'};
    }
  }

  /// ✅ ENHANCED COMPREHENSIVE EXPORT DATA
  static Future<Map<String, dynamic>> exportComprehensiveData({
    required DateTime startDate,
    required DateTime endDate,
    String audioFormat = 'wav',
    int sampleRate = 44100,
    bool includeAudio = true,
  }) async {
    final url = Uri.parse(
      '$baseUrl/admin/export-comprehensive?'
      'startDate=${startDate.toIso8601String()}'
      '&endDate=${endDate.toIso8601String()}'
      '&format=zip'
      '&audioFormat=$audioFormat'
      '&sampleRate=$sampleRate'
      '&includeAudio=$includeAudio',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/zip')) {
          return {
            'success': true,
            'data': response.bodyBytes,
            'format': 'zip',
            'contentType': contentType,
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Export failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ SUBMIT DOCTOR'S CLINICAL NOTES
  static Future<Map<String, dynamic>> submitClinicalNotes({
    required String patientId,
    String? diagnosis,
    String? treatmentPlan,
    String? followUpNotes,
    String? priorityLevel,
    List<String>? recommendations,
    Map<String, dynamic>? voiceAnalysisNotes,
  }) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/clinical-notes');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode({
          'diagnosis': diagnosis,
          'treatmentPlan': treatmentPlan,
          'followUpNotes': followUpNotes,
          'priorityLevel': priorityLevel,
          'recommendations': recommendations,
          'voiceAnalysisNotes': voiceAnalysisNotes,
          'submittedAt': DateTime.now().toIso8601String(),
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ ANALYZE PATIENT VOICE PROGRESSION
  static Future<Map<String, dynamic>> analyzePatientVoiceProgression(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/analyze-voice');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET VOICE RECORDINGS FOR PATIENT
  static Future<Map<String, dynamic>> getPatientVoiceRecordings(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/admin/patient/$patientId/recordings';
    final params = <String>[];
    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ UPDATE PATIENT INFORMATION
  static Future<Map<String, dynamic>> updatePatientInfo(
    String patientId,
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/update');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode(updates),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ DELETE PATIENT
  static Future<Map<String, dynamic>> deletePatient(String patientId) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/delete');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ EXPORT MULTIPLE PATIENTS WITH FILTERS
  static Future<Map<String, dynamic>> exportFilteredPatients({
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    bool? hasVoiceRecordings,
    int? minCompleteness,
    int? maxCompleteness,
    String format = 'zip',
    bool includeAudio = true,
    String audioFormat = 'wav',
  }) async {
    String url = '$baseUrl/admin/export-filtered';
    final params = <String>[];

    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
    if (priority != null) params.add('priority=$priority');
    if (hasVoiceRecordings != null)
      params.add('hasVoiceRecordings=$hasVoiceRecordings');
    if (minCompleteness != null) params.add('minCompleteness=$minCompleteness');
    params.add('format=$format');
    params.add('includeAudio=$includeAudio');
    params.add('audioFormat=$audioFormat');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/zip')) {
          return {
            'success': true,
            'data': response.bodyBytes,
            'format': 'zip',
            'contentType': contentType,
            'fileName': 'filtered_patients_export.zip',
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Export failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET VOICE ANALYSIS SUMMARY
  static Future<Map<String, dynamic>> getVoiceAnalysisSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/admin/voice-analysis-summary';
    final params = <String>[];

    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET ADMIN VOICE RECORDINGS WITH ADVANCED FILTERING
  static Future<Map<String, dynamic>> getVoiceRecordingsAdmin({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? taskType,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    String? patientSearch,
  }) async {
    String url = '$baseUrl/admin/voice-recordings';
    final params = <String>[];

    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
    if (userId != null) params.add('userId=$userId');
    if (taskType != null) params.add('taskType=$taskType');
    params.add('sortBy=$sortBy');
    params.add('sortOrder=$sortOrder');
    if (patientSearch != null) params.add('patientSearch=$patientSearch');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ BATCH EXPORT OPERATIONS
  static Future<Map<String, dynamic>> batchExportPatients({
    required List<String> patientIds,
    String format = 'zip',
    bool includeAudio = true,
    String audioFormat = 'wav',
  }) async {
    final url = Uri.parse('$baseUrl/admin/batch-export');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode({
          'patientIds': patientIds,
          'format': format,
          'includeAudio': includeAudio,
          'audioFormat': audioFormat,
        }),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/zip')) {
          return {
            'success': true,
            'data': response.bodyBytes,
            'format': 'zip',
            'contentType': contentType,
            'fileName':
                'batch_export_${DateTime.now().millisecondsSinceEpoch}.zip',
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Batch export failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET EXPORT HISTORY
  static Future<Map<String, dynamic>> getExportHistory() async {
    final url = Uri.parse('$baseUrl/admin/export-history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ VALIDATE EXPORT PARAMETERS
  static Future<Map<String, dynamic>> validateExportParameters({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? patientIds,
    bool includeAudio = true,
  }) async {
    final url = Uri.parse('$baseUrl/admin/validate-export');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode({
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'patientIds': patientIds,
          'includeAudio': includeAudio,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET SYSTEM STATUS
  static Future<Map<String, dynamic>> getSystemStatus() async {
    final url = Uri.parse('$baseUrl/admin/system-status');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ SEARCH PATIENTS WITH ADVANCED FILTERS
  static Future<Map<String, dynamic>> searchPatientsAdvanced({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? riskFactors,
    String? vhiSeverity,
    bool? hasVoiceRecordings,
    int? minCompleteness,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    int page = 1,
    int limit = 50,
  }) async {
    String url = '$baseUrl/admin/patients/search';
    final params = <String>[];

    if (searchQuery != null)
      params.add('q=${Uri.encodeComponent(searchQuery)}');
    if (startDate != null)
      params.add('startDate=${startDate.toIso8601String()}');
    if (endDate != null) params.add('endDate=${endDate.toIso8601String()}');
    if (riskFactors != null) params.add('riskFactors=${riskFactors.join(',')}');
    if (vhiSeverity != null) params.add('vhiSeverity=$vhiSeverity');
    if (hasVoiceRecordings != null)
      params.add('hasVoiceRecordings=$hasVoiceRecordings');
    if (minCompleteness != null) params.add('minCompleteness=$minCompleteness');
    params.add('sortBy=$sortBy');
    params.add('sortOrder=$sortOrder');
    params.add('page=$page');
    params.add('limit=$limit');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GENERATE CLINICAL REPORT
  static Future<Map<String, dynamic>> generateClinicalReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? patientIds,
    Map<String, dynamic>? parameters,
  }) async {
    final url = Uri.parse('$baseUrl/admin/reports/generate');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode({
          'reportType': reportType,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'patientIds': patientIds,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf')) {
          return {
            'success': true,
            'data': response.bodyBytes,
            'format': 'pdf',
            'contentType': contentType,
            'fileName':
                'clinical_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message':
              'Report generation failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ BULK UPDATE PATIENT DATA
  static Future<Map<String, dynamic>> bulkUpdatePatients({
    required List<String> patientIds,
    required Map<String, dynamic> updates,
  }) async {
    final url = Uri.parse('$baseUrl/admin/patients/bulk-update');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
        body: jsonEncode({'patientIds': patientIds, 'updates': updates}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ GET PATIENT TIMELINE
  static Future<Map<String, dynamic>> getPatientTimeline(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/admin/patient/$patientId/timeline');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ BACKUP SYSTEM DATA
  static Future<Map<String, dynamic>> backupSystemData({
    bool includeAudio = false,
    String format = 'zip',
  }) async {
    final url = Uri.parse(
      '$baseUrl/admin/backup?includeAudio=$includeAudio&format=$format',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/zip')) {
          return {
            'success': true,
            'data': response.bodyBytes,
            'format': 'zip',
            'contentType': contentType,
            'fileName':
                'system_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
          };
        } else {
          return jsonDecode(response.body);
        }
      } else {
        return {
          'success': false,
          'message': 'Backup failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// ✅ ERROR HANDLING HELPER
  static Map<String, dynamic> _handleError(dynamic error) {
    if (error is http.ClientException) {
      return {
        'success': false,
        'message': 'Network error: ${error.message}',
        'type': 'network_error',
      };
    } else if (error is FormatException) {
      return {
        'success': false,
        'message': 'Invalid response format',
        'type': 'format_error',
      };
    } else {
      return {
        'success': false,
        'message': 'Unexpected error: ${error.toString()}',
        'type': 'unknown_error',
      };
    }
  }

  /// ✅ REFRESH TOKEN
  static Future<Map<String, dynamic>> refreshToken() async {
    final url = Uri.parse('$baseUrl/admin/refresh-token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
        },
      );

      final responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true && responseBody['token'] != null) {
        _adminToken = responseBody['token'];
      }

      return responseBody;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<int?> submitOnboardingData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/onboarding');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        print("✅ Onboarding success: $decoded");
        return int.tryParse(decoded['userId'].toString());
      } else {
        print("❌ Onboarding failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ API Exception: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> submitDemographics(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/demographics');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Submission failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitConfounder(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/confounder');

    try {
      // Add timestamp fields if not already present
      final completeData = {
        'startedAt': DateTime.now().toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
        'durationMinutes': 0, // Calculate this if needed
        ...data,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(completeData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Submission failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitOralCancerData(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/oral-cancer');

    try {
      // Add timestamp fields if not already present
      final completeData = {
        'startedAt': DateTime.now().toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
        'durationMinutes': 0, // Calculate this if needed
        ...data,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(completeData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Submission failed',
        };
      }
    } catch (e) {
      print("❌ API Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitLarynxHypopharynxData(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/larynx');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Submission failed',
        };
      }
    } catch (e) {
      debugPrint('Error submitting larynx/hypopharynx data: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitPharynxCancerData(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/pharynx');

    try {
      // Calculate duration if needed
      final startedAt =
          payload['startedAt'] ?? DateTime.now().toIso8601String();
      final completedAt = DateTime.now().toIso8601String();
      final durationMinutes = DateTime.parse(
        completedAt,
      ).difference(DateTime.parse(startedAt)).inMinutes;

      // Transform payload to match backend expectations
      final completeData = {
        ...payload,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'durationMinutes': durationMinutes,
        'respondentIdentity': payload['respondentIdentity'] ?? 'Patient',
      };

      debugPrint("📤 Sending payload: ${jsonEncode(completeData)}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(completeData),
      );

      final responseBody = jsonDecode(response.body);
      debugPrint("📥 Received response: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Submission failed',
        };
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitVoiceRecording({
    required String userId,
    required String sessionId,
    required String taskType,
    required String language,
    required String audioPath,
    required int duration,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final url = Uri.parse('$baseUrl/voice-recordings');

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Audio file not found'};
      }

      var request = http.MultipartRequest('POST', url)
        ..fields.addAll({
          'userId': userId,
          'sessionId': sessionId,
          'taskType': taskType,
          'language': language,
          'duration': duration.toString(),
        });

      // Add file with proper content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
          contentType: MediaType('audio', 'm4a'),
        ),
      );

      // Track progress
      int bytesSent = 0;
      final totalBytes = await file.length();
      final streamedRequest = request.send();

      if (onSendProgress != null) {
        streamedRequest.asStream().listen((http.StreamedResponse response) {
          // This gives us the response headers as they arrive
        });
      }

      // Get the complete response
      final response = await streamedRequest;
      final responseData = await response.stream.bytesToString();

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': jsonDecode(responseData),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      debugPrint('Upload error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitGRBASRating({
    required String userId,
    required String sessionId,
    required int taskNumber,
    required int gScore,
    required int rScore,
    required int bScore,
    required int aScore,
    required int sScore,
    required String clinicianName,
    required String evaluationDate,
    required String comments,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grbas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'sessionId': sessionId,
        'taskNumber': taskNumber,
        'gScore': gScore,
        'rScore': rScore,
        'bScore': bScore,
        'aScore': aScore,
        'sScore': sScore,
        'clinicianName': clinicianName,
        'evaluationDate': evaluationDate,
        'comments': comments,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> saveSessionProgress({
    required String userId,
    required String sessionId,
    required String currentPage,
    required Map<String, dynamic> progressData,
  }) async {
    final url = Uri.parse('$baseUrl/session-progress/save');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'sessionId': sessionId,
          'currentPage': currentPage,
          'progressData': progressData,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to save progress: ${response.body}");
        return false;
      }
    } catch (e) {
      print("API error (save progress): $e");
      return false;
    }
  }

  // Fetch saved session progress
  static Future<Map<String, dynamic>?> fetchSessionProgress(
    String userId,
    String sessionId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/session-progress/fetch?userId=$userId&sessionId=$sessionId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return {
            'currentPage': decoded['currentPage'],
            'progressData': decoded['progressData'],
          };
        }
      }
      return null;
    } catch (e) {
      print("API error (fetch progress): $e");
      return null;
    }
  }

  // Mark session as complete
  static Future<bool> completeSession(String userId, String sessionId) async {
    final url = Uri.parse('$baseUrl/session-progress/complete');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'sessionId': sessionId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("API error (complete session): $e");
      return false;
    }
  }

  // static Future<Map<String, dynamic>> _handleApiCall(
  //   Future<http.Response> apiCall,
  //   String endpoint,
  // ) async {
  //   print('🔄 API Call started: $endpoint');
  //   print('📦 Request timestamp: ${DateTime.now().toIso8601String()}');

  //   try {
  //     final response = await apiCall;
  //     print('✅ API Response received - Status: ${response.statusCode}');

  //     // Check if response is JSON
  //     final contentType = response.headers['content-type'];
  //     final isJson =
  //         contentType != null && contentType.contains('application/json');

  //     if (isJson) {
  //       print('📋 Response is JSON format');
  //       final Map<String, dynamic> responseData = json.decode(response.body);

  //       // Ensure consistent response format
  //       final result = {
  //         'success':
  //             responseData['success'] ?? false, // Default to false if null
  //         'message': responseData['message'] ?? '',
  //         'statusCode': response.statusCode,
  //         'data': responseData['data'],
  //         'errors': responseData['errors'],
  //       };

  //       // Check if the response indicates an error
  //       if (response.statusCode >= 400) {
  //         print('❌ API Error: ${response.statusCode} - ${result['message']}');
  //         return result;
  //       }

  //       print('✅ API Call successful');
  //       return result;
  //     } else {
  //       // Handle non-JSON response (HTML error page)
  //       print('❌ API Response is not JSON - Content-Type: $contentType');

  //       // SAFELY get response body substring (fix for RangeError)
  //       String responseBodyPreview = '';
  //       if (response.body.isNotEmpty) {
  //         final length = response.body.length;
  //         final previewLength = length > 200 ? 200 : length;
  //         responseBodyPreview = response.body.substring(0, previewLength);
  //       }

  //       print(
  //         '📝 Response body (first ${responseBodyPreview.length} chars): $responseBodyPreview',
  //       );

  //       return {
  //         'success': false,
  //         'message': 'Server error: Received invalid response format',
  //         'statusCode': response.statusCode,
  //         'body': responseBodyPreview,
  //       };
  //     }
  //   } on SocketException {
  //     print('❌ Network error: SocketException - Unable to connect to server');
  //     return {
  //       'success': false,
  //       'message':
  //           'Network error: Unable to connect to server. Please check your internet connection.',
  //     };
  //   } on FormatException catch (e) {
  //     print('❌ Data format error: $e');
  //     return {'success': false, 'message': 'Data format error: ${e.message}'};
  //   } on http.ClientException catch (e) {
  //     print('❌ Connection error: $e');
  //     return {'success': false, 'message': 'Connection error: ${e.message}'};
  //   } catch (e) {
  //     print('❌ Unexpected error: $e');
  //     return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
  //   } finally {
  //     print('🏁 API Call completed: $endpoint');
  //   }
  // }

  // VHI API Methods
  static Future<Map<String, dynamic>> submitVHI(
    Map<String, dynamic> payload,
  ) async {
    return _handleApiCall(
      http.post(
        Uri.parse('$baseUrl/vhi/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ),
      'submitVHI',
    );
  }

  static Future<Map<String, dynamic>> getVHIHistory(
    String userId, {
    String? language,
  }) async {
    String url = '$baseUrl/vhi/history/$userId';
    if (language != null) {
      url += '?language=$language';
    }

    return _handleApiCall(
      http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'}),
      'getVHIHistory',
    );
  }

  static Future<Map<String, dynamic>> getVHIQuestions(String language) async {
    return _handleApiCall(
      http.get(
        Uri.parse('$baseUrl/vhi/questions/$language'),
        headers: {'Content-Type': 'application/json'},
      ),
      'getVHIQuestions',
    );
  }

  static Future<Map<String, dynamic>> _handleApiCall(
    Future<http.Response> apiCall,
    String endpoint,
  ) async {
    try {
      final response = await apiCall;

      // Check if response is JSON
      final contentType = response.headers['content-type'];
      final isJson =
          contentType != null && contentType.contains('application/json');

      if (isJson) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Ensure consistent response format
        final result = {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? '',
          'statusCode': response.statusCode,
          'data': responseData['data'],
          'errors': responseData['errors'],
        };

        return result;
      } else {
        // Handle non-JSON response
        String responseBodyPreview = '';
        if (response.body.isNotEmpty) {
          final length = response.body.length;
          final previewLength = length > 200 ? 200 : length;
          responseBodyPreview = response.body.substring(0, previewLength);
        }

        return {
          'success': false,
          'message': 'Server error: Received invalid response format',
          'statusCode': response.statusCode,
          'body': responseBodyPreview,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message':
            'Network error: Unable to connect to server. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      return {'success': false, 'message': 'Data format error: ${e.message}'};
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }
}

// Remove these methods from your ApiService:
// - testConnection()
// - The old VHI methods that had incorrect URLs
//   static Future<Map<String, dynamic>> submitVHI(
//     Map<String, dynamic> data,
//   ) async {
//     final url = Uri.parse('$baseUrl/vhi');

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(data),
//       );

//       final responseBody = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return {'success': true, 'data': responseBody};
//       } else {
//         return {
//           'success': false,
//           'message': responseBody['message'] ?? 'Submission failed',
//         };
//       }
//     } catch (e) {
//       debugPrint("❌ VHI API Error: $e");
//       return {'success': false, 'message': e.toString()};
//     }
//   }
// }
