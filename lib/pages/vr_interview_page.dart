import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/auth_service.dart';

class VRInterviewPage extends StatefulWidget {
  const VRInterviewPage({super.key});

  @override
  State<VRInterviewPage> createState() => _VRInterviewPageState();
}

class _VRInterviewPageState extends State<VRInterviewPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _authToken;
  String _errorMessage = '';
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    
    // Force landscape orientation for VR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      _authToken = await AuthService.getToken();
    } catch (e) {
      print('Error loading auth token: $e');
    }
    
    // Read the HTML file from assets
    try {
      _htmlContent = await rootBundle.loadString('assets/html-model/index.html');
      
      // Inject auth token into the HTML if available
      if (_authToken != null && _authToken!.isNotEmpty) {
        // Add a script right after <body> to set the token
        _htmlContent = _htmlContent!.replaceFirst(
          '<body>',
          '<body>\n<script>window.__AUTH_TOKEN__ = "${_authToken!}";</script>',
        );
      }
    } catch (e) {
      print('Error loading HTML: $e');
      _errorMessage = 'Failed to load HTML: $e';
    }
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base URL for resolving relative paths (ASSETS/classroom.glb, sw.js, etc.)
    const baseUrl = "file:///android_asset/flutter_assets/assets/html-model/";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // SINGLE full-screen WebView — loads the 3D classroom HTML
          // This renders ONE centered 3D model (no stereo split)
          if (_htmlContent != null)
            Positioned.fill(
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _htmlContent!,
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                  baseUrl: WebUri(baseUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  supportZoom: false,
                  transparentBackground: false,
                  allowContentAccess: true,
                  allowFileAccess: true,
                  // Allow mixed content (HTTP CDNs from file://)
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  // Enable WebGL for Three.js
                  hardwareAcceleration: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                },
                onLoadError: (controller, url, code, message) {
                  print('WebView Load Error: $code - $message');
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Load Error: $message ($code)';
                  });
                },
                onReceivedError: (controller, request, error) {
                  print('WebView Received Error: ${error.type} - ${error.description}');
                },
                onConsoleMessage: (controller, consoleMessage) {
                  print('WebView Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
                },
                onPermissionRequest: (controller, request) async {
                  // Auto-grant microphone permission for speech recognition
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF65C8FF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading VR Interview Room...',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Error display
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ===== CARDBOARD-STYLE BORDER OVERLAY =====
          // Rounded black vignette around both lenses
          if (!_isLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardboardBorderPainter(),
                ),
              ),
            ),

          // Center divider line
          if (!_isLoading)
            Positioned(
              left: screenWidth / 2 - 1.5,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 3,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),

          // Back button (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Settings gear icon (bottom-center)
          if (!_isLoading)
            Positioned(
              bottom: 16,
              left: screenWidth / 2 - 20,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter that draws Google Cardboard-style lens borders
/// Creates the exact rounded vignette effect from the reference image
class _CardboardBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2;
    final centerY = size.height / 2;
    
    // Lens radius — slightly smaller than half the screen height
    final lensRadius = min(halfW * 0.85, size.height * 0.45);
    
    // Create vignette path: full screen minus two circular cutouts
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Left lens center
    final leftCenter = Offset(halfW * 0.5, centerY);
    // Right lens center
    final rightCenter = Offset(halfW * 1.5, centerY);

    // Build the vignette path
    final path = Path()
      ..addRect(fullRect)
      ..addOval(Rect.fromCircle(center: leftCenter, radius: lensRadius))
      ..addOval(Rect.fromCircle(center: rightCenter, radius: lensRadius))
      ..fillType = PathFillType.evenOdd;

    // Draw solid black border
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw subtle white ring around each lens for polish
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(leftCenter, lensRadius, ringPaint);
    canvas.drawCircle(rightCenter, lensRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
