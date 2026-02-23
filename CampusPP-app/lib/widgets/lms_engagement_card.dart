import 'package:flutter/material.dart';
import '../models/student_model.dart';

class LMSEngagementCard extends StatelessWidget {
  final int engagementScore;

  const LMSEngagementCard({
    super.key,
    required this.engagementScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced vertical padding
      decoration: BoxDecoration(
        color: const Color(0xFF40FFA7),
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
          // Penguin icon
          Container(
            width: 50, // Smaller
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🐧',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LMS Engagement',
                      style: TextStyle(
                        fontSize: 16, // Slightly smaller
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '$engagementScore%', 
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 10, // Thinner
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (engagementScore / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5), // Blue
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
