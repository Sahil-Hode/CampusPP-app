import 'package:flutter/material.dart';
import '../models/performance_model.dart';
import '../services/student_service.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/roadmap_completion_overlay.dart';
import '../services/quiz_service.dart';
import '../models/quiz_model.dart';
import 'quiz_page.dart';

class LearningPathDetailPage extends StatefulWidget {
  final LearningPath path;

  const LearningPathDetailPage({super.key, required this.path});

  @override
  State<LearningPathDetailPage> createState() => _LearningPathDetailPageState();
}

class _LearningPathDetailPageState extends State<LearningPathDetailPage> {
  late LearningPath _path;
  bool _isLoading = false; // Initial load or major refresh
  bool _isStepUpdating = false; // Specific step updating
  int? _expandedStepIndex; // Track expanded step
  bool _showCelebration = false;
  bool _showFinalCelebration = false;
  Map<String, QuizStatusStep> _quizStatusMap = {};

  @override
  void initState() {
    super.initState();
    _path = widget.path;
    _loadQuizStatus();
  }

  Duration? _cooldownRemaining(DateTime? cooldownUntil) {
    if (cooldownUntil == null) return null;
    final now = DateTime.now();
    if (cooldownUntil.isBefore(now)) return Duration.zero;
    return cooldownUntil.difference(now);
  }

  String _formatCooldown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Future<void> _loadQuizStatus() async {
    try {
      final map = await QuizService.getLearningPathQuizStatus(_path.id);
      if (mounted) {
        setState(() => _quizStatusMap = map);
      }
    } catch (e) {
      print('Quiz status load failed: $e');
    }
  }

  Future<void> _refreshPathAndStatus() async {
    try {
      final updatedPath = await StudentService.getLearningPath(_path.id);
      if (mounted) {
        setState(() => _path = updatedPath);
      }
    } catch (e) {
      print('Failed to refresh path: $e');
    }
    await _loadQuizStatus();
  }

  Future<void> _startQuiz(LearningStep data) async {
    final key = '${data.courseIndex}_${data.stepIndex}';
    final status = _quizStatusMap[key];
    final remaining = _cooldownRemaining(status?.cooldownUntil);
    if (remaining != null && remaining > Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz locked. Try again in ${_formatCooldown(remaining)}.')),
      );
      return;
    }

