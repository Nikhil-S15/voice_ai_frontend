import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the audio recording service
  Future<bool> initialize() async {
    try {
      // Check if recording is supported
      if (await _recorder.hasPermission()) {
        return true;
      }

      // Request microphone permission
      final permission = await Permission.microphone.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Error initializing audio service: $e');
      return false;
    }
  }

  /// Start audio recording
  Future<bool> startRecording({String? fileName}) async {
    try {
      if (_isRecording) {
        print('Already recording');
        return false;
      }

      // Check permission first
      if (!await _recorder.hasPermission()) {
        print('No microphone permission');
        return false;
      }

      // Generate file path
      final String recordingPath = await _getRecordingPath(fileName);

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.wav, // Use WAV for better web compatibility
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Start recording
      await _recorder.start(config, path: recordingPath);
      _isRecording = true;
      _currentRecordingPath = recordingPath;

      print('Recording started: $recordingPath');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop audio recording
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      print('Recording stopped: $path');
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Play recorded audio
  Future<bool> playRecording(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlaying();
      }

      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;

      // Listen for completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });

      return true;
    } catch (e) {
      print('Error playing recording: $e');
      return false;
    }
  }

  /// Stop playing audio
  Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  /// Pause playing audio
  Future<void> pausePlaying() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  /// Resume playing audio
  Future<void> resumePlaying() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error resuming playback: $e');
    }
  }

  /// Get recording duration (while recording)
  Stream<Duration> get recordingDuration {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      return Duration(seconds: count);
    });
  }

  /// Generate recording file path
  Future<String> _getRecordingPath(String? fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      // Create recordings directory if it doesn't exist
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final name =
          fileName ?? 'recording_${DateTime.now().millisecondsSinceEpoch}';
      return '${recordingsDir.path}/$name.wav';
    } catch (e) {
      // Fallback for web or when directory access fails
      final name =
          fileName ?? 'recording_${DateTime.now().millisecondsSinceEpoch}';
      return '$name.wav';
    }
  }

  /// Get list of all recordings
  Future<List<String>> getRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      if (!await recordingsDir.exists()) {
        return [];
      }

      final files = await recordingsDir.list().toList();
      return files
          .where((file) => file.path.endsWith('.wav'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting recordings: $e');
      return [];
    }
  }

  /// Delete a recording
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  /// Get recording file size
  Future<int> getRecordingSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
