import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/tasks/grbasrating.dart';

class VoiceTaskPage extends StatefulWidget {
  final String userId;
  final String sessionId;
  final String language;

  const VoiceTaskPage({
    Key? key,
    required this.userId,
    required this.sessionId,
    required this.language,
  }) : super(key: key);

  @override
  _VoiceTaskPageState createState() => _VoiceTaskPageState();
}

class _VoiceTaskPageState extends State<VoiceTaskPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  bool _isUploading = false;
  String? _currentAudioPath;
  int _recordingDuration = 0;
  int _currentTaskIndex = 0;
  Timer? _recordingTimer;
  double _recordingAmplitude = 0;
  double _uploadProgress = 0;
  String? _playerError;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  @override
  void initState() {
    super.initState();
    _restoreProgress();
    _initAudioPlayer();
    _checkPermissions();
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
          // Restore the current task index if saved; else default 0
          _currentTaskIndex = progress['currentTaskIndex'] ?? 0;
          // Optionally restore other related data (e.g., completed tasks audio)
        });
      }
    } catch (e) {
      debugPrint('Error restoring progress: $e');
    }
  }

  final List<Map<String, dynamic>> _englishInstructions = [
    {
      'id': 1,
      'title': 'Prolonged Vowel Phonation',
      'text':
          "Take a deep breath and say the vowel sound /a/ (as in 'car') for as long as you can in one breath. Try to keep your voice steady and clear.\n\nVowels: A, E, I, O, U",
    },
    {
      'id': 2,
      'title': 'Maximum Phonation Time (MPT)',
      'text':
          "Breathe in deeply and hold the vowel /a/ for as long as possible in one breath. The goal is to measure how long you can produce sound without taking another breath.\n\nConsonants: P, B, M, V, T, D, N, R, L, S, T, D, N, L, SH, CH, J, ZH, Y, K, G, H",
    },
    {
      'id': 3,
      'title': 'Rainbow Passage Reading',
      'text':
          "You will be shown a short paragraph called the 'Rainbow Passage'. Read it aloud in your natural voice and pace.\n\nParagraph:\nWhen the sunlight strikes raindrops in the air, they act as a prism and form a rainbow. The rainbow is a division of white light into many beautiful colors. These take the shape of a long round arch, with its path high above, and its two ends apparently beyond the horizon. There is, according to legend, a boiling pot of gold at one end. People look, but no one ever finds it. When a man looks for something beyond his reach, his friends say he is looking for the pot of gold at the end of the rainbow.",
    },
    {
      'id': 4,
      'title': 'Pitch Glides',
      'text':
          "Start by making a low-pitched sound and smoothly glide to a high-pitched sound, like a siren. Then do the reverse: from high to low pitch.",
    },
    {
      'id': 5,
      'title': 'Loudness Task',
      'text':
          "Say the vowel /a/ three times: first softly, then in your normal voice, and then loudly. Try to make each version as distinct as possible.",
    },
    {
      'id': 6,
      'title': 'Free Speech',
      'text':
          "Speak about a topic of your choice, such as your day or a favorite memory, for about 30 to 60 seconds. Speak naturally and continuously.",
    },
    {
      'id': 7,
      'title': 'Respiration Observation',
      'text':
          "Sit calmly and breathe normally. We will observe your breathing patterns. You do not need to do anything special.",
    },
    {
      'id': 8,
      'title': 'Reflex Cough',
      'text':
          "If you feel a natural urge to cough, please do so. This will help us understand your natural cough reflex.",
    },
    {
      'id': 9,
      'title': 'Voluntary Cough',
      'text':
          "Take a deep breath and cough as if you are trying to clear your throat. Do this once or twice.",
    },
    {
      'id': 10,
      'title': 'Breath Sounds',
      'text':
          "Breathe normally through your mouth for a few seconds. We will listen to the sounds of your breathing.",
    },
  ];

  final List<Map<String, dynamic>> _malayalamInstructions = [
    {
      'id': 1,
      'title': 'നീണ്ടുള്ള അക്ഷരപ്രയോഗം',
      'text':
          "MPT:ദീർഘ ശ്വാസം എടുക്കുക. ശ്വാസം എടുത്തതിന് ശേഷം ‘‘ആാാാ...’’എന്ന് ഒരേ ശബ്ദത്തിലും ഒരേ ശക്തിയിലും ശ്വാസം തീരുന്നത് വരെ നീട്ടി പറയുക.",
    },
    {
      'id': 2,
      'title': 'പരമാവധി ധ്വനി സമയം',
      'text':
          "ദീർഘ ശ്വാസം എടുത്തതിന് ശേഷം, /ആ/ സ്വരം വ്യക്തവും സ്ഥിരവുമായ ശബ്ദത്തിൽ കഴിയുന്നത്ര നേരം ഒരൊറ്റ ശ്വാസത്തിൽ ഉച്ചരിക്കുക. ശബ്ദത്തിന്റെ ഉയരത്തിലും ശക്തിയിലും മാറ്റം വരുത്താതെ തുടരണം..\n\nസ്വരങ്ങൾ:\nഅ, എ, ഈ, ഒ, ഉ",
    },
    {
      'id': 3,
      'title': 'തേങ്ങു പാരഗ്രാഫ്',
      'text':
          "താഴെ നൽകിയിരിക്കുന്ന പാരഗ്രാഫ് ഉച്ചരിക്കുക. നിങ്ങളുടെ സ്വാഭാവിക ശബ്ദത്തിലും ശൈലിയിലുമാണ് വായിക്കേണ്ടത്.\n\nമനുഷ്യർക്ക് സഹായം ചെയ്യുന്ന മരങ്ങളിൽ ഒന്നാണ് തെങ്ങ്. പല തരം തെങ്ങിൻ കായ്കളുണ്ട്. ഇവയിൽ ചിലത് നീണ്ടതും ചിലത് ഉരുണ്ടതുമാണ്. ഇവ ഇളപ്പമായിരിക്കുമ്പോൾ പച്ച നിറത്തിലും, മൂക്കുമ്പോൾ ഇളം മഞ്ഞ നിറമായും മാറും. കേരളീയന്റെ ജീവിതത്തിലെ അവിഭാജ്യ ഘടകമാണ് തെങ്ങ്. ഇളം തേങ്ങയുടെ അകത്തുള്ള നീരിന് ഔഷധഗുണമുണ്ട്. മൃദുവായ ചകിരി മെത്ത നിറക്കാൻ ഉപയോഗിക്കും. ബലമുള്ള മേശയും കസേരയും ഉണ്ടാക്കാൻ തെങ്ങ് ഉചിതമാണ്. പലഹാരങ്ങളും തേങ്ങ പിഴിഞ്ഞെടുത്ത പാലുകൊണ്ടു പാകം ചെയ്യാം. പക്ഷികൾ ഇവയുടെ ചകിരികൊണ്ട് മഴക്കാലത്ത് കൂടുണ്ടാക്കും.",
    },
    {
      'id': 4,
      'title': 'പിച്ച് ഗ്ലൈഡുകൾ',
      'text':
          "താഴ്ന്ന ശബ്ദത്തിൽ തുടങ്ങി, പതിയെ ഉയർന്ന ശബ്ദത്തിലേക്ക് കൊണ്ടുപോകൂ. പിന്നെ തിരിച്ചും ചെയ്യൂ.",
    },

    {
      'id': 5,
      'title': 'ശബ്ദതീവ്രത',
      'text':
          "/ആ/ എന്ന് മൂന്നു പ്രാവശ്യം പറയുക — ആദ്യം മൃദുവായി, പിന്നെ നിങ്ങളുടെ സാധാരണ ശബ്ദത്തിൽ, ശേഷം ശബ്ദം ഉയർത്തി. ഓരോ പ്രാവശ്യവും വ്യക്തമായിരിക്കാൻ ശ്രദ്ധിക്കുക.",
    },
    {
      'id': 6,
      'title': 'സ്വതന്ത്രമായി സംസാരിക്കൽ',
      'text':
          "നിങ്ങൾക്ക് ഇഷ്ടമുള്ള വിഷയം കുറിച്ച് 30–60 സെക്കന്റ് സ്വാഭാവികമായി തുടർച്ചയായി സംസാരിക്കുക.",
    },
    {
      'id': 7,
      'title': 'ശ്വാസമെടുക്കൽ നിരീക്ഷണം',
      'text':
          "സാധാരണ നിലയിൽ ഇരിക്കുക, സ്വാഭാവികമായി ശ്വാസമെടുക്കുക. ശ്വാസമെടുക്കലിന്റെ താളവും രീതി പരിശോധിക്കും.",
    },
    {
      'id': 8,
      'title': 'സ്വാഭാവിക ചുമ',
      'text':
          "നിങ്ങൾക്ക് സ്വാഭാവികമായി ചുമക്കാൻ തോന്നുന്നുണ്ടെങ്കിൽ, ദയവായി ചുമയ്ക്കുക. ഇത് നിങ്ങളുടെ സ്വാഭാവിക ചുമ  മനസ്സിലാക്കാൻ സഹായിക്കും.",
    },
    {
      'id': 9,
      'title': 'സ്വമേധയാ ചുമ',
      'text': "ഒരു ദീർഘ ശ്വാസം എടുക്കൂ… പിന്നെ ശക്തിയായി രണ്ടുതവണ ചുമയ്ക്കൂ.",
    },
    {
      'id': 10,
      'title': 'ശ്വാസ ശബ്ദങ്ങൾ',
      'text':
          " “ശാന്തമായി ഇരുന്ന്, സാധാരണ പോലെ ശ്വസിക്കുക ഞങ്ങൾ നിങ്ങളുടെ ശ്വാസത്തിന്റെ രീതികൾ ശ്രദ്ധിക്കും. പ്രത്യേകിച്ച് ഒന്നും ചെയ്യേണ്ടതില്ല.",
    },
  ];

  List<Map<String, dynamic>> get _instructions {
    return widget.language == 'english'
        ? _englishInstructions
        : _malayalamInstructions;
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _initAudioPlayer();
  //   _checkPermissions();
  // }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError('Microphone permission is required');
    }
  }

  Future<void> _initAudioPlayer() async {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.stopped) {
          _playerError = null;
        }
      });
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
    });

    _audioPlayer.onLog.listen((message) {
      debugPrint('AudioPlayer log: $message');
    });
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showError('Microphone permission not granted');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 300))
          .listen((amp) {
            setState(() {
              _recordingAmplitude = _normalizeAmplitude(amp.current);
            });
          }, onError: (e) => debugPrint('Amplitude error: $e'));

      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _currentAudioPath = path;
        _recordingDuration = 0;
        _playerError = null;
        _uploadProgress = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
      });
    } catch (e) {
      _showError('Failed to start recording: ${e.toString()}');
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
      _recordingTimer?.cancel();
      _amplitudeSubscription?.cancel();

      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _currentAudioPath = path;
      });
    } catch (e) {
      _showError('Failed to stop recording: ${e.toString()}');
    }
  }

  Future<void> _playRecording() async {
    if (_currentAudioPath == null) {
      _showError("No recording to play");
      return;
    }

    try {
      final file = File(_currentAudioPath!);
      if (!await file.exists()) {
        throw Exception("File does not exist: $_currentAudioPath");
      }

      final fileSize = await file.length();
      debugPrint("🎤 Playing file: $_currentAudioPath ($fileSize bytes)");

      if (fileSize == 0) {
        throw Exception("File is empty");
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_currentAudioPath!));
    } catch (e) {
      _showError("Playback failed: $e");
      debugPrint("Playback error: $e");
    }
  }

  Future<void> _resetAudioPlayer() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    } catch (e) {
      debugPrint('Reset error: $e');
    }
  }

  Future<void> _submitRecording() async {
    if (_currentAudioPath == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final response = await ApiService.submitVoiceRecording(
        userId: widget.userId,
        sessionId: widget.sessionId,
        taskType: _instructions[_currentTaskIndex]['id'].toString(),
        language: widget.language,
        audioPath: _currentAudioPath!,
        duration: _recordingDuration,
        onSendProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (response['success'] == true) {
        _showSuccess('Recording submitted successfully');

        // ✅ Auto move to next page if this was the last task
        if (_currentTaskIndex == _instructions.length - 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GRBASRatingScreen(
                userId: widget.userId,
                sessionId: widget.sessionId,
                language: widget.language,
              ),
            ),
          );
        } else {
          _nextTask();
        }
      } else {
        _showError(response['message'] ?? 'Submission failed');
      }
    } catch (e) {
      _showError('Failed to submit recording: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _nextTask() {
    if (_currentTaskIndex < _instructions.length - 1) {
      setState(() {
        _currentTaskIndex++;
        _currentAudioPath = null;
        _recordingDuration = 0;
        _hasRecording = false;
        _uploadProgress = 0;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GRBASRatingScreen(
            userId: widget.userId,
            sessionId: widget.sessionId,
            language: widget.language,
          ),
        ),
      );
    }
  }

  void _reRecord() {
    setState(() {
      _currentAudioPath = null;
      _hasRecording = false;
      _recordingDuration = 0;
      _uploadProgress = 0;
    });
    _audioPlayer.stop();
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

  String _formatDuration(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _recordingTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = _instructions[_currentTaskIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${currentTask['title']} (${_currentTaskIndex + 1}/${_instructions.length})',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          currentTask['text'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_playerError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _playerError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Text(
                              'Recording: ${_formatDuration(_recordingDuration)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 30,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeOut,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        _recordingAmplitude,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isUploading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            const Text(
                              'Uploading Recording...',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _uploadProgress),
                            Text(
                              '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recording State Flow
            if (!_hasRecording && !_isRecording)
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else if (_isRecording)
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
            else if (_hasRecording)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPlaying ? null : _playRecording,
                          icon: _isPlaying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _isPlaying ? 'Playing...' : 'Play Recording',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _reRecord,
                          icon: const Icon(Icons.replay),
                          label: const Text('Re-record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _submitRecording,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Submit Recording',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            if (_hasRecording && !_isUploading)
              ElevatedButton(
                onPressed: _nextTask,
                child: Text(
                  _currentTaskIndex == _instructions.length - 1
                      ? 'Finish Session'
                      : 'Next Task',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
