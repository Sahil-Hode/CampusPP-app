import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class QuizOverviewCard extends StatelessWidget {
  final QuizOverviewSummary summary;

  const QuizOverviewCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final failRate = summary.totalQuizzesAttempted == 0
        ? 0
        : ((summary.totalQuizzesFailed / summary.totalQuizzesAttempted) * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Insights',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your quiz performance at a glance',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 330;
              final labelFont = isNarrow ? 9.0 : 11.0;
              final valueFont = isNarrow ? 14.0 : 16.0;
              final height = isNarrow ? 60.0 : 56.0;
              return Row(
                children: [
                  Expanded(child: _statPill('Avg Score', '${summary.overallScore}%', valueFont, labelFont, height)),
                  const SizedBox(width: 8),
                  Expanded(child: _statPill('Passed', '${summary.totalQuizzesPassed}', valueFont, labelFont, height)),
                  const SizedBox(width: 8),
                  Expanded(child: _statPill('Attempts', '${summary.totalQuizzesAttempted}', valueFont, labelFont, height)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _barRow('Pass Rate', summary.passRate, const Color(0xFF40FFA7)),
          const SizedBox(height: 10),
          _barRow('Completion Rate', summary.completionRate, const Color(0xFF64B5F6)),
          const SizedBox(height: 10),
          _barRow('Fail Rate', failRate, const Color(0xFFFF8B94)),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, double valueFont, double labelFont, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: valueFont,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: labelFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barRow(String label, int value, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInlineLabel = constraints.maxWidth > 280;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!showInlineLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Row(
              children: [
                if (showInlineLabel)
                  SizedBox(
                    width: 110,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (value.clamp(0, 100)) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$value%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
