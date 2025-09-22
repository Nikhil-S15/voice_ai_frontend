import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileStorageUtils {
  /// Gets the appropriate save path for the current platform
  static Future<String?> getSavePath() async {
    if (kIsWeb) {
      // Web: return null or handle web-specific storage
      return null;
    } else {
      // Mobile/Desktop: Use path_provider
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  /// Creates a file in the appropriate location for the platform
  static Future<File?> getSaveFile(String fileName) async {
    if (kIsWeb) {
      // Web doesn't support dart:io File operations
      return null;
    } else {
      final path = await getSavePath();
      return File('$path/$fileName');
    }
  }
}
