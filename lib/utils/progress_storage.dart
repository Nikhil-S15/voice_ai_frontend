import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> saveProgress(
  String userId,
  String sessionId,
  Map<String, dynamic> data,
) async {
  final prefs = await SharedPreferences.getInstance();
  String key = '${userId}_${sessionId}_progress';
  await prefs.setString(key, jsonEncode(data));
}

Future<Map<String, dynamic>?> loadProgress(
  String userId,
  String sessionId,
) async {
  final prefs = await SharedPreferences.getInstance();
  String key = '${userId}_${sessionId}_progress';
  String? savedData = prefs.getString(key);

  if (savedData != null) {
    return jsonDecode(savedData);
  }
  return null;
}

Future<void> clearProgress(String userId, String sessionId) async {
  final prefs = await SharedPreferences.getInstance();
  String key = '${userId}_${sessionId}_progress';
  await prefs.remove(key);
}
