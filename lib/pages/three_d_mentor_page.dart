import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert' as convert;
import 'dart:typed_data';
import '../services/ai_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/student_service.dart';

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
  String? _studentContext; // Store fetched student data
  
  bool _isSpeaking = false; // Audio playing (lip sync)
  bool _isListening = false; // STT listening
  bool _isProcessing = false; // Backend processing
  String _text = "Press the mic and ask me anything!";
  String _selectedLanguage = 'en-US';
  
  // Language Map
  final Map<String, String> _languages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Marathi': 'mr-IN',
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAudioPlayer();
    _fetchStudentContext();
    _initSocket();
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
          // Only update the text if it's the AI response
          _text = data['response'] ?? "I couldn't process that.";
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

  Future<void> _fetchStudentContext() async {
    try {
      final data = await StudentService.fetchFullStudentData();
      // Format data for AI
      final profile = data['profile'] ?? {};
      final perf = data['performance'] ?? {};
      final currentPerf = perf['currentPerformance'] ?? {};
      
      String context = """
      Name: ${profile['name']}
      Course: ${profile['Course']}
      Attendance: ${currentPerf['attendance']}%
      Marks: ${currentPerf['currentPerformance']?['internalMarks'] ?? 'N/A'}
      Risk Level: ${currentPerf['riskLevel']}
      Strengths: ${currentPerf['strengths']?.join(', ') ?? 'N/A'}
      Concerns: ${currentPerf['concerns']?.join(', ') ?? 'N/A'}
      """;
      
      setState(() => _studentContext = context);
      print("Student Context Loaded: $_studentContext");
    } catch (e) {
      print("Error fetching student context: $e");
    }
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
    
    String languageName = (_selectedLanguage == 'hi-IN') ? "Hindi" : (_selectedLanguage == 'mr-IN' ? "Marathi" : "English");
    
    String systemPrompt = """You are a helpful and knowledgeable teacher named Deepak. You are mentoring a student.
    
    CRITICAL INSTRUCTIONS:
    1. ALWAYS reply in $languageName. Use perfect grammar and natural phrasing.
    2. If the user asks a general knowledge or academic question (e.g., about math, science, history), answer it accurately and concisely.
    3. Use the provided STUDENT DATA ONLY if the user asks something personal about themselves (like their name, marks, or performance).
    4. Keep answers under 3 sentences.
    """;
    
    if (_studentContext != null) {
      systemPrompt += "\n\nSTUDENT DATA (Use only if relevant to the question):\n$_studentContext";
    }

    _socket.emit('textMessage', {
       'message': input,
       'systemPrompt': systemPrompt,
       'languageCode': _selectedLanguage
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
              src: 'assets/models/avatar_animated.glb',
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
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                 _audioPlayer.stop();
                 Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // 3. Transparent Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6), // Darker at bottom
                    Colors.transparent, // Fade to transparent
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Language Selector Bubble
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            items: _languages.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.value,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLanguage = val);
                              }
                            },
                          ),
                        ),
                      ),
                      
                      // Status Text
                      if (_isProcessing)
                         const Text(
                           "Thinking...",
                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                         ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recognized Text Display (Floating above mic)
                  if (_text.isNotEmpty && !_isProcessing)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _text,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Mic Button
                  GestureDetector(
                    onTap: _listen,
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : const Color(0xFF40FFA7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : const Color(0xFF40FFA7)).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 32,
                        color: _isListening ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening ? "Listening..." : "Tap to Speak",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
