// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:voice_ai_app/api_service.dart';
// import 'package:voice_ai_app/theme/app_colors.dart';
// import 'package:voice_ai_app/theme/app_text_styles.dart';
// import 'package:voice_ai_app/widgets/app_buttons.dart';

// class AdminVoiceRecordingsScreen extends StatefulWidget {
//   const AdminVoiceRecordingsScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminVoiceRecordingsScreen> createState() =>
//       _AdminVoiceRecordingsScreenState();
// }

// class _AdminVoiceRecordingsScreenState
//     extends State<AdminVoiceRecordingsScreen> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String? _selectedTaskType;
//   List<dynamic> _recordings = [];
//   bool _loading = false;
//   final TextEditingController _userIdController = TextEditingController();

//   final List<String> _taskTypes = [
//     'Sustained Vowel',
//     'Reading Passage',
//     'Spontaneous Speech',
//     'Pitch Glide',
//     'All Tasks',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadRecordings();
//   }

//   Future<void> _loadRecordings() async {
//     setState(() => _loading = true);
//     try {
//       final response = await ApiService.getAdminVoiceRecordings(
//         startDate: _startDate,
//         endDate: _endDate,
//         userId: _userIdController.text.isNotEmpty
//             ? _userIdController.text
//             : null,
//         taskType: _selectedTaskType != 'All Tasks' ? _selectedTaskType : null,
//       );

//       if (response['success'] == true) {
//         setState(() => _recordings = response['data'] ?? []);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(response['message'] ?? 'Failed to load recordings'),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _downloadRecording(String recordingId) async {
//     try {
//       final response = await ApiService.downloadAdminRecording(recordingId);
//       if (response['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Downloaded: ${response['fileName']}')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Download failed')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//     }
//   }

//   void _showDateRangePicker() async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.primary,
//               onPrimary: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//       _loadRecordings();
//     }
//   }

//   Widget _buildRecordingCard(Map<String, dynamic> recording) {
//     final userInfo = recording['Onboarding'] ?? {};
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: const Icon(Icons.audio_file, color: AppColors.primary),
//         title: Text(
//           '${userInfo['participantName'] ?? 'Unknown'} (${userInfo['participantId'] ?? 'No ID'})',
//           style: AppTextStyles.bodyBold,
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Task: ${recording['taskType']}'),
//             Text(
//               'Duration: ${(recording['durationMs'] / 1000).toStringAsFixed(1)}s',
//             ),
//             Text('Device: ${recording['recordingDevice'] ?? 'Unknown'}'),
//             Text(
//               'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(recording['createdAt']))}',
//             ),
//           ],
//         ),
//         trailing: IconButton(
//           icon: const Icon(Icons.download, color: AppColors.primary),
//           onPressed: () => _downloadRecording(recording['id'].toString()),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Voice Recordings', style: AppTextStyles.appBarTitle),
//         backgroundColor: AppColors.primary,
//       ),
//       body: Column(
//         children: [
//           // Filters
//           Card(
//             margin: const EdgeInsets.all(16),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Text('Filters', style: AppTextStyles.titleLarge),
//                   const SizedBox(height: 16),

//                   // User ID Filter
//                   TextField(
//                     controller: _userIdController,
//                     decoration: const InputDecoration(
//                       labelText: 'User ID',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) => _loadRecordings(),
//                   ),
//                   const SizedBox(height: 16),

//                   // Task Type Filter
//                   DropdownButtonFormField<String>(
//                     value: _selectedTaskType,
//                     decoration: const InputDecoration(
//                       labelText: 'Task Type',
//                       border: OutlineInputBorder(),
//                     ),
//                     items: _taskTypes.map((type) {
//                       return DropdownMenuItem(value: type, child: Text(type));
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() => _selectedTaskType = value);
//                       _loadRecordings();
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Date Range
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _startDate == null
//                               ? 'All dates'
//                               : '${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.calendar_today),
//                         onPressed: _showDateRangePicker,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Results
//           Expanded(
//             child: _loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _recordings.isEmpty
//                 ? const Center(child: Text('No recordings found'))
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: _recordings.length,
//                     itemBuilder: (context, index) =>
//                         _buildRecordingCard(_recordings[index]),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
