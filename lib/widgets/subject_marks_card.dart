import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/performance_model.dart';

class OverviewCard extends StatelessWidget {
  final OverviewData overview;

  const OverviewCard({
    super.key,
    required this.overview,
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
          // 1. Overview Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9C4), // Light Yellow Header
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
                     const Text('ACADEMIC OVERVIEW', 
                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                     ),
                     Text(
                       '${overview.predictiveSummary.stabilityScore}%',
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: overview.riskLevel == 'Low' ? const Color(0xFFA5D6A7) : const Color(0xFFFFCCBC),
                     borderRadius: BorderRadius.circular(30),
                     border: Border.all(color: Colors.black, width: 2),
                   ),
                   child: Text(
                     'Risk: ${overview.riskLevel}',
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                   ),
                 ),
              ],
            ),
          ),

          // 2. Attendance & Details Body(Replaces Subjects)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricBar('Attendance', overview.attendance, const Color(0xFF4DB6AC)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '$value%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: (value / 100).clamp(0.0, 1.0),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
