import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/performance_model.dart';
import 'dart:math' as math;

class AiAnalysisPage extends StatefulWidget {
  const AiAnalysisPage({super.key});

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  TrendsData? _trendsData;
  RecommendationsData? _recommendationsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final trends = await StudentService.getTrends();
      final recs = await StudentService.getRecommendations();
      if (mounted) {
        setState(() {
          _trendsData = trends;
          _recommendationsData = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3), // Very light grey/mint
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI Analysis', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // 1. Trend Banner (Minimalist)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(5, 5), blurRadius: 0)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PERFORMANCE TREND', 
                              style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_trendsData?.trends ?? 'Stable').toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ],
                        ),
                        // Animated-looking Arrow
                        Transform.rotate(
                          angle: -math.pi / 4,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCE93D8), // Purple accent
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_forward, color: Colors.black, size: 32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Strengths & Focus (Creative Layout)
                  // Instead of boxes, use "Sticker" headers and floating items
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Transform.rotate(
                          angle: -0.05,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA5D6A7), // Green
                              border: Border.all(width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                            ),
                            child: const Text('SUPER POWERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: (_recommendationsData?.strengths ?? []).map((s) => _buildStickerItem(s, Colors.white)).toList(),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Transform.rotate(
                          angle: 0.05,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCCBC), // Orange
                              border: Border.all(width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                            ),
                            child: const Text('NEEDS ATTENTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Use a vertical list for concerns to make them readable
                   Column(
                     children: (_recommendationsData?.concerns ?? []).map((c) => _buildAlertItem(c)).toList(),
                   ),

                  const SizedBox(height: 40),

                  // 3. Main Action (Recommendation)
                  const Text('AI SUGGESTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  if ((_recommendationsData?.recommendations.isNotEmpty ?? false))
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0), // Sharp
                        border: Border.all(width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: const Color(0xFFFFD54F), // Yellow Header
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 16),
                                SizedBox(width: 8),
                                Text('TOP PRIORITY', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _recommendationsData!.recommendations.first,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  // Other recs plain list
                  if ((_recommendationsData?.recommendations.length ?? 0) > 1) ...[
                     const SizedBox(height: 20),
                     ..._recommendationsData!.recommendations.skip(1).map((r) => Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('->', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           const SizedBox(width: 12),
                           Expanded(child: Text(r, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                         ],
                       ),
                     )),
                  ],

                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildStickerItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30), // Pill shape
        border: Border.all(width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildAlertItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7), // Very light red/orange
        border: const Border(left: BorderSide(color: Colors.red, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }
}
