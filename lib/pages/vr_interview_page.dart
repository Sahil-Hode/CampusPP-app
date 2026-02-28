import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

class VRInterviewPage extends StatefulWidget {
  const VRInterviewPage({super.key});

  @override
  State<VRInterviewPage> createState() => _VRInterviewPageState();
}

class _VRInterviewPageState extends State<VRInterviewPage> {
  final localhostServer = InAppLocalhostServer(documentRoot: 'assets');
  bool _isInit = false;
  String _statusMessage = "Initializing Localhost Server...";

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      if (!localhostServer.isRunning()) {
        await localhostServer.start();
      }
      _setStatus("Ready to launch in Chrome");
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      _setStatus("Failed to init: \$e");
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  Future<void> _launchInBrowser() async {
    final token = await AuthService.getToken() ?? "";
    _setStatus("Launching Chrome...");
    
    final uri = Uri.parse("http://localhost:8080/html-model/index.html?token=$token");
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _setStatus("Could not launch Browser.");
    }
  }

  @override
  void dispose() {
    localhostServer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vrpano, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            Text(
              "WebXR Mock Interview",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "VR mode requires launching in a full browser\nlike Google Chrome to access WebXR features.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.blue[200], fontSize: 14),
            ),
            const SizedBox(height: 48),
            if (!_isInit)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _launchInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Launch in external Browser"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
