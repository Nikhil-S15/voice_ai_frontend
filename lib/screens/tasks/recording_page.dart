import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class EnhancedRecordingPage extends StatefulWidget {
  final String userId;
  final String sessionId;
  final String taskType;
  final String language;
  final String instructions;
  final bool isMultiTask;
  final List<Map<String, dynamic>>? taskList;

  const EnhancedRecordingPage({
    Key? key,
    required this.userId,
    required this.sessionId,
    required this.taskType,
    required this.language,
    required this.instructions,
    this.isMultiTask = false,
    this.taskList,
  }) : super(key: key);

  @override
  _EnhancedRecordingPageState createState() => _EnhancedRecordingPageState();
}

class _EnhancedRecordingPageState extends State<EnhancedRecordingPage>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;
  String? _filePath;
  int _attempts = 0;
  int _currentTaskIndex = 0;
  double _uploadProgress = 0;
  double _recordingAmplitude = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  // Subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudio();
    _checkPermissions();
    if (widget.isMultiTask) {
      _restoreProgress();
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAudio() async {
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _restoreProgress() async {
    try {
      final saved = await ApiService.fetchSessionProgress(
        widget.userId,
        widget.sessionId,
      );
      if (saved != null) {
        final progress = saved['progressData'];
        setState(() {
          _currentTaskIndex = progress['currentTaskIndex'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error restoring progress: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError('Microphone permission is required for recording');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showError('Microphone permission not granted');
        return;
      }

      // Create file path - web compatible
      String filePath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        filePath =
            '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      } catch (e) {
        // Fallback for web
        filePath = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      }

      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav, // Better web compatibility
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      // Listen to amplitude changes
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((amp) {
        if (mounted) {
          setState(() {
            _recordingAmplitude = _normalizeAmplitude(amp.current);
          });
        }
      });

      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _filePath = filePath;
        _recordingDuration = 0;
        _attempts++;
        _uploadProgress = 0;
      });

      // Start animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      // Start duration timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingDuration++);
        }
      });
    } catch (e) {
      _showError('Recording failed: ${e.toString()}');
    }
  }

  double _normalizeAmplitude(double dbFs) {
    const minDb = -60.0;
    const maxDb = 0.0;
    double normalized = (dbFs - minDb) / (maxDb - minDb);
    return normalized.clamp(0.0, 1.0);
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _amplitudeSubscription?.cancel();
      _pulseController.stop();
      _waveController.stop();
      _pulseController.reset();
      _waveController.reset();

      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _filePath = path ?? _filePath;
        _recordingAmplitude = 0;
      });

      if (_filePath != null) {
        _showSuccess('Recording completed successfully');
      }
    } catch (e) {
      _showError('Failed to stop recording: ${e.toString()}');
    }
  }

  Future<void> _playRecording() async {
    if (_filePath == null) {
      _showError("No recording to play");
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_filePath!));
    } catch (e) {
      _showError("Playback failed: ${e.toString()}");
    }
  }

  Future<void> _uploadRecording() async {
    if (_filePath == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      if (widget.isMultiTask) {
        // Multi-task upload
        final response = await ApiService.submitVoiceRecording(
          userId: widget.userId,
          sessionId: widget.sessionId,
          taskType: getCurrentTask()['id'].toString(),
          language: widget.language,
          audioPath: _filePath!,
          duration: _recordingDuration,
          onSendProgress: (sent, total) {
            if (mounted) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );

        if (response['success'] == true) {
          _showSuccess('Recording uploaded successfully');
          if (_currentTaskIndex < getTaskList().length - 1) {
            _nextTask();
          } else {
            _finishSession();
          }
        } else {
          throw Exception(response['message'] ?? 'Upload failed');
        }
      } else {
        // Single task upload
        final file = File(_filePath!);
        final audioBytes = await file.readAsBytes();

        final url =
            Uri.parse('${ApiService.baseUrl}/acoustic-tasks/upload-recording');
        var request = http.MultipartRequest('POST', url);

        request.fields['userId'] = widget.userId;
        request.fields['sessionId'] = widget.sessionId;
        request.fields['taskType'] = widget.taskType;
        request.fields['language'] = widget.language;
        request.fields['recordingDevice'] = 'built_in_mic';
        request.fields['durationMs'] = (_recordingDuration * 1000).toString();
        request.fields['sampleRate'] = '44100';
        request.fields['bitDepth'] = '16';

        request.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename:
                '${widget.taskType}_${DateTime.now().millisecondsSinceEpoch}.wav',
          ),
        );

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          _showSuccess('Recording uploaded successfully');
          Navigator.pop(context, true);
        } else {
          throw Exception('Upload failed: $responseBody');
        }
      }
    } catch (e) {
      _showError('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _nextTask() {
    setState(() {
      _currentTaskIndex++;
      _resetRecording();
    });
  }

  void _finishSession() {
    // Navigate to GRBAS rating or completion screen
    Navigator.pushReplacementNamed(context, '/grbas-rating', arguments: {
      'userId': widget.userId,
      'sessionId': widget.sessionId,
      'language': widget.language,
    });
  }

  void _resetRecording() {
    setState(() {
      _filePath = null;
      _hasRecording = false;
      _recordingDuration = 0;
      _uploadProgress = 0;
      _recordingAmplitude = 0;
    });
    _audioPlayer.stop();
  }

  List<Map<String, dynamic>> getTaskList() {
    return widget.taskList ??
        [
          {'id': 1, 'title': widget.taskType, 'text': widget.instructions}
        ];
  }

  Map<String, dynamic> getCurrentTask() {
    final tasks = getTaskList();
    return tasks[_currentTaskIndex.clamp(0, tasks.length - 1)];
  }

  String _getTaskTitle() {
    if (widget.isMultiTask) {
      return getCurrentTask()['title'];
    }

    switch (widget.taskType) {
      case 'prolonged_vowel':
        return 'Prolonged Vowel Phonation';
      case 'maximum_phonation':
        return 'Maximum Phonation Time';
      case 'rainbow_passage':
        return 'Rainbow Passage Reading';
      case 'malayalam_passage':
        return 'Malayalam Passage Reading';
      default:
        return widget.taskType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = getCurrentTask();
    final taskList = getTaskList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isMultiTask
              ? '${_getTaskTitle()} (${_currentTaskIndex + 1}/${taskList.length})'
              : _getTaskTitle(),
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          if (widget.isMultiTask && _currentTaskIndex > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  _currentTaskIndex--;
                  _resetRecording();
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructions', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    Text(
                      widget.isMultiTask
                          ? currentTask['text']
                          : widget.instructions,
                      style: AppTextStyles.bodyText,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recording Visualization
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated microphone icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? AppColors.primary
                                  : AppColors.grey.withOpacity(0.3),
                              boxShadow: _isRecording
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _isRecording ? Icons.mic : Icons.mic_off,
                              size: 60,
                              color:
                                  _isRecording ? Colors.white : AppColors.grey,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Recording status and duration
                    Text(
                      _isRecording
                          ? 'Recording... ${_formatDuration(_recordingDuration)}'
                          : _hasRecording
                              ? 'Recording ready (${_formatDuration(_recordingDuration)})'
                              : 'Ready to record',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color:
                            _isRecording ? AppColors.primary : AppColors.text,
                      ),
                    ),

                    // Amplitude visualization
                    if (_isRecording) ...[
                      const SizedBox(height: 20),
                      Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Container(color: AppColors.grey.withOpacity(0.1)),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: MediaQuery.of(context).size.width *
                                    _recordingAmplitude,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.5),
                                      AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 20),
                      const Text('Uploading recording...'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppColors.grey.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      Text('${(_uploadProgress * 100).toStringAsFixed(1)}%'),
                    ],
                  ],
                ),
              ),
            ),

            // Control buttons
            if (!_isRecording && !_hasRecording && _attempts == 0)
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              )
            else if (_isRecording)
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              )
            else if (_hasRecording) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPlaying ? null : _playRecording,
                      icon: _isPlaying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isPlaying ? 'Playing...' : 'Play'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _resetRecording();
                        _startRecording();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-record'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadRecording,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Submit Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
