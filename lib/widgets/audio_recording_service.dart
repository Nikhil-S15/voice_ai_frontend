import 'package:flutter/material.dart';
import 'dart:async';

import 'package:voice_ai_app/services/audio_service.dart';

// Import your audio service (adjust the path as needed)
// import 'audio_recording_service.dart';

class AudioRecordingWidget extends StatefulWidget {
  final Function(String)? onRecordingComplete;
  final Function(String)? onRecordingError;

  const AudioRecordingWidget({
    super.key,
    this.onRecordingComplete,
    this.onRecordingError,
  });

  @override
  State<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends State<AudioRecordingWidget>
    with TickerProviderStateMixin {
  final AudioRecordingService _audioService = AudioRecordingService();

  bool _isInitialized = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _lastRecordingPath;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAudioService();

    // Setup pulse animation for recording
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeAudioService() async {
    final initialized = await _audioService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    if (!initialized) {
      widget.onRecordingError?.call('Failed to initialize audio service');
    }
  }

  void _startRecording() async {
    if (!_isInitialized || _audioService.isRecording) return;

    final success = await _audioService.startRecording();
    if (success) {
      setState(() {
        _recordingDuration = Duration.zero;
      });

      // Start duration timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });

      // Start pulse animation
      _pulseController.repeat(reverse: true);
    } else {
      widget.onRecordingError?.call('Failed to start recording');
    }
  }

  void _stopRecording() async {
    if (!_audioService.isRecording) return;

    final recordingPath = await _audioService.stopRecording();

    // Stop timer and animation
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _lastRecordingPath = recordingPath;
    });

    if (recordingPath != null) {
      widget.onRecordingComplete?.call(recordingPath);
    } else {
      widget.onRecordingError?.call('Failed to save recording');
    }
  }

  void _playLastRecording() async {
    if (_lastRecordingPath == null) return;

    if (_audioService.isPlaying) {
      await _audioService.stopPlaying();
    } else {
      await _audioService.playRecording(_lastRecordingPath!);
    }
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing audio...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording Duration Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _audioService.isRecording
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      _audioService.isRecording ? Colors.red : Colors.grey[600],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recording Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Record/Stop Button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _audioService.isRecording
                          ? _pulseAnimation.value
                          : 1.0,
                      child: FloatingActionButton(
                        onPressed: _audioService.isRecording
                            ? _stopRecording
                            : _startRecording,
                        backgroundColor: _audioService.isRecording
                            ? Colors.red
                            : Colors.blue,
                        child: Icon(
                          _audioService.isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),

                // Play/Pause Button (only show if there's a recording)
                if (_lastRecordingPath != null)
                  FloatingActionButton(
                    onPressed: _playLastRecording,
                    backgroundColor:
                        _audioService.isPlaying ? Colors.orange : Colors.green,
                    child: Icon(
                      _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Text
            Text(
              _getStatusText(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            // Recording Path (for debugging)
            if (_lastRecordingPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last recording: ${_lastRecordingPath!.split('/').last}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_audioService.isRecording) {
      return 'Recording... Tap stop when finished';
    } else if (_audioService.isPlaying) {
      return 'Playing recording...';
    } else if (_lastRecordingPath != null) {
      return 'Recording ready! Tap record for new or play to listen';
    } else {
      return 'Tap the microphone to start recording';
    }
  }
}
