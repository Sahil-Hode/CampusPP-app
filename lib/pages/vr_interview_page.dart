import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_unity_widget_2/flutter_unity_widget_2.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/student_service.dart';
import '../services/vr_interview_service.dart';
import '../models/student_profile_model.dart';
import '../models/student_model.dart';
import '../models/performance_model.dart';

class VRInterviewPage extends StatefulWidget {
  const VRInterviewPage({super.key});

  @override
  State<VRInterviewPage> createState() => _VRInterviewPageState();
}

class _VRInterviewPageState extends State<VRInterviewPage> {
  UnityWidgetController? _unityWidgetController;
  late stt.SpeechToText _speech;
  late VRMockInterviewService _interviewService;

  bool _isListening = false;
  bool _isAIProcessing = false;
  String _currentDialogue = "Initializing VR Interview...";
  
  StudentProfile? _profile;
  OverviewData? _overview;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _interviewService = VRMockInterviewService();
    _initInterviewFlow();
  }

  Future<void> _initInterviewFlow() async {
    try {
      // 1. Fetch Profile and Resume/Overview Context
      _profile = await StudentService.getFullStudentProfile();
      _overview = await StudentService.getOverview();
      
      final resumeContext = "Attendance: ${_overview?.attendance}%, Internals: ${_overview?.internalMarks}%, Risk Level: ${_overview?.riskLevel}.";
      _interviewService.addSystemProfile(_profile?.name ?? "Student", resumeContext);

      // 2. Initializing Google STT (Android native speech recognition)
      await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );

      // 3. Trigger initial question
      setState(() {
        _currentDialogue = "Connecting to Mistral AI...";
        _isAIProcessing = true;
      });

      _interviewService.addUserMessage("Start the mock interview now. Introduce yourself briefly and ask the first question.");
      final aiResponse = await _interviewService.getAiResponse();
      
      setState(() {
        _currentDialogue = aiResponse;
        _isAIProcessing = false;
      });

      // 4. Play Sarvam TTS
      await _interviewService.speakSarvam(aiResponse);

    } catch (e) {
      if (mounted) {
        setState(() => _currentDialogue = "Error initializing AI: $e");
      }
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      if (await _speech.hasPermission) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _currentDialogue = result.recognizedWords;
            });
            if (result.finalResult) {
              _handleUserResponse(result.recognizedWords);
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for Google STT!')),
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _handleUserResponse(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _isAIProcessing = true;
      _currentDialogue = "Mistral AI thinking...";
    });

    _interviewService.addUserMessage(text);
    final aiResponse = await _interviewService.getAiResponse();

    setState(() {
      _currentDialogue = aiResponse;
      _isAIProcessing = false;
    });

    await _interviewService.speakSarvam(aiResponse);
  }

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    _speech.stop();
    _interviewService.dispose();
    super.dispose();
  }

  void _onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void onUnityMessage(message) {
    print('Received message from unity: ${message.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnityMessage: onUnityMessage,
            useAndroidViewSurface: false,
            borderRadius: const BorderRadius.all(Radius.circular(0)),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Dialogue Overlay Bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(color: _isListening ? Colors.green.withOpacity(0.3) : Colors.black, blurRadius: 10)
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    _isAIProcessing ? "AI Interviewer (Typing...)" : (_isListening ? "Listening (Google STT)..." : "AI Interviewer"),
                    style: GoogleFonts.jetBrainsMono(
                      color: _isListening ? Colors.greenAccent : Colors.cyanAccent, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentDialogue,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isAIProcessing ? null : _toggleListening,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.black),
                    label: Text(_isListening ? "STOP LISTENING" : "TAP TO SPEAK"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.greenAccent : Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(200, 45),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

