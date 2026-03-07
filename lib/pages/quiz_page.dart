import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

class QuizPage extends StatefulWidget {
  final String title;
  final QuizData quiz;

  const QuizPage({
    super.key,
    required this.title,
    required this.quiz,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Map<int, int> _answers = {};
  // ✅ NEW: tracks which questions have their hint expanded
  final Set<int> _expandedHints = {};
  bool _isSubmitting = false;

  // ✅ NEW: difficulty badge color
  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'hard':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  // ✅ NEW: questionType badge color
  Color _questionTypeColor(String type) {
    switch (type) {
      case 'recall':
        return const Color(0xFF2196F3);
      case 'concept':
        return const Color(0xFF9C27B0);
      case 'analytical':
        return const Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }

  // ✅ NEW: questionType label
  String _questionTypeLabel(String type) {
    switch (type) {
      case 'recall':
        return 'Recall';
      case 'concept':
        return 'Concept';
      case 'analytical':
        return 'Analytical';
      default:
        return type;
    }
  }

  Future<void> _submit() async {
    if (_answers.length != widget.quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final answers = List.generate(widget.quiz.questions.length, (i) {
      return {
        'questionIndex': i,
        'selectedAnswer': _answers[i] ?? 0,
      };
    });

    try {
      final result = await QuizService.submitQuiz(
        quizId: widget.quiz.id,
        answers: answers,
      );
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Quiz',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.quiz.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              final isHintExpanded = _expandedHints.contains(index);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NEW: difficulty + questionType badges row
                    Row(
                      children: [
                        _Badge(
                          label: q.difficulty.toUpperCase(),
                          color: _difficultyColor(q.difficulty),
                        ),
                        const SizedBox(width: 8),
                        _Badge(
                          label: _questionTypeLabel(q.questionType),
                          color: _questionTypeColor(q.questionType),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Question text
                    Text(
                      'Q${index + 1}. ${q.question}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Options
                    ...q.options.asMap().entries.map((opt) {
                      return RadioListTile<int>(
                        value: opt.key,
                        groupValue: _answers[index],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _answers[index] = val);
                        },
                        title: Text(opt.value),
                        activeColor: Colors.black,
                      );
                    }).toList(),

                    // ✅ NEW: thinkingHint toggle (only if hint exists)
                    if (q.thinkingHint.isNotEmpty) ...[
                      const Divider(height: 20),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isHintExpanded) {
                              _expandedHints.remove(index);
                            } else {
                              _expandedHints.add(index);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 18, color: Color(0xFFFF9800)),
                            const SizedBox(width: 6),
                            const Text(
                              'Thinking Hint',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isHintExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFFFF9800),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      if (isHintExpanded) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF9800), width: 1),
                          ),
                          child: Text(
                            q.thinkingHint,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Quiz',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: reusable badge widget for difficulty and questionType
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}