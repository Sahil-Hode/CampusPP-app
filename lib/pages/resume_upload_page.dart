import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'resume_analysis_result_page.dart';
import '../services/resume_service.dart';
import '../models/resume_analysis_model.dart';
import '../widgets/scanning_animation.dart';

class ResumeUploadPage extends StatefulWidget {
  const ResumeUploadPage({super.key});

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}


class _ResumeUploadPageState extends State<ResumeUploadPage> {
  String? _fileName;
  String? _filePath;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          _filePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _analyzeResume() async {
    if (_filePath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ResumeService.analyzeResume(_filePath!);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (response.data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumeAnalysisResultPage(data: response.data!),
            ),
          );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(response.message ?? 'Analysis failed')),
             );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Mint background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resume Analyzer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Upload your Resume',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get AI-powered feedback on keywords, formatting, and content.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
  
                // Upload Area
                GestureDetector(
                  onTap: _pickFile,
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: Colors.black,
                      strokeWidth: 2,
                      dashPattern: [10, 6],
                      radius: 20,
                    ),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploading)
                            Column(
                              children: const [
                                ScanningAnimation(width: 80, height: 100, color: Color(0xFF29B6F6)),
                                SizedBox(height: 16),
                                Text('Analyzing...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            )
                          else ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7FA),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _fileName != null ? Icons.description : Icons.cloud_upload,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _fileName ?? 'Tap to Upload PDF or DOC',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_fileName == null) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Supports .pdf, .doc, .docx',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
  
                // Analyze Button
                ElevatedButton(
                  onPressed: _fileName != null && !_isUploading ? _analyzeResume : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F), // Yellow
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Analyze Resume ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashPattern = const [5, 3],
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    Path dashedPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        double len = dashPattern[0];
        if (distance + len > measurePath.length) {
          len = measurePath.length - distance;
        }
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashPattern[0] + dashPattern[1];
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
