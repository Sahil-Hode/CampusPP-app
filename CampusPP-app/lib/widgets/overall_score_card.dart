import 'package:flutter/material.dart';
import '../models/performance_model.dart';

class OverallScoreCard extends StatelessWidget {
  final int overallScore;
  final ScoreBreakdown? breakdown;
  final String title;

  const OverallScoreCard({
    super.key,
    required this.overallScore,
    this.breakdown,
    this.title = 'Overall Performance',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
           // 1. Overall Score Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE1BEE7), // Light Purple Header
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(21),
                  topRight: Radius.circular(21),
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(title.toUpperCase(), 
                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                       ),
                       Text(
                         '$overallScore%',
                         style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                       ),
                     ],
                   ),
                   Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.bar_chart, color: Colors.black),
                   ),
                ],
              ),
            ),

          if (breakdown != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMetricBar('Attendance', breakdown!.attendance, const Color(0xFFFFD54F)),
                  const SizedBox(height: 16),
                  _buildMetricBar('Internal Marks', breakdown!.internalMarks, const Color(0xFF64B5F6)),
                  const SizedBox(height: 16),
                  _buildMetricBar('Assignments', breakdown!.assignmentScore, const Color(0xFF81C784)),
                  const SizedBox(height: 16),
                  _buildMetricBar('LMS Engagement', breakdown!.lmsEngagement, const Color(0xFFFF8A65)),
                ],
              ),
            )
          else 
             const Padding(
               padding: EdgeInsets.all(24),
               child: Center(child: Text('No breakdown data available')),
             ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, int value, Color color) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        // Progress Bar
        Expanded(
          child: Stack(
            children: [
              // Background
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: (value / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Percentage
        SizedBox(
          width: 36,
          child: Text(
            '$value%', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
