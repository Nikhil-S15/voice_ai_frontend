// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:path/path.dart' as path;
// import 'package:voice_ai_app/api_service.dart';
// import 'package:voice_ai_app/theme/app_colors.dart';
// import 'package:voice_ai_app/theme/app_text_styles.dart';
// import 'package:open_filex/open_filex.dart';

// import 'package:flutter_file_dialog/flutter_file_dialog.dart';

// class ExportFilesScreen extends StatefulWidget {
//   const ExportFilesScreen({Key? key}) : super(key: key);

//   @override
//   State<ExportFilesScreen> createState() => _ExportFilesScreenState();
// }

// class _ExportFilesScreenState extends State<ExportFilesScreen> {
//   List<FileSystemEntity> _files = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadFiles();
//   }

//   Future<void> _loadFiles() async {
//     setState(() => _loading = true);
//     final files = await ApiService.getExportedFiles();
//     setState(() {
//       _files = files;
//       _loading = false;
//     });
//   }

//   Future<void> _openFile(String filePath) async {
//     try {
//       final result = await OpenFilex.open(filePath);
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Cannot open file: ${result.message}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error opening file: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _shareFile(String filePath) async {
//     try {
//       // For sharing files to other apps
//       await FlutterFileDialog.saveFile(
//         params: SaveFileDialogParams(sourceFilePath: filePath),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing file: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _deleteFile(String filePath) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete File'),
//         content: Text(
//           'Are you sure you want to delete ${path.basename(filePath)}?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       final success = await ApiService.deleteExportedFile(filePath);
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('File deleted successfully')),
//         );
//         _loadFiles();
//       } else {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Failed to delete file')));
//       }
//     }
//   }

//   String _formatFileSize(int bytes) {
//     if (bytes <= 0) return '0 B';
//     const suffixes = ['B', 'KB', 'MB', 'GB'];
//     final i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
//   }

//   Widget _buildFileCard(FileSystemEntity file) {
//     final fileName = path.basename(file.path);
//     final fileExtension = path.extension(file.path).toLowerCase();
//     final fileStat = file.statSync();

//     IconData icon;
//     switch (fileExtension) {
//       case '.csv':
//         icon = Icons.table_chart;
//         break;
//       case '.pdf':
//         icon = Icons.picture_as_pdf;
//         break;
//       case '.json':
//         icon = Icons.code;
//         break;
//       case '.mp3':
//       case '.wav':
//       case '.m4a':
//         icon = Icons.audio_file;
//         break;
//       default:
//         icon = Icons.insert_drive_file;
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, color: AppColors.primary),
//         title: Text(fileName, style: AppTextStyles.bodyBold),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(_formatFileSize(fileStat.size)),
//             Text(
//               'Modified: ${DateFormat('yyyy-MM-dd HH:mm').format(fileStat.modified)}',
//               style: AppTextStyles.bodyText,
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.open_in_new, size: 20),
//               onPressed: () => _openFile(file.path),
//               tooltip: 'Open File',
//             ),
//             IconButton(
//               icon: const Icon(Icons.share, size: 20),
//               onPressed: () => _shareFile(file.path),
//               tooltip: 'Share File',
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//               onPressed: () => _deleteFile(file.path),
//               tooltip: 'Delete File',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Exported Files', style: AppTextStyles.appBarTitle),
//         backgroundColor: AppColors.primary,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _loadFiles,
//             tooltip: 'Refresh Files',
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _files.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.folder_open, size: 64, color: Colors.grey),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No exported files found',
//                     style: AppTextStyles.bodyText,
//                   ),
//                   Text(
//                     'Export data from the dashboard first',
//                     style: AppTextStyles.bodyText,
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _files.length,
//               itemBuilder: (context, index) => _buildFileCard(_files[index]),
//             ),
//     );
//   }
// }
