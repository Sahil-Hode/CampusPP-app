import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/mock_interview_model.dart';
import '../services/mock_interview_service.dart';
import '../services/mock_interview_socket_service.dart';
import '../services/student_service.dart';
import '../models/student_profile_model.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'resume_upload_page.dart';

class MockInterviewPage extends StatefulWidget {
  const MockInterviewPage({super.key});

  @override
  State<MockInterviewPage> createState() => _MockInterviewPageState();
}

class _MockInterviewPageState extends State<MockInterviewPage> {
  // Services
  final MockInterviewSocketService _socketService =
      MockInterviewSocketService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  CameraController? _cameraController;

  // State
  bool _isInterviewStarted = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isCameraOff = true; // Default to off
  bool _cameraInitialized = false;
  bool _showChat = false;
  String? _sessionId;
  StudentProfile? _profile;
  String? _resumePath;
  String? _resumeFileName;
  bool _isResumeUploading = false;
  bool _hasResume = false;
  String _resumeSource = 'profile'; // 'profile' or 'upload'
  String _currentText = "Welcome to your AI Mock Interview.";
  String _userTranscription = "";
  Interviewer? _currentInterviewer;
  InterviewFeedback? _feedback;

  StreamSubscription? _statusSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _transcriptionSub;
  StreamSubscription? _feedbackSub;
  StreamSubscription? _recordSub;
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _setupSocketListeners();
    _setupAudioPlayer();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera Error: $e');
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await StudentService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _hasResume = (profile.resumeText ?? '').isNotEmpty;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == PlayerState.playing);
    });
  }

  void _setupSocketListeners() {
    _statusSub = _socketService.status.listen((status) {
      if (mounted) {
        setState(() {
          _isProcessing = status == 'processing';
          if (status == 'ended') _isInterviewStarted = false;
          if (status == 'streaming') _userTranscription = "Speak now...";
          if (status == 'error') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Interviewer connection issue. Retrying...'),
              ),
            );
          }
        });
      }
    });

    _msgSub = _socketService.messages.listen((data) {
      if (mounted) {
        setState(() {
          _currentText = data['message'] ?? "";
          if (data['interviewer'] != null) {
            _currentInterviewer = Interviewer.fromJson(data['interviewer']);
          }
        });
      }
    });

    _audioSub = _socketService.audio.listen((data) async {
      if (data['audioBase64'] != null) {
        try {
          final base64String = data['audioBase64'] as String;
          print('Playing AI Voice (Base64 length: ${base64String.length})');
          final bytes = base64Decode(base64String);

          // For Web, ensure we use the correct mime type if possible
          await _audioPlayer.play(
            BytesSource(Uint8List.fromList(bytes), mimeType: 'audio/mp3'),
          );
        } catch (e) {
          print('Error playing AI Audio: $e');
        }
      }
    });

    _transcriptionSub = _socketService.transcription.listen((data) {
      if (mounted) {
        setState(() => _userTranscription = data['text'] ?? "");
      }
    });

    _feedbackSub = _socketService.feedback.listen((feedback) {
      if (mounted) setState(() => _feedback = feedback);
    });
  }

  Future<void> _startInterview() async {
    setState(() => _isLoading = true);
    try {
      if (_resumeSource == 'profile' && !_hasResume) {
        throw Exception(
          'Please upload your resume on your profile first before starting a mock interview.',
        );
      }
      if (_resumeSource == 'upload' && _resumePath == null) {
        throw Exception('Please select a resume to upload.');
      }

      final session = await MockInterviewService.startInterview(
        resumeSource: _resumeSource,
        resumePath: _resumeSource == 'upload' ? _resumePath : null,
      );
      _sessionId = session.sessionId;

      // 1. Set initial state from POST response
      if (mounted) {
        setState(() {
          _isInterviewStarted = true;
          _isLoading = false;
          _currentInterviewer = session.interviewer;
          _currentText = session.openingMessage;
        });
      }

      // 2. Connect to Socket
      await _socketService.connect(_sessionId!);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errorStr = e.toString();
        print('Interview Start Error: $errorStr');
        if (errorStr.contains('upload your resume')) {
          _showResumeUploadDialog();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $errorStr')));
        }
      }
    }
  }

  Future<void> _pickTempResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _resumePath = result.files.single.path;
          _resumeFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _showResumeUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Resume Required',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(
          'Our AI panel needs your resume to prepare personalized interview questions based on your experience.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResumeUploadPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40FFA7),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: Text(
              'GO TO UPLOAD',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _resumePath = result.files.single.path;
          _resumeFileName = result.files.single.name;
          _isResumeUploading = true;
        });

        // Use the service we added earlier
        await StudentService.uploadResume(_resumePath!);

        if (mounted) {
          setState(() {
            _isResumeUploading = false;
            _hasResume = true;
          });
          // Fetch profile to get the name from the newly uploaded resume
          _fetchProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResumeUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleListening() async {
    print('DEBUG: Toggling Microphone. Current state: $_isListening');
    if (_isListening) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    print('DEBUG: Requesting mic permission...');
    if (await _recorder.hasPermission()) {
      print('DEBUG: Mic permission granted. Starting stream...');
      // Create a stream of audio data
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _socketService.startVoiceStream();

      _recordSub = stream.listen((data) {
        _socketService.sendAudioChunk(data);
      });

      setState(() {
        _isListening = true;
        _userTranscription = "Listening...";
      });
      print('DEBUG: Microphone is now LIVE');
    } else {
      print('DEBUG: Mic permission DENIED');
    }
  }

  Future<void> _stopRecording() async {
    print('DEBUG: Stopping Microphone...');
    await _recorder.stop();
    await _recordSub?.cancel();
    _socketService.stopVoiceStream();
    setState(() => _isListening = false);
    print('DEBUG: Microphone is now OFF');
  }

  void _toggleCamera() async {
    print(
      'DEBUG: Toggling Camera. Initialized: $_cameraInitialized, Current off: $_isCameraOff',
    );
    if (!_cameraInitialized) {
      print('DEBUG: Camera not initialized. Starting init...');
      await _initCamera();
    }
    setState(() => _isCameraOff = !_isCameraOff);
    print('DEBUG: New Camera state (off): $_isCameraOff');
  }

  Future<void> _endInterview() async {
    print('DEBUG: _endInterview called');
    if (_sessionId == null) return;

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Text(
          'End Interview?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to end the session? Your feedback will be generated now.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Continue',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: Text(
              'End Now',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    print('DEBUG: Proceeding to end interview for session: $_sessionId');

    try {
      // 1. Tell socket we are ending
      _socketService.endInterview();

      // 2. Clear all local resources
      await _recorder.stop();
      await _audioPlayer.stop();
      await _cameraController?.dispose();
      _cameraInitialized = false;

      // 3. Call REST API to get final feedback as fallback (most reliable)
      final feedback = await MockInterviewService.endInterview(_sessionId!);

      if (mounted) {
        setState(() {
          _feedback = feedback;
          _isLoading = false;
          _isInterviewStarted = false;
        });
        print(
          'DEBUG: Interview Ended successfully. Feedback received: ${_feedback?.feedback['score']}',
        );
      }
    } catch (e) {
      print('DEBUG: End Interview Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ending interview: $e')));
      }
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _msgSub?.cancel();
    _audioSub?.cancel();
    _transcriptionSub?.cancel();
    _feedbackSub?.cancel();
    _recordSub?.cancel();
    _socketService.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _cameraController?.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_feedback != null) return _buildFeedbackView();
    if (!_isInterviewStarted && !_isLoading) return _buildLandingView();

    final participants = _buildParticipants();
    final activeId = _activeSpeakerId(participants);
    final activeTile = participants.firstWhere(
      (p) => p.id == activeId,
      orElse: () => participants.first,
    );
    final passiveTiles = participants
        .where((p) => p.id != activeTile.id)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFD9), // Matching landing page vibe
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOCK INTERVIEW ROOM',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Text(
              'Live simulation with AI panel',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _pageScrollController,
              child: Column(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        // 1. Main speaker + 3 passive tiles
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildMeetingTile(
                                      tile: activeTile,
                                      isActive: true,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < passiveTiles.length;
                                          i++
                                        ) ...[
                                          Expanded(
                                            child: _buildMeetingTile(
                                              tile: passiveTiles[i],
                                              isActive: false,
                                            ),
                                          ),
                                          if (i != passiveTiles.length - 1)
                                            const SizedBox(width: 10),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 2. Control Dock (Floating Neobrutalist)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 360;
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildControlCircle(
                                        icon: _isListening
                                            ? Icons.mic
                                            : Icons.mic_off,
                                        color: _isListening
                                            ? const Color(0xFF81C784)
                                            : const Color(0xFFFF8B94),
                                        onTap: _toggleListening,
                                        size: isNarrow ? 40 : 46,
                                        iconSize: isNarrow ? 18 : 22,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildControlCircle(
                                        icon: _isCameraOff
                                            ? Icons.videocam_off
                                            : Icons.videocam,
                                        color: _isCameraOff
                                            ? const Color(0xFFFF8B94)
                                            : const Color(0xFFBBDEFB),
                                        onTap: _toggleCamera,
                                        size: isNarrow ? 40 : 46,
                                        iconSize: isNarrow ? 18 : 22,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildControlCircle(
                                        icon: _showChat
                                            ? Icons.close
                                            : Icons.chat_bubble_outline,
                                        color: _showChat
                                            ? Colors.red
                                            : Colors.grey[200]!,
                                        iconColor: _showChat
                                            ? Colors.white
                                            : Colors.black,
                                        onTap: _toggleChatPanel,
                                        size: isNarrow ? 40 : 46,
                                        iconSize: isNarrow ? 18 : 22,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildControlCircle(
                                        icon: Icons.auto_fix_high,
                                        color: Colors.grey[200]!,
                                        onTap: () {},
                                        size: isNarrow ? 40 : 46,
                                        iconSize: isNarrow ? 18 : 22,
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: isNarrow ? 40 : 46,
                                        child: ElevatedButton(
                                          onPressed: _endInterview,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            minimumSize: const Size(56, 40),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: const BorderSide(
                                                color: Colors.black,
                                                width: 2.5,
                                              ),
                                            ),
                                            elevation: 4,
                                            shadowColor: Colors.black,
                                          ),
                                          child: Text(
                                            'END',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w900,
                                              fontSize: isNarrow ? 12 : 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showChat) _buildTranscriptPanel(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _activeSpeakerId(List<_ParticipantTile> tiles) {
    if (_isListening) return 'user';
    if (_isSpeaking && _currentInterviewer != null) {
      final name = _currentInterviewer!.name.toUpperCase();
      if (name.contains('ARJUN')) return 'arjun';
      if (name.contains('PRIYA')) return 'priya';
      if (name.contains('VIKRAM')) return 'vikram';
    }
    return 'user';
  }

  List<_ParticipantTile> _buildParticipants() {
    return [
      _ParticipantTile(
        id: 'user',
        label: 'LIVEFEED_01',
        subLabel: _profile?.name.toUpperCase() ?? 'IDENTIFYING...',
        color: const Color(0xFFD1C4E9),
        content: _buildUserCamera(),
      ),
      _ParticipantTile(
        id: 'arjun',
        label: 'AI_SYSTEM_01',
        subLabel: 'MR. ARJUN',
        color: const Color(0xFFB3E5FC),
        content: _buildAiAvatar('🤖'),
      ),
      _ParticipantTile(
        id: 'priya',
        label: 'AI_SYSTEM_02',
        subLabel: 'MISS PRIYA',
        color: const Color(0xFFE1BEE7),
        content: _buildAiAvatar('👩‍💻'),
      ),
      _ParticipantTile(
        id: 'vikram',
        label: 'AI_SYSTEM_03',
        subLabel: 'MR. VIKRAM',
        color: const Color(0xFFFFF9C4),
        content: _buildAiAvatar('👨‍💼'),
      ),
    ];
  }

  Widget _buildUserCamera() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCameraOff) {
      return const Icon(Icons.videocam_off, size: 40, color: Colors.black45);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 0,
          height: _cameraController!.value.previewSize?.width ?? 0,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildAiAvatar(String emoji) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }

  Widget _buildMeetingTile({
    required _ParticipantTile tile,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tile.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? (tile.label.startsWith('LIVEFEED')
                    ? const Color(0xFF40FFA7)
                    : const Color(0xFF40DBFF))
              : Colors.black,
          width: isActive ? 5 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: isActive ? const Offset(0, 0) : const Offset(6, 6),
            blurRadius: isActive ? 15 : 0,
          ),
          if (isActive)
            BoxShadow(
              color:
                  (tile.label.startsWith('LIVEFEED')
                          ? const Color(0xFF40FFA7)
                          : const Color(0xFF40DBFF))
                      .withOpacity(0.5),
              blurRadius: 20,
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Center(child: tile.content),
            ),
          ),

          Positioned(
            top: 0,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                tile.label,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),

          if (tile.subLabel != null)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: Text(
                  tile.subLabel!,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 8,
            right: 8,
            child: Opacity(
              opacity: 0.3,
              child: Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isActive)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SPEAKING',
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    double size = 46,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  void _toggleChatPanel() {
    setState(() => _showChat = !_showChat);

    if (_showChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageScrollController.hasClients) {
          _pageScrollController.animateTo(
            _pageScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildTranscriptPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE TRANSCRIPT',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _buildTranscriptRow(
              label: _currentInterviewer?.name.toUpperCase() ?? 'INTERVIEWER',
              text: _currentText.isEmpty ? '...' : _currentText,
              isUser: false,
            ),
            const SizedBox(height: 6),
            _buildTranscriptRow(
              label: _profile?.name.toUpperCase() ?? 'YOU',
              text: _userTranscription.isEmpty ? '...' : _userTranscription,
              isUser: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptRow({
    required String label,
    required String text,
    required bool isUser,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFD9),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(10, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 36,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'VOICE INTERVIEW',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a resume source and start when you are ready.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 📄 Resume Source Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume Source',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildResumeOption(
                        title: 'Profile Resume',
                        subtitle: _hasResume
                            ? 'Saved in profile'
                            : 'Not uploaded yet',
                        selected: _resumeSource == 'profile',
                        statusColor: _hasResume ? Colors.green : Colors.orange,
                        onTap: () => setState(() => _resumeSource = 'profile'),
                      ),
                      const SizedBox(height: 6),
                      _buildResumeOption(
                        title: 'Upload New',
                        subtitle:
                            _resumeFileName ?? 'PDF or DOCX (this session)',
                        selected: _resumeSource == 'upload',
                        statusColor: const Color(0xFF64B5F6),
                        onTap: () => setState(() => _resumeSource = 'upload'),
                      ),
                      const SizedBox(height: 10),
                      if (_resumeSource == 'profile') ...[
                        if (_isResumeUploading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          )
                        else if (!_hasResume)
                          ElevatedButton.icon(
                            onPressed: _pickAndUploadResume,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('UPLOAD TO PROFILE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 44),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.description, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Resume saved in profile',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _pickAndUploadResume,
                                child: const Text(
                                  'REPLACE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _pickTempResume,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('SELECT RESUME'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 44),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed:
                      (_resumeSource == 'profile' && _hasResume) ||
                          (_resumeSource == 'upload' && _resumePath != null)
                      ? _startInterview
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        ((_resumeSource == 'profile' && _hasResume) ||
                            (_resumeSource == 'upload' && _resumePath != null))
                        ? const Color(0xFF40FFA7)
                        : Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ((_resumeSource == 'profile' && _hasResume) ||
                                (_resumeSource == 'upload' &&
                                    _resumePath != null))
                            ? Icons.play_arrow
                            : Icons.lock_outline,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ((_resumeSource == 'profile' && _hasResume) ||
                                  (_resumeSource == 'upload' &&
                                      _resumePath != null))
                              ? 'START INTERVIEW'
                              : 'SELECT RESUME TO START',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width < 380
                                ? 13
                                : 15,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumeOption({
    required String title,
    required String subtitle,
    required bool selected,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: selected
              ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackView() {
    final f = _feedback!.feedback;
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFD9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(8, 8)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'INTERVIEW FEEDBACK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: (f['score'] ?? 0) / 100,
                          strokeWidth: 16,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF81C784),
                          ),
                        ),
                      ),
                      Text(
                        '${f['score']}%',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildFeedbackDetail('Overall Performance', f['overall']),
                  const Divider(height: 40, thickness: 2, color: Colors.black),
                  _buildFeedbackDetail('Behavioral', f['behavioral']),
                  _buildFeedbackDetail('Technical', f['technical']),
                  _buildFeedbackDetail('Creative', f['creative']),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'RETURN TO DASHBOARD',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackDetail(String title, dynamic content) {
    if (content == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.toString(),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile {
  final String id;
  final String label;
  final String? subLabel;
  final Color color;
  final Widget content;

  const _ParticipantTile({
    required this.id,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.content,
  });
}
