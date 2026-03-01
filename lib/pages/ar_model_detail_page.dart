import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARModelDetailPage extends StatefulWidget {
  final String modelPath;
  final String title;

  const ARModelDetailPage({
    super.key,
    required this.modelPath,
    required this.title,
  });

  @override
  State<ARModelDetailPage> createState() => _ARModelDetailPageState();
}

class _ARModelDetailPageState extends State<ARModelDetailPage> {
  bool _isModelLoaded = false;
  bool _hasError = false;
  String? _modelSrc;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _prepareModel();
  }

  bool get _isRemoteUrl =>
      widget.modelPath.startsWith('http://') ||
      widget.modelPath.startsWith('https://');

  Future<void> _prepareModel() async {
    if (widget.modelPath.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No model URL available. The model may still be processing.';
        });
      }
      return;
    }

    if (_isRemoteUrl) {
      // Use the remote URL directly — model_viewer_plus handles HTTP URLs natively
      // This avoids the Android WebView file:// security restriction
      if (mounted) {
        setState(() {
          _modelSrc = widget.modelPath;
          _isModelLoaded = true;
        });
      }
    } else {
      // Local asset — ready immediately
      setState(() {
        _modelSrc = widget.modelPath;
        _isModelLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Match dashboard theme
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap the AR icon in the corner of the model viewer to place the model in your real environment!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: _hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isModelLoaded = false;
                                  });
                                  _prepareModel();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isModelLoaded && _modelSrc != null
                        ? ModelViewer(
                            backgroundColor: const Color(0xFFF5F5F5),
                            src: _modelSrc!,
                            alt: 'A 3D model of ${widget.title}',
                            ar: true,
                            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                            autoRotate: true,
                            cameraControls: true,
                            disableZoom: false,
                            autoPlay: true,
                            shadowIntensity: 1.0,
                            shadowSoftness: 1.0,
                            exposure: 1.0,
                            environmentImage: 'neutral',
                            loading: Loading.eager,
                            reveal: Reveal.auto,
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading 3D Model...',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
