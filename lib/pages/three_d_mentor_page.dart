import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert' as convert;
import 'dart:typed_data';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/student_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../widgets/feedback_dialog.dart';

class ThreeDMentorPage extends StatefulWidget {
  const ThreeDMentorPage({super.key});

  @override
  State<ThreeDMentorPage> createState() => _ThreeDMentorPageState();
}

class _ThreeDMentorPageState extends State<ThreeDMentorPage> {
  // Services
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late IO.Socket _socket;

  // State variables
  String _studentContext = '';

  bool _isSpeaking = false; // Audio playing (lip sync)
  bool _isListening = false; // STT listening
  bool _isProcessing = false; // Backend processing
  String _text = "Press the mic and ask me anything!";
  String _selectedLanguage = 'en-US'; // STT locale passed to speech_to_text plugin
  String _selectedLangDisplayKey = 'English'; // Display name (dropdown key)

  // Language Map — display name → STT locale code
  // Rajasthani reuses hi-IN for STT (no official BCP-47 code);
  // backend resolves 'rajasthani' → Rajasthani dialect prompt
  final Map<String, String> _languages = {
    'English':    'en-US',
    'Hindi':      'hi-IN',
    'Marathi':    'mr-IN',
    'Rajasthani': 'hi-IN',
  };

  // Display name → backend language key (used in socket 'language' field)
  // Must match LANGUAGE_CONFIG aliases in the backend controller
  static const Map<String, String> _backendLangKey = {
    'English':    'english',
    'Hindi':      'hindi',
    'Marathi':    'marathi',
    'Rajasthani': 'rajasthani',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAudioPlayer();
    _fetchStudentContext();
    _initSocket();
  }

  Future<void> _fetchStudentContext() async {
    try {
      final data = await StudentService.fetchFullStudentData();
      final profile = data['profile'] ?? {};
      final perf = data['performance'] ?? {};
      final currentPerf = perf['currentPerformance'] ?? {};
      final pi = perf['predictiveIntelligence'] ?? {};
      final stability = pi['academicStability'] ?? {};
      final trend = pi['trendAnalysis'] ?? {};
      final riskBd = pi['riskBreakdown'] ?? {};
      final alert = pi['smartAlert'] ?? {};
      final intervention = perf['intervention'] ?? {};

      final buf = StringBuffer();
      buf.writeln('[STUDENT PROFILE — use ONLY when asked]');
      buf.writeln('Name: ${profile['name'] ?? 'N/A'}');
      buf.writeln('Student ID: ${profile['studentId'] ?? 'N/A'}');
      buf.writeln('Email: ${profile['email'] ?? 'N/A'}');
      buf.writeln('Class: ${profile['classes'] ?? 'N/A'} | Course: ${profile['Course'] ?? 'N/A'}');
      buf.writeln('Institute: ${profile['instituteName'] ?? 'N/A'}');
      buf.writeln('Marks: ${profile['marks'] ?? 'N/A'} | Attendance: ${profile['attendance'] ?? 'N/A'}');

      buf.writeln('');
      buf.writeln('[PERFORMANCE — use ONLY when asked about scores/performance/risk]');
      buf.writeln('Overall Score: ${perf['score'] ?? 'N/A'}/100 | Risk: ${perf['riskLevel'] ?? 'N/A'} | Trend: ${perf['trend'] ?? 'N/A'}');
      buf.writeln('Attendance: ${currentPerf['attendance'] ?? 'N/A'}% | Internal Marks: ${currentPerf['internalMarks'] ?? 'N/A'}%');

      final strengths = perf['strengths'];
      if (strengths is List && strengths.isNotEmpty) {
        buf.writeln('Strengths: ${strengths.join(', ')}');
      }
      final concerns = perf['concerns'];
      if (concerns is List && concerns.isNotEmpty) {
        buf.writeln('Concerns: ${concerns.join(', ')}');
      }
      final recs = perf['recommendations'];
      if (recs is List && recs.isNotEmpty) {
        buf.writeln('Recommendations: ${recs.take(3).join('; ')}');
      }

      if (stability.isNotEmpty) {
        buf.writeln('Stability: ${stability['stabilityScore'] ?? 'N/A'}/100 | Failure Risk: ${stability['finalRisk'] ?? 'N/A'}%');
      }
      if (riskBd.isNotEmpty) {
        buf.writeln('Primary Weakness: ${riskBd['primaryWeakness'] ?? 'N/A'}');
      }
      if (alert.isNotEmpty) {
        buf.writeln('Alert: ${alert['level'] ?? 'N/A'} — ${alert['message'] ?? 'None'}');
      }
      if (intervention['required'] == true) {
        buf.writeln('Intervention: ${intervention['priority'] ?? 'N/A'} priority');
      }

      if (mounted) setState(() => _studentContext = buf.toString());
    } catch (e) {
      print("Error fetching student context: $e");
    }
  }

