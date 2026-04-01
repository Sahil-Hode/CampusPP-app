import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/sarvam_service.dart';

class NotesAnalyzerPage extends StatefulWidget {
  const NotesAnalyzerPage({super.key});

  @override
  State<NotesAnalyzerPage> createState() => _NotesAnalyzerPageState();
}

class _NotesAnalyzerPageState extends State<NotesAnalyzerPage>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  String _selectedLanguage = 'English';
  bool _isAnalyzing = false;
  SarvamAnalysisResult? _result;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _languages = [
    {'name': 'English', 'flag': '🇬🇧'},
    {'name': 'Hindi', 'flag': '🇮🇳'},
    {'name': 'Tamil', 'flag': '🇮🇳'},
    {'name': 'Telugu', 'flag': '🇮🇳'},
    {'name': 'Kannada', 'flag': '🇮🇳'},
    {'name': 'Malayalam', 'flag': '🇮🇳'},
    {'name': 'Bengali', 'flag': '🇮🇳'},
    {'name': 'Marathi', 'flag': '🇮🇳'},
    {'name': 'Gujarati', 'flag': '🇮🇳'},
    {'name': 'Punjabi', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _fileName = image.name;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeNotes() async {
    if (_selectedFile == null) {
      setState(() => _errorMessage = 'Please select a file first');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await SarvamService.analyzeNotes(
        _selectedFile!.path,
        language: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isAnalyzing = false;
        });
      }
    }
  }

  void _clearAll() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _result = null;
      _errorMessage = null;
      _selectedLanguage = 'English';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Soft lavender background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 20),
                    _buildUploadSection(),
                    const SizedBox(height: 16),
                    _buildLanguageSelector(),
                    const SizedBox(height: 20),
                    _buildAnalyzeButton(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorCard(),
                    ],
                    if (_isAnalyzing) ...[
                      const SizedBox(height: 24),
                      _buildLoadingAnimation(),
                    ],
                    if (_result != null && _result!.success) ...[
                      const SizedBox(height: 24),
                      _buildResultsSection(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes Analyzer',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Powered by Sarvam AI',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (_result != null || _selectedFile != null)
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.refresh, color: Colors.black, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1BEE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.5),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Document Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upload handwritten notes, PDFs, or images and get instant translations & summaries.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _showUploadOptions,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _selectedFile != null
              ? const Color(0xFFA8E6CF)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black,
            width: 2.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: _selectedFile != null
            ? _buildFileSelectedView()
            : _buildUploadPlaceholder(),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 2),
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 40,
            color: Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to Upload',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, PDF, WEBP supported',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildFileSelectedView() {
    final ext = _fileName?.split('.').last.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: isImage && _selectedFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, size: 28, color: Colors.black54),
                  ),
                )
              : Icon(
                  ext == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                  size: 28,
                  color: ext == 'pdf' ? Colors.red[700] : Colors.black54,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fileName ?? 'Unknown file',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to change file',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: const Icon(Icons.check, size: 18, color: Colors.green),
        ),
      ],
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.black, width: 2.5),
            left: BorderSide(color: Colors.black, width: 2.5),
            right: BorderSide(color: Colors.black, width: 2.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    subtitle: 'Take a photo',
                    color: const Color(0xFFFFE082),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.folder_open_rounded,
                    label: 'Files',
                    subtitle: 'Browse device',
                    color: const Color(0xFFB2EBF2),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFile();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'TARGET LANGUAGE',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _languages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected = lang['name'] == _selectedLanguage;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLanguage = lang['name']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9C27B0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black,
                      width: isSelected ? 2.5 : 2,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang['flag'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lang['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final bool canAnalyze = _selectedFile != null && !_isAnalyzing;
    return GestureDetector(
      onTap: canAnalyze ? _analyzeNotes : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: canAnalyze
              ? const Color(0xFF9C27B0)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canAnalyze ? Colors.black : Colors.grey[400]!,
            width: 2.5,
          ),
          boxShadow: canAnalyze
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(5, 5),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: canAnalyze ? Colors.white : Colors.grey[500],
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze Notes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: canAnalyze ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology,
              size: 40,
              color: Color(0xFF9C27B0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AI is analyzing your notes...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Extracting text & translating to $_selectedLanguage',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(
          color: Color(0xFF9C27B0),
          backgroundColor: Color(0xFFE1BEE7),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ ANALYSIS COMPLETE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_result?.language != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFA8E6CF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  _result!.language!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary Card
        if (_result?.summary != null && _result!.summary!.isNotEmpty)
          _buildResultCard(
            title: '📋 Summary',
            content: _result!.summary!,
            color: const Color(0xFFFFE082),
            iconColor: const Color(0xFFF9A825),
          ),

        if (_result?.originalText != null && _result!.originalText!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildResultCard(
            title: '📝 Extracted Text',
            content: _result!.originalText!,
            color: Colors.white,
            iconColor: Colors.black54,
          ),
        ],

        if (_result?.translatedText != null &&
            _result!.translatedText!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildResultCard(
            title: '🌐 Translated Text',
            content: _result!.translatedText!,
            color: const Color(0xFFB2EBF2),
            iconColor: const Color(0xFF00838F),
          ),
        ],

        // Fallback: If no recognized text fields are populated, show the raw JSON
        if (!_result!.hasContent) ...[
          const SizedBox(height: 14),
          _buildResultCard(
            title: '🛠️ Raw API Output',
            content: _result!.rawData.toString(),
            color: const Color(0xFFCFD8DC),
            iconColor: Colors.black54,
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String content,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.6,
                ),
                strong: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                listBullet: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }
}
