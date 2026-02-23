import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/student_service.dart';
import '../models/performance_model.dart';
import 'ai_analysis_page.dart';

class PerformanceAnalysisPage extends StatefulWidget {
  const PerformanceAnalysisPage({super.key});

  @override
  State<PerformanceAnalysisPage> createState() => _PerformanceAnalysisPageState();
}

class _PerformanceAnalysisPageState extends State<PerformanceAnalysisPage> {
  PerformanceData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await StudentService.getPerformance();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
       setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Performance Page', // Updated Name
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Header Card with Score
                        _buildNeuCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCE93D8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Overall Score',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Progress Bar
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 12,
                                              width: constraints.maxWidth,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.black, width: 1.5),
                                              ),
                                            ),
                                            Container(
                                              height: 12,
                                              width: constraints.maxWidth * ((_data?.score ?? 0) / 100),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFA726),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.black, width: 1.5),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${_data?.score}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Attendance', '${_data?.attendance}%', const Color(0xFFE0F7FA))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Internal', '${_data?.internalMarks}/100', const Color(0xFFFFF3E0))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Risk & Trend Row
                        Row(
                          children: [
                             Expanded(child: _buildStatCard('Risk Level', _data?.riskLevel ?? '-', _data?.riskLevel == 'High' ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9))),
                             const SizedBox(width: 12),
                             Expanded(child: _buildStatCard('Trend', _data?.trends ?? '-', const Color(0xFFE1BEE7))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Recommendations
                        if (_data?.recommendations.isNotEmpty == true) ...[
                          const Text(
                            'AI Recommendations',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: _data!.recommendations.map((rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildNeuCard(
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(rec, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 30),
                        ],

                        // AI Report Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AiAnalysisPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD54F), // Yellow/Gold
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.black, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'View Detailed AI Report',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return _buildNeuCard(
      color: color,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNeuCard({
    required Widget child,
    Color color = Colors.white,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
