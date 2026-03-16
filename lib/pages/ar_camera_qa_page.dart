import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/vision_service.dart';
import '../services/student_service.dart';

class ARCameraQAPage extends StatefulWidget {
  final String modelTitle;
  final String modelPath;

  const ARCameraQAPage({
    super.key,
    required this.modelTitle,
    required this.modelPath,
  });

  @override
  State<ARCameraQAPage> createState() => _ARCameraQAPageState();
}

class _ARCameraQAPageState extends State<ARCameraQAPage> {
  // Camera (used for snapshot capture, NOT live preview)
  CameraController? _cameraController;
  bool _isCameraReady = false;
  Uint8List? _bgFrame; // latest camera snapshot shown as background
  Timer? _frameTimer;

  // Q&A
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late IO.Socket _socket;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _subtitle = '';
  String _userQuestion = '';
  String _studentContext = '';

  // Model
  double _modelSize = 250;

  // Language
  String _selectedLanguage = 'en-US';
  String _selectedLangDisplayKey = 'English';

  final Map<String, String> _languages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Marathi': 'mr-IN',
  };

  static const Map<String, String> _backendLangKey = {
    'English': 'english',
    'Hindi': 'hindi',
    'Marathi': 'marathi',
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSpeech();
    _initAudioPlayer();
    _initSocket();
    _fetchStudentContext();
  }

  // ── Camera (snapshot mode) ──

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraReady = true);

      // Take initial snapshot
      await _captureBackgroundFrame();

      // Periodically refresh background (every 1.5s)
      _frameTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _captureBackgroundFrame();
      });
    } catch (e) {
      debugPrint('[AR Camera] Camera init error: $e');
    }
  }

  Future<void> _captureBackgroundFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      if (mounted) setState(() => _bgFrame = bytes);
    } catch (e) {
      debugPrint('[AR Camera] Frame capture error: $e');
    }
  }

  Future<Uint8List?> _captureFrame() async {
    // Return latest bg frame for Vision API
    if (_bgFrame != null) return _bgFrame;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      final xFile = await _cameraController!.takePicture();
      return await xFile.readAsBytes();
    } catch (e) {
      debugPrint('[AR Camera] Capture error: $e');
      return null;
    }
  }

  // ── Student context ──

  Future<void> _fetchStudentContext() async {
    try {
      final data = await StudentService.fetchFullStudentData();
      final profile = data['profile'] ?? {};
      final perf = data['performance'] ?? {};
      final currentPerf = perf['currentPerformance'] ?? {};

      final buf = StringBuffer();
      buf.writeln('[STUDENT INFO — only mention if student asks or if relevant]');
      buf.writeln('Name: ${profile['name'] ?? 'N/A'}');
      buf.writeln('Class: ${profile['classes'] ?? 'N/A'} | Course: ${profile['Course'] ?? 'N/A'}');
      buf.writeln('Overall Score: ${perf['score'] ?? 'N/A'}/100 | Risk: ${perf['riskLevel'] ?? 'N/A'}');
      buf.writeln('Attendance: ${currentPerf['attendance'] ?? 'N/A'}% | Marks: ${currentPerf['internalMarks'] ?? 'N/A'}%');

      if (mounted) setState(() => _studentContext = buf.toString());
    } catch (e) {
      debugPrint('[AR Camera] Student context error: $e');
    }
  }

  // ── Socket.IO ──

  void _initSocket() {
    _socket = IO.io(
      'https://campuspp-f7qx.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) => debugPrint('[AR Camera] Socket connected'));

    _socket.on('aiResponse', (data) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _subtitle = _cleanMarkdown(data['response'] ?? "I couldn't process that.");
        });
      }
    });

    _socket.on('ttsAudio', (data) async {
      try {
        final Uint8List audioBytes = base64Decode(data['audioBase64']);
        if (mounted) setState(() => _isProcessing = false);
        await _audioPlayer.play(BytesSource(audioBytes));
      } catch (e) {
        debugPrint('[AR Camera] Audio error: $e');
      }
    });

    _socket.on('ttsError', (_) {
      if (mounted) setState(() => _isProcessing = false);
    });

    _socket.onDisconnect((_) => debugPrint('[AR Camera] Socket disconnected'));
  }

  // ── Audio ──

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  // ── STT ──

  void _initSpeech() {
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech Error: ${val.errorMsg}')),
            );
          }
        },
      );

      if (available) {
        await _audioPlayer.stop();
        setState(() {
          _isListening = true;
          _subtitle = '';
          _userQuestion = '';
        });

        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              setState(() => _userQuestion = val.recognizedWords);
              _onQuestionReady(val.recognizedWords);
            }
          },
          localeId: _selectedLanguage,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: false,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // ── Q&A Pipeline ──

  Future<void> _onQuestionReady(String question) async {
    if (question.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _subtitle = 'Looking at what you see...';
      });
    }

    // Step 1: Capture camera frame → Vision API
    String visionDesc = '';
    try {
      final frameBytes = await _captureFrame();
      if (frameBytes != null) {
        final base64Img = base64Encode(frameBytes);
        visionDesc = await VisionService.analyzeImage(base64Img);
        debugPrint('[AR Camera] Vision: $visionDesc');
      }
    } catch (e) {
      debugPrint('[AR Camera] Vision failed: $e');
    }

    if (mounted) setState(() => _subtitle = 'Thinking...');

    // Step 2: Build prompt
    final String systemPrompt =
        'You are a friendly teacher having a casual conversation with a student. '
        'The student is in AR mode — they see a 3D model of "${widget.modelTitle}" placed on their real environment through their camera. '
        'You can see what their camera sees along with the model. '
        'Talk like a real human — warm, natural, no robotic tone. '
        'Keep it super short: 1-2 sentences MAX. No bullet points, no lists, no headings. '
        'Do NOT use markdown formatting (no **, no ##, no bullets). Plain text only. '
        'Never dump all info at once. Answer only what they asked, nothing extra.'
        '${visionDesc.isNotEmpty ? '\n\n[What the camera sees right now: $visionDesc]' : ''}'
        '${_studentContext.isNotEmpty ? '\n\n$_studentContext' : ''}';

    // Step 3: Send via socket
    _socket.emit('textMessage', {
      'message': question,
      'systemPrompt': systemPrompt,
      'language': _backendLangKey[_selectedLangDisplayKey] ?? 'english',
      'languageCode': _selectedLanguage,
    });
  }

  // ── Helpers ──

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        .replaceAll(RegExp(r'~~(.+?)~~'), r'$1')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .replaceAll('\\n', '\n')
        .replaceAll('\\\\', '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _socket.disconnect();
    _socket.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Camera snapshot as background (static image, no GPU surface)
          if (_bgFrame != null)
            Positioned.fill(
              child: Image.memory(
                _bgFrame!,
                fit: BoxFit.cover,
                gaplessPlayback: true, // prevents flicker between frames
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Layer 2: 3D model overlay (only WebView surface, no camera surface competing)
          if (widget.modelPath.isNotEmpty)
            Center(
              child: SizedBox(
                width: _modelSize,
                height: _modelSize,
                child: ModelViewer(
                  backgroundColor: Colors.transparent,
                  src: widget.modelPath,
                  alt: widget.modelTitle,
                  ar: false,
                  autoRotate: true,
                  cameraControls: true,
                  disableZoom: false,
                  autoPlay: true,
                  shadowIntensity: 0,
                ),
              ),
            ),

          // Model size slider (left side vertical)
          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.3,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF40FFA7),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 3,
                  overlayColor: const Color(0xFF40FFA7).withValues(alpha: 0.2),
                ),
                child: Slider(
                  min: 120,
                  max: 400,
                  value: _modelSize,
                  onChanged: (v) => setState(() => _modelSize = v),
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: () {
                    _audioPlayer.stop();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.view_in_ar, color: Color(0xFF40FFA7), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.modelTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Language
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLangDisplayKey,
                      isDense: true,
                      dropdownColor: Colors.grey[900],
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                      items: _languages.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (displayName) {
                        if (displayName != null) {
                          setState(() {
                            _selectedLangDisplayKey = displayName;
                            _selectedLanguage = _languages[displayName] ?? 'en-US';
                          });
                          _socket.emit('setLanguage', {
                            'language': _backendLangKey[displayName] ?? 'english',
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User question
                  if (_userQuestion.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _userQuestion,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // AI subtitle
                  if (_subtitle.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isSpeaking ? const Color(0xFF40FFA7) : Colors.white24,
                          width: _isSpeaking ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isProcessing ? Icons.hourglass_top : Icons.smart_toy,
                            color: const Color(0xFF40FFA7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _subtitle,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Processing spinner
                  if (_isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Color(0xFF40FFA7),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _subtitle == 'Looking at what you see...'
                                ? 'Analyzing...'
                                : 'Thinking...',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Mic row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.view_in_ar, color: Colors.white38, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Point & Ask',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Mic button
                      GestureDetector(
                        onTap: _isProcessing ? null : _listen,
                        child: Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.redAccent
                                : _isProcessing
                                    ? Colors.grey
                                    : const Color(0xFF40FFA7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : const Color(0xFF40FFA7))
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            size: 30,
                            color: _isListening ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isListening
                              ? 'Listening...'
                              : _isSpeaking
                                  ? 'Speaking...'
                                  : 'Tap mic',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _isListening ? Colors.redAccent : Colors.white38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