  void _initSocket() {
    _socket = IO.io('https://campuspp-f7qx.onrender.com', IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());

    _socket.onConnect((_) {
      print('Connected to Voice Chat Server');
    });
    
    _socket.on('aiResponse', (data) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _text = _cleanMarkdown(data['response'] ?? "I couldn't process that.");
        });
      }
    });

    _socket.on('ttsAudio', (data) async {
      print("Received audio from Voice Chat backend");
      try {
        final String base64Audio = data['audioBase64'];
        final Uint8List audioBytes = convert.base64Decode(base64Audio);
        if (mounted) {
           setState(() => _isProcessing = false);
        }
        await _playAudioBytes(audioBytes);
      } catch (e) {
        print("Error decoding or playing audio: $e");
      }
    });
    
    _socket.on('ttsError', (data) {
        if(mounted) {
           setState(() => _isProcessing = false);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error generating audio: ${data['message']}")),
           );
        }
    });

    _socket.onDisconnect((_) {
      print('Disconnected from Voice Chat Server');
    });
  }



  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isSpeaking = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
  }

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

  void _listen() async {
    if (!_isListening) {
      // 1. Ensure plugin is initialized before listening
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('STT Error: ${val.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Speech Error: ${val.errorMsg}")),
            );
          }
        },
      );

      if (available) {
        // Stop any current audio
        await _audioPlayer.stop();
        
        setState(() => _isListening = true);
        
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              setState(() {
                _text = val.recognizedWords;
              });
              _processResponse(val.recognizedWords);
            }
          },
          localeId: _selectedLanguage,
          listenMode: stt.ListenMode.dictation, // Better for general conversation
          cancelOnError: true,
          partialResults: false,
        );
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Speech recognition not available on this device.")),
           );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Socket.IO Backend Processing
  Future<void> _processResponse(String input) async {
    if (input.isEmpty) return;

    if (mounted) {
       setState(() {
          _isProcessing = true;
          _text = input; // Keep the recognized text on screen
       });
    }
    
    // Resolve backend language key — backend's resolveLanguageConfig() uses this
    final String backendLang =
        _backendLangKey[_selectedLangDisplayKey] ?? 'english';

    // Base system prompt — conversational, human, short
    final String systemPrompt =
        'You are Deepak, a friendly teacher talking to a student. '
        'Talk like a real human — warm, casual, natural. Not robotic. '
        'Keep it super short: 1-2 sentences MAX. No bullet points, no lists, no headings. '
        'Just talk naturally like you would face to face. '
        'Do NOT use markdown formatting (no **, no ##, no bullets). Plain text only. '
        'Never dump all info at once. Answer only what they asked, nothing extra. '
        'If they greet you, just greet back briefly. '
        'You know their details but only mention them if they ask or if it is directly relevant.'
        '${_studentContext.isNotEmpty ? '\n\n$_studentContext' : ''}';

    _socket.emit('textMessage', {
      'message': input,
      'systemPrompt': systemPrompt,
      'language': backendLang,        // primary key — backend resolves dialect
      'languageCode': _selectedLanguage, // STT locale (informational)
    });
  }

  Future<void> _playAudioBytes(List<int> bytes) async {
    final source = BytesSource(Uint8List.fromList(bytes));
    await _audioPlayer.play(source);
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      body: Stack(
        children: [
          // 1. Full Screen 3D Model
          Positioned.fill(
            child: ModelViewer(
              // Using user provided model (renamed)
              src: 'assets/models/64f1a714fe61576b46f27ca2.glb',
              alt: '3D Mentor',
              ar: true,
              autoRotate: false, 
              cameraControls: true,
              backgroundColor: Colors.transparent,
              disableZoom: false,
              // Prevention of upside down rotation
              // theta (horizontal), phi (vertical), radius (zoom)
              minCameraOrbit: 'auto 0deg auto', // Prevents looking from above
              maxCameraOrbit: 'auto 90deg auto', // Prevents looking from below ground
              // Animate 'Talk' when speaking (audio playing) OR processing (thinking)
              // We'll leave the animationName for now (it may lack these animations unless embedded, but model will load)
              animationName: _isSpeaking ? 'Talking_0' : 'Idle',
              autoPlay: true,
            ),
          ),

          // 2. Back Button (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                 _audioPlayer.stop();
                 // Randomly show user feedback dialog when leaving mentor
                 await maybeShowFeedbackDialog(
                   context,
                   feature: FeedbackFeature.threeDMentor,
                   featureDisplayName: '3D Mentor',
                 );
                 if (context.mounted) Navigator.pop(context);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Controls (No background)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtitle / Text Bubble
                if (_text.isNotEmpty && !_isProcessing)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _text,
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Bottom Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Language Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            "LANGUAGE",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: Offset(1, 1))],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLangDisplayKey,
                              isDense: true,
                              dropdownColor: const Color(0xFF2D2D2D),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                              items: _languages.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
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

                    // Mic Button Center
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _listen,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: _isListening ? 1.15 : 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  height: 72,
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: _isListening ? const Color(0xFFFF4B4B) : const Color(0xFF40FFA7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isListening ? const Color(0xFFFF4B4B) : const Color(0xFF40FFA7)).withOpacity(0.5),
                                        blurRadius: _isListening ? 25 : 15,
                                        spreadRadius: _isListening ? 5 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                                    size: 34,
                                    color: _isListening ? Colors.white : Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isProcessing ? "PROCESSING..." : (_isListening ? "LISTENING..." : "TAP TO SPEAK"),
                          style: GoogleFonts.poppins(
                            color: _isProcessing ? Colors.blueAccent[100] : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: Offset(1, 1))],
                          ),
                        ),
                      ],
                    ),

                    // Empty spacer for layout balance
                    const SizedBox(width: 80), 
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
