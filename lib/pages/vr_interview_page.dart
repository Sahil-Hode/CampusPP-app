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
      });

      // Fetch and play Sarvam TTS immediately showing text
      await _interviewService.speakSarvam(aiResponse);

      setState(() {
        _isAIProcessing = false;
      });

      // Auto-start listening after the AI finishes speaking
      _startListening();

    } catch (e) {
      if (mounted) {
        setState(() => _currentDialogue = "Error initializing AI: $e");
      }
    }
  }

  void _startListening() async {
    if (_isAIProcessing) return;

    if (await _speech.hasPermission) {
      setState(() {
        _isListening = true;
        _currentDialogue = "Listening...";
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _currentDialogue = result.recognizedWords;
          });
          if (result.finalResult) {
            _speech.stop();
            setState(() => _isListening = false);
            if (!_isAIProcessing) {
              _handleUserResponse(result.recognizedWords);
            }
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for Google STT!')),
        );
      }
    }
  }

  Future<void> _handleUserResponse(String text) async {
    if (_isAIProcessing) return;

    if (text.isEmpty) {
        _startListening(); // Re-trigger if empty
        return;
    }
    
    // Explicitly shut mic
    _speech.stop();
    setState(() => _isListening = false);

    setState(() {
      _isAIProcessing = true;
      _currentDialogue = "Mistral AI thinking...";
    });

    _interviewService.addUserMessage(text);
    final aiResponse = await _interviewService.getAiResponse();

    setState(() {
      _currentDialogue = aiResponse;
    });

    // Fetch and play audio completely
    await _interviewService.speakSarvam(aiResponse);

    setState(() {
      _isAIProcessing = false;
    });

    // Loop continuously back to listening
    _startListening();
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
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              alignment: Alignment.center,
              child: Text(
                _currentDialogue,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: _isListening ? Colors.greenAccent.withOpacity(0.8) : Colors.cyanAccent.withOpacity(0.8),
                      blurRadius: 10,
                    )
                  ]
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

