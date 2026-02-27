import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';
import '../models/mock_interview_model.dart';

class MockInterviewSocketService {
  static const String _socketUrl = 'https://campuspp-f7qx.onrender.com/mock-interview';
  IO.Socket? _socket;
  
  // Streams for the UI to listen to
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _audioController = StreamController<Map<String, dynamic>>.broadcast();
  final _transcriptionController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _feedbackController = StreamController<InterviewFeedback>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get audio => _audioController.stream;
  Stream<Map<String, dynamic>> get transcription => _transcriptionController.stream;
  Stream<String> get status => _statusController.stream;
  Stream<InterviewFeedback> get feedback => _feedbackController.stream;

  Future<void> connect(String sessionId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No token found');

    print('Connecting to Socket: $_socketUrl with SessionID: $sessionId');

    _socket = IO.io(_socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      print('Socket Connected Successfully');
      _statusController.add('connected');
      // Added a small delay to ensure backend is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        print('Emitting joinInterview for $sessionId');
        _socket!.emit('joinInterview', {'sessionId': sessionId});
      });
    });

    _socket!.onConnectError((data) {
      print('Socket Connection Error: $data');
      _statusController.add('error');
    });

    _socket!.on('connected', (data) {
      print('Server Connection Confirmed: $data');
    });

    _socket!.on('interviewJoined', (data) {
      print('Joined Interview Success: $data');
      _statusController.add('joined');
    });

    _socket!.on('interviewMessage', (data) {
      print('AI Message Received: ${data['message']}');
      _messageController.add(data);
    });

    _socket!.on('interviewAudio', (data) {
      print('AI Audio Chunk Received (Base64 length: ${data['audioBase64']?.length})');
      _audioController.add(data);
    });

    _socket!.on('interviewTranscription', (data) {
      print('User Transcription: ${data['text']}');
      _transcriptionController.add(data);
    });

    _socket!.on('interviewProcessing', (data) {
      print('Server is processing answer...');
      _statusController.add('processing');
    });

    _socket!.on('interviewStreamStarted', (data) {
      print('Voice stream started - user can speak now');
      _statusController.add('streaming');
    });

    _socket!.on('interviewEnded', (data) {
      print('Interview Ended: Session ${data['sessionId']}');
      if (data['feedback'] != null) {
        _feedbackController.add(InterviewFeedback.fromJson(data));
      }
      _statusController.add('ended');
    });

    _socket!.on('interviewError', (data) {
      print('SERVER ERROR: ${data['message']}');
      _statusController.add('error');
    });

    _socket!.on('interviewTTSError', (data) {
      print('TTS ERROR: ${data['message']}');
      // Surface TTS errors as general errors for now
      _statusController.add('error');
    });

    _socket!.onDisconnect((reason) {
      print('Socket Disconnected: $reason');
      _statusController.add('disconnected');
    });

    _socket!.connect();
  }

  void startVoiceStream() {
    _socket?.emit('interviewStartStream', {
      'encoding': 'LINEAR16',
      'sampleRateHertz': 16000,
      'languageCode': 'en-US',
    });
  }

  void sendAudioChunk(List<int> chunk) {
    _socket?.emit('interviewAudioData', chunk);
  }

  void stopVoiceStream() {
    _socket?.emit('interviewStopStream');
  }

  void endInterview() {
    _socket?.emit('endInterview');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _audioController.close();
    _transcriptionController.close();
    _statusController.close();
    _feedbackController.close();
  }
}
