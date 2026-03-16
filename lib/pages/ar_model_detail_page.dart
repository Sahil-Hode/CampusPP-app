import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/vision_service.dart';
import '../services/student_service.dart';

class ARModelDetailPage extends StatefulWidget {
  final String modelPath;
  final String title;

  const ARModelDetailPage({
    super.key,
    required this.modelPath,
    required this.title,
  });

  @override
  State<ARModelDetailPage> createState() => _ARModelDetailPageState();
}

class _ARModelDetailPageState extends State<ARModelDetailPage> {
  // Model state
  bool _isModelLoaded = false;
  bool _hasError = false;
  String? _modelSrc;
  String _errorMessage = '';

  // Screenshot key for capturing the model viewer area
  final GlobalKey _modelViewerKey = GlobalKey();

  // Q&A state
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late IO.Socket _socket;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _subtitle = '';
  String _userQuestion = '';
  bool _showControls = true; // toggle to reveal AR button underneath
  String _studentContext = '';
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
    _prepareModel();
    _initSpeech();
    _initAudioPlayer();
    _initSocket();
    _fetchStudentContext();
  }

  // ── Fetch student context once (for personalized answers) ──

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
      debugPrint('[AR Q&A] Student context fetch error: $e');
    }
  }

  // ── Model loading (same as before) ──

  bool get _isRemoteUrl =>
      widget.modelPath.startsWith('http://') ||
      widget.modelPath.startsWith('https://');

  Future<void> _prepareModel() async {
    debugPrint('[AR Detail] modelPath = ${widget.modelPath}');

    if (widget.modelPath.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'No model URL available. The model may still be processing.';
        });
      }
      return;
    }

    if (_isRemoteUrl) {
      try {
        debugPrint('[AR Detail] Downloading model from remote URL...');
        final response = await http.get(Uri.parse(widget.modelPath));
        debugPrint('[AR Detail] Download status: ${response.statusCode}, '
            'bytes: ${response.bodyBytes.length}');

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final dir = await getTemporaryDirectory();
          final fileName =
              'ar_model_${DateTime.now().millisecondsSinceEpoch}.glb';
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('[AR Detail] Saved to: ${file.path}');

          if (mounted) {
            setState(() {
              _modelSrc = 'file://${file.path}';
              _isModelLoaded = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage =
                  'Failed to download model (HTTP ${response.statusCode})';
            });
          }
        }
      } catch (e) {
        debugPrint('[AR Detail] Download error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Error loading model: ${e.toString().replaceAll("Exception: ", "")}';
          });
        }
      }
    } else {
      setState(() {
        _modelSrc = widget.modelPath;
        _isModelLoaded = true;
      });
    }
  }

  // ── Socket.IO (same pattern as 3D Mentor) ──

  void _initSocket() {
    _socket = IO.io(
      'https://campuspp-f7qx.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      debugPrint('[AR Q&A] Connected to Voice Chat Server');
    });

    _socket.on('aiResponse', (data) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _subtitle = _cleanMarkdown(data['response'] ?? "I couldn't process that.");
        });
      }
    });

    _socket.on('ttsAudio', (data) async {
      debugPrint('[AR Q&A] Received TTS audio');
      try {
        final String base64Audio = data['audioBase64'];
        final Uint8List audioBytes = base64Decode(base64Audio);
        if (mounted) setState(() => _isProcessing = false);
        await _playAudioBytes(audioBytes);
      } catch (e) {
        debugPrint('[AR Q&A] Audio play error: $e');
      }
    });

    _socket.on('ttsError', (data) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });

    _socket.onDisconnect((_) {
      debugPrint('[AR Q&A] Disconnected from Voice Chat Server');
    });
  }

  // ── Audio Player ──

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isSpeaking = state == PlayerState.playing);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _playAudioBytes(List<int> bytes) async {
    final source = BytesSource(Uint8List.fromList(bytes));
    await _audioPlayer.play(source);
  }

  // ── Speech-to-Text ──

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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available.')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // ── Main Q&A Pipeline ──

  Future<void> _onQuestionReady(String question) async {
    if (question.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _subtitle = 'Analyzing model...';
      });
    }

    // Step 1: Capture screenshot & analyze with Google Vision
    String visionDesc = '';
    try {
      final screenshotBytes = await _captureModelScreenshot();
      if (screenshotBytes != null) {
        final base64Img = base64Encode(screenshotBytes);
        visionDesc = await VisionService.analyzeImage(base64Img);
        debugPrint('[AR Q&A] Vision: $visionDesc');
      }
    } catch (e) {
      debugPrint('[AR Q&A] Vision analysis failed: $e');
    }

    if (mounted) {
      setState(() => _subtitle = 'Thinking...');
    }

    // Step 2: Build system prompt — conversational, human, short
    final String systemPrompt =
        'You are a friendly teacher having a casual conversation with a student. '
        'They are looking at a 3D model of "${widget.title}" in AR. '
        'Talk like a real human — warm, natural, no robotic tone. '
        'Keep it super short: 1-2 sentences MAX. No bullet points, no lists, no headings. '
        'Just talk naturally like you would in person. '
        'Do NOT use markdown formatting (no **, no ##, no bullets). Plain text only. '
        'Never dump all info at once. Answer only what they asked, nothing extra. '
        'If they greet you, just greet back briefly.'
        '${visionDesc.isNotEmpty ? '\n\n[What you can see on their screen: $visionDesc]' : ''}'
        '${_studentContext.isNotEmpty ? '\n\n$_studentContext' : ''}';

    final String backendLang =
        _backendLangKey[_selectedLangDisplayKey] ?? 'english';

    // Step 3: Send to backend via socket (Mistral AI + TTS)
    _socket.emit('textMessage', {
      'message': question,
      'systemPrompt': systemPrompt,
      'language': backendLang,
      'languageCode': _selectedLanguage,
    });
  }

  // ── Screenshot capture ──

  Future<Uint8List?> _captureModelScreenshot() async {
    try {
      final boundary = _modelViewerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[AR Q&A] Screenshot capture failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Strip markdown formatting from AI response ──

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')   // **bold**
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')        // *italic*
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')        // __bold__
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')          // _italic_
        .replaceAll(RegExp(r'~~(.+?)~~'), r'$1')        // ~~strike~~
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')          // `code`
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // # headings
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '') // bullet lists
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '') // numbered lists
        .replaceAll('\\n', '\n')                         // literal \n
        .replaceAll('\\\\', '')                          // stray backslashes
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')           // collapse blank lines
        .trim();
  }

  // ── Build UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen model viewer
            Positioned.fill(
              child: RepaintBoundary(
                key: _modelViewerKey,
                child: _hasError
                    ? _buildErrorWidget()
                    : _isModelLoaded && _modelSrc != null
                        ? ModelViewer(
                            backgroundColor: const Color(0xFFF0FFF0),
                            src: _modelSrc!,
                            alt: 'A 3D model of ${widget.title}',
                            ar: true,
                            arModes: const [
                              'scene-viewer',
                              'webxr',
                              'quick-look'
                            ],
                            autoRotate: true,
                            cameraControls: true,
                            disableZoom: false,
                            autoPlay: true,
                            shadowIntensity: 1.0,
                            shadowSoftness: 1.0,
                            exposure: 1.0,
                            environmentImage: 'neutral',
                            loading: Loading.eager,
                            reveal: Reveal.auto,
                          )
                        : _buildLoadingWidget(),
              ),
            ),

            // Top bar: back button + title + language selector
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      _audioPlayer.stop();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language selector
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLangDisplayKey,
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black, size: 18),
                        items: _languages.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          );
                        }).toList(),
                        onChanged: (displayName) {
                          if (displayName != null) {
                            setState(() {
                              _selectedLangDisplayKey = displayName;
                              _selectedLanguage =
                                  _languages[displayName] ?? 'en-US';
                            });
                            _socket.emit('setLanguage', {
                              'language':
                                  _backendLangKey[displayName] ?? 'english',
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Toggle controls button (top-right area, below top bar)
            Positioned(
              top: 60,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _showControls ? Icons.visibility_off : Icons.mic,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Bottom controls overlay — only shown when _showControls is true
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User question display
                        if (_userQuestion.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 14),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
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

                        // Subtitle / AI response display
                        if (_subtitle.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isSpeaking
                                    ? const Color(0xFF40FFA7)
                                    : Colors.white30,
                                width: _isSpeaking ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _isProcessing
                                      ? Icons.hourglass_top
                                      : Icons.smart_toy,
                                  color: const Color(0xFF40FFA7),
                                  size: 18,
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

                        // Processing indicator
                        if (_isProcessing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF40FFA7),
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _subtitle == 'Analyzing model...'
                                      ? 'Analyzing model...'
                                      : 'Thinking...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Mic button + hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // AR hint
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.view_in_ar,
                                      color: Colors.white54, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ask about this model',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white54,
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
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? Colors.redAccent
                                      : _isProcessing
                                          ? Colors.grey
                                          : const Color(0xFF40FFA7),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening
                                              ? Colors.red
                                              : const Color(0xFF40FFA7))
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  size: 28,
                                  color: _isListening
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Status text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isListening
                                    ? 'Listening...'
                                    : _isSpeaking
                                        ? 'Speaking...'
                                        : 'Tap mic',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: _isListening
                                      ? Colors.redAccent
                                      : Colors.white54,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isModelLoaded = false;
                });
                _prepareModel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Loading 3D Model...',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
