import 'package:flutter/material.dart';
import '../models/resume_analysis_model.dart';
// import 'resume_upload_page.dart'; // Circular import if we go back logic changes, but pop is fine.

class ResumeAnalysisResultPage extends StatelessWidget {
  final ResumeAnalysisData data;

  const ResumeAnalysisResultPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5), // Softer background
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
          'Analysis Results',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Resume Score (${data.overallRating})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Score Card
              _buildNeuCard(
                color: const Color(0xFFE0F2F1), // Mint
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.atsScore}/100',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Text('Based on ATS criteria'),
                        ],
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.description, size: 30, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Keyword Analysis
              if (data.analysis.missingOrSuggestedSkills.isNotEmpty) ...[
                const Text(
                  'Suggested Skills',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.analysis.missingOrSuggestedSkills.take(8).map((skill) {
                    return _buildChip(skill, false);
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Strengths
               if (data.analysis.mainStrengths.isNotEmpty) ...[
                const Text(
                  'Strengths',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildNeuCard(
                  child: Column(
                    children: data.analysis.mainStrengths.take(5).map((s) {
                       return Column(
                         children: [
                           _buildFeedbackItem(s, true),
                           const Divider(color: Colors.black12),
                         ],
                       );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],


              // Improvements
               if (data.analysis.criticalImprovements.isNotEmpty) ...[
                const Text(
                  'Improvements Needed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildNeuCard(
                  child: Column(
                    children: data.analysis.criticalImprovements.take(5).map((s) {
                       return Column(
                         children: [
                           _buildFeedbackItem(s, false),
                           const Divider(color: Colors.black12),
                         ],
                       );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
               ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Upload New Resume', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check : Icons.warning_amber_rounded,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.visible, // Allow wrapping
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(String text, bool isPositive) {
    return Row(
      children: [
        Icon(
          isPositive ? Icons.check_circle : Icons.info,
          color: isPositive ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildNeuCard({required Widget child, Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
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
      child: child,
    );
  }
}
