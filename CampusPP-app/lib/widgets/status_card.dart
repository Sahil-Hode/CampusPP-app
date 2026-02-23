import 'package:flutter/material.dart';
import '../models/student_model.dart';

class StatusCard extends StatelessWidget {
  final Student student;

  const StatusCard({
    super.key,
    required this.student,
  });

  Color _getRiskColor() {
    switch (student.riskLevel) {
      case RiskLevel.safe:
        return const Color(0xFF7DD3C0); // Mint green
      case RiskLevel.warning:
        return const Color(0xFFFFC857); // Soft yellow
      case RiskLevel.critical:
        return const Color(0xFFFF8B94); // Soft red
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFB8F4E4).withOpacity(0.3),
            const Color(0xFFD4F1F4).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7DD3C0).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getRiskColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    student.riskLevelText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getRiskColor(),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8F4E4).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  student.stabilityText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2D6A5F),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
