import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert' as convert;
import 'dart:typed_data';
import '../services/ai_service.dart';
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

  // ... existing methods

  // Real Backend Processing (Mistral + ElevenLabs)


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
            setState(() {
              _text = val.recognizedWords;
            });
            // 2. Only process if it's the final result or confidence is high enough
            if (val.finalResult) {
              _processResponse(val.recognizedWords);
            }
          },
          localeId: _selectedLanguage,
          listenMode: stt.ListenMode.dictation, // Better for general conversation
          cancelOnError: true,
          partialResults: true,
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

  // Real Backend Processing (Mistral + ElevenLabs)
  Future<void> _processResponse(String input) async {
    if (input.isEmpty) return;

    setState(() => _isProcessing = true);
    
    // 1. Get AI Text Response
    String? aiResponse = await AIService.getAIResponse(input, _selectedLanguage, studentContext: _studentContext);
    
    if (aiResponse == null) {
      if (mounted) setState(() => _isProcessing = false);
      // Fallback or error message
      _text = "Sorry, I couldn't connect to my brain.";
      return; 
    }

    // 2. Convert Text to Speech (Audio)
    try {
      List<int>? audioBytes = await AIService.convertTextToSpeech(aiResponse);

      if (audioBytes == null) {
         if (mounted) {
           setState(() => _isProcessing = false);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Error generating audio (API might be busy).")),
           );
         }
         _text = aiResponse; 
         return;
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _text = aiResponse; 
        });
      }

      // 3. Play Audio
      await _playAudioBytes(audioBytes);
    } catch (e) {
      print("Audio Error: $e");
      if (mounted) {
         setState(() => _isProcessing = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Audio playback failed: $e")),
         );
      }
    }
  }

  Future<void> _playAudioBytes(List<int> bytes) async {
    // Correct way to play bytes in AudioPlayers
    final source = BytesSource(Uint8List.fromList(bytes));
    await _audioPlayer.play(source);
  }

  @override
  void dispose() {
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
              src: 'assets/models/speaking_man.glb',
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
              animationName: _isSpeaking ? 'Talk' : 'Idle',
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
