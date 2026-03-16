import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectMarksCard extends StatelessWidget {
  final Map<String, double> subjectMarks;
  final int averageMarks;

  const SubjectMarksCard({
    super.key,
    required this.subjectMarks,
    required this.averageMarks,
  });

  Color _barColor(double marks) {
    if (marks >= 75) return const Color(0xFF40FFA7);
    if (marks >= 60) return const Color(0xFFFFD54F);
    return const Color(0xFFFF8B94);
  }

  @override
  Widget build(BuildContext context) {
    if (subjectMarks.isEmpty) return const SizedBox.shrink();

    final sorted = subjectMarks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.menu_book, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SUBJECT MARKS',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _barColor(averageMarks.toDouble()),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    'AVG $averageMarks%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subject bars
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildSubjectBar(sorted[i].key, sorted[i].value, i),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(String subject, double marks, int index) {
    final color = _barColor(marks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                subject,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${marks.toInt()}%',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: marks < 60 ? const Color(0xFFFF8B94) : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (marks / 100).clamp(0.0, 1.0),
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