    if (status?.quizStatus == 'passed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz already passed. Keep going!')),
      );
      return;
    }

    setState(() => _isStepUpdating = true);
    QuizGenerateResult generate;
    try {
      generate = await QuizService.generateQuiz(
        learningPathId: _path.id,
        courseIndex: data.courseIndex,
        stepIndex: data.stepIndex,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start quiz: $e')),
        );
        setState(() => _isStepUpdating = false);
      }
      return;
    }

    if (generate.moduleLocked) {
      if (mounted) setState(() => _isStepUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(generate.message ?? 'Module is locked.')),
      );
      return;
    }

    if (generate.cooldownUntil != null) {
      setState(() {
        _quizStatusMap[key] = QuizStatusStep(
          courseIndex: data.courseIndex,
          stepIndex: data.stepIndex,
          quizId: status?.quizId ?? '',
          quizStatus: 'cooldown',
          bestScore: status?.bestScore ?? 0,
          attemptCount: status?.attemptCount ?? 0,
          cooldownUntil: generate.cooldownUntil,
          cooldownRemainingMinutes: generate.remainingMinutes ?? 0,
          canAttempt: false,
        );
        _isStepUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(generate.message ?? 'Quiz is in cooldown.')),
      );
      return;
    }

    if (generate.alreadyPassed) {
      await _loadQuizStatus();
      if (mounted) setState(() => _isStepUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already passed this quiz.')),
      );
      return;
    }

    if (generate.quiz == null) {
      if (mounted) setState(() => _isStepUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz not available. Try again.')),
      );
      return;
    }

    final result = await Navigator.push<QuizSubmitResult>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          title: data.title,
          quiz: generate.quiz!,
        ),
      ),
    );

    if (result == null || !mounted) {
      if (mounted) setState(() => _isStepUpdating = false);
      return;
    }

    if (result.passed) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Congratulations!'),
            content: Text('You scored ${result.score}% in ${data.title}. Keep it up and move to the next step.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cooldown Activated'),
            content: Text('You scored ${result.score}%. You need 70%+ to pass. Try again after 24 hours.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    }

    await _refreshPathAndStatus();
    if (mounted) setState(() => _isStepUpdating = false);
  }

  Future<void> _updateProgress(String pathId, int completedSteps) async {
    // Show celebration immediately
    setState(() {
       _showCelebration = true;
       _isStepUpdating = true;
    });

    try {
      await StudentService.updateLearningProgress(pathId, completedSteps);
      // Fetch updated path silently
      final updatedPath = await StudentService.getLearningPath(pathId);
      
      bool isFinalStep = completedSteps >= _path.steps.length;

      if (mounted) {
        setState(() {
          _path = updatedPath;
          _isStepUpdating = false;
          _expandedStepIndex = null; // Collapse after update
          if (isFinalStep) {
            _showFinalCelebration = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStepUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update progress: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(_path.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true), 
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(_path),
                        const SizedBox(height: 30),
                        const Text(
                          'YOUR ROADMAP',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ..._path.steps.asMap().entries.map((entry) {
                          return Column(
                            children: [
                              _buildPathStep(
                                step: entry.key + 1,
                                data: entry.value,
                                index: entry.key,
                                isLast: entry.key == _path.steps.length - 1,
                              ),
                              if (entry.key != _path.steps.length - 1)
                                _buildPathConnector(entry.value.status == 'completed'),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
          if (_showCelebration)
             CelebrationOverlay(
               onFinished: () {
                 if (mounted) setState(() => _showCelebration = false);
               },
             ),
             
          if (_showFinalCelebration)
            RoadmapCompletionOverlay(
              earnedPoints: 50, // Standard reward
              badgeName: "${_path.title} Master",
              onFinished: () {
                if (mounted) setState(() => _showFinalCelebration = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(LearningPath path) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Goal', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(path.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${path.progress}% Completed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.flag, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildPathStep({
    required int step,
    required LearningStep data,
    required int index,
    required bool isLast,
  }) {
    Color color;
    IconData icon;
    bool isCurrent = false;
    bool isExpanded = _expandedStepIndex == index;
    final key = '${data.courseIndex}_${data.stepIndex}';
    final quizStatus = _quizStatusMap[key];
    final cooldownRemaining = _cooldownRemaining(quizStatus?.cooldownUntil);
    final isInCooldown = cooldownRemaining != null && cooldownRemaining > Duration.zero;
    final isPassed = quizStatus?.quizStatus == 'passed' || data.status.toLowerCase() == 'completed';

    if (isPassed) {
      color = const Color(0xFFA5D6A7); // Green
      icon = Icons.check_circle;
    } else if (data.status.toLowerCase() == 'in-progress') {
      color = const Color(0xFFFFF59D); // Yellow
      isCurrent = true;
      icon = isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down;
    } else {
      color = Colors.grey.shade300;
      icon = Icons.lock;
    }

    return GestureDetector(
      onTap: () {
        if (data.status == 'locked') {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish previous steps first!')));
           return;
        }
        setState(() {
          if (_expandedStepIndex == index) {
            _expandedStepIndex = null; // Collapse if already expanded
          } else {
            _expandedStepIndex = index; // Expand this one
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: isCurrent 
              ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
              : [],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              title: Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
              subtitle: Text(data.description, style: const TextStyle(color: Colors.black87, fontSize: 12)),
              trailing: Icon(icon, size: 28, color: Colors.black),
            ),
            
            // Expanded Content
            if (isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 10),
                    const Text(
                      "Key Concepts & Theory:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.content,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    
                    if (data.status == 'in-progress') ...[
                      if (isPassed)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA5D6A7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.black),
                              const SizedBox(width: 8),
                              Text(
                                'Quiz passed: ${quizStatus?.bestScore ?? 0}%',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else if (isInCooldown)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCDD2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_clock, color: Colors.black),
                              const SizedBox(width: 8),
                              Text(
                                'Cooldown: ${_formatCooldown(cooldownRemaining!)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isStepUpdating || isInCooldown || isPassed
                              ? null
                              : () => _startQuiz(data),
                          icon: _isStepUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.quiz, color: Colors.white),
                          label: Text(
                            isPassed
                                ? 'Quiz Completed'
                                : isInCooldown
                                    ? 'Locked'
                                    : 'Start Quiz',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathConnector(bool isActive) {
    return Container(
      height: 30,
      width: 4,
      margin: const EdgeInsets.only(left: 40), 
      color: isActive ? Colors.black : Colors.grey.shade400,
    );
  }
}
