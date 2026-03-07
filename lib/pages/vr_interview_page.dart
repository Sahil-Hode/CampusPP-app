import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_unity_widget_2/flutter_unity_widget_2.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

class VRInterviewPage extends StatefulWidget {
  const VRInterviewPage({super.key});

  @override
  State<VRInterviewPage> createState() => _VRInterviewPageState();
}

class _VRInterviewPageState extends State<VRInterviewPage> {
  UnityWidgetController? _unityWidgetController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }

  void _onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void onUnityMessage(message) {
    print('Received message from unity: ${message.toString()}');
  }

  void onUnitySceneLoaded(SceneLoaded? scene) {
    if (scene != null) {
      print('Received scene loaded from unity: ${scene.name}');
    }
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
            onUnitySceneLoaded: onUnitySceneLoaded,
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
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                "3D Interview Environment Active\nLook around and interact",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
