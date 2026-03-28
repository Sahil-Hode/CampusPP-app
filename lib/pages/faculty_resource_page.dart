import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/faculty_resource_model.dart';
import '../services/faculty_resource_service.dart';

class FacultyResourcePage extends StatefulWidget {
  const FacultyResourcePage({super.key});

  @override
  State<FacultyResourcePage> createState() => _FacultyResourcePageState();
}

class _FacultyResourcePageState extends State<FacultyResourcePage> {
  bool _loading = true;
  List<FacultyResource> _resources = [];

  static const _bg = Color(0xFFF0F4C3); // Light Lime / Yellowish green
  static const _primary = Color(0xFFCDDC39);
  static const _accent = Color(0xFFFF9800);
  static const _black = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _loading = true);
    try {
      final res = await FacultyResourceService.getResources();
      if (mounted) {
        setState(() {
          _resources = res;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resources: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download URL')));
      }
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays}d ago';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _black))
                  : _resources.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadResources,
                          color: _black,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _resources.length,
                            itemBuilder: (ctx, i) => _buildResourceCard(_resources[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _black, width: 2),
                boxShadow: const [BoxShadow(color: _black, offset: Offset(3, 3))],
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACULTY RESOURCES',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Study materials & documents',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _black, width: 2),
            ),
            child: const Icon(Icons.folder_open, size: 48, color: _accent),
          ),
          const SizedBox(height: 16),
          Text(
            'No Resources Found',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Files shared by faculty will appear here.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(FacultyResource res) {
    final isPdf = res.mimeType == 'application/pdf';
    final cardColor = isPdf ? const Color(0xFFFFCC80) : const Color(0xFFB39DDB);
    final iconData = isPdf ? Icons.picture_as_pdf : Icons.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _black, width: 2),
        boxShadow: const [BoxShadow(color: _black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _black, width: 1.5),
                  ),
                  child: Icon(iconData, size: 20, color: _black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        res.subject.isNotEmpty ? res.subject : 'General',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _black, width: 1.5),
                  ),
                  child: Text(
                    res.fileSizeLabel,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          // Body
          if (res.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                res.description,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            )
          else
            const SizedBox(height: 16),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      res.facultyName,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(res.createdAt),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _downloadFile(res.downloadUrl.isNotEmpty ? res.downloadUrl : res.fileUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Download',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
