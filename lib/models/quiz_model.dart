class QuizQuestion {
  final int index;
  final String question;
  final List<String> options;
  final String difficulty;

  QuizQuestion({
    required this.index,
    required this.question,
    required this.options,
    required this.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      index: json['index'] ?? 0,
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      difficulty: json['difficulty'] ?? 'easy',
    );
  }
}

class QuizData {
  final String id;
  final String topic;
  final String stepTitle;
  final String moduleTitle;
  final String status;
  final int passThreshold;
  final int attemptCount;
  final int bestScore;
  final DateTime? cooldownUntil;
  final DateTime? passedAt;
  final List<QuizQuestion> questions;

  QuizData({
    required this.id,
    required this.topic,
    required this.stepTitle,
    required this.moduleTitle,
    required this.status,
    required this.passThreshold,
    required this.attemptCount,
    required this.bestScore,
    required this.cooldownUntil,
    required this.passedAt,
    required this.questions,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      id: json['_id'] ?? '',
      topic: json['topic'] ?? '',
      stepTitle: json['stepTitle'] ?? '',
      moduleTitle: json['moduleTitle'] ?? '',
      status: json['status'] ?? 'unlocked',
      passThreshold: json['passThreshold'] ?? 70,
      attemptCount: json['attemptCount'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      cooldownUntil: json['cooldownUntil'] != null ? DateTime.tryParse(json['cooldownUntil']) : null,
      passedAt: json['passedAt'] != null ? DateTime.tryParse(json['passedAt']) : null,
      questions: (json['questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
    );
  }
}

class QuizGenerateResult {
  final QuizData? quiz;
  final bool alreadyPassed;
  final String? message;
  final DateTime? cooldownUntil;
  final int? remainingMinutes;
  final bool moduleLocked;

  QuizGenerateResult({
    required this.quiz,
    required this.alreadyPassed,
    required this.message,
    required this.cooldownUntil,
    required this.remainingMinutes,
    required this.moduleLocked,
  });
}

class QuizSubmitResult {
  final bool passed;
  final int score;
  final String message;
  final DateTime? cooldownUntil;
  final bool moduleCompleted;
  final Map<String, dynamic>? nextModule;

  QuizSubmitResult({
    required this.passed,
    required this.score,
    required this.message,
    required this.cooldownUntil,
    required this.moduleCompleted,
    required this.nextModule,
  });
}

class QuizStatusStep {
  final int courseIndex;
  final int stepIndex;
  final String quizId;
  final String quizStatus;
  final int bestScore;
  final int attemptCount;
  final DateTime? cooldownUntil;
  final int cooldownRemainingMinutes;
  final bool canAttempt;

  QuizStatusStep({
    required this.courseIndex,
    required this.stepIndex,
    required this.quizId,
    required this.quizStatus,
    required this.bestScore,
    required this.attemptCount,
    required this.cooldownUntil,
    required this.cooldownRemainingMinutes,
    required this.canAttempt,
  });

  factory QuizStatusStep.fromJson(int courseIndex, Map<String, dynamic> json) {
    return QuizStatusStep(
      courseIndex: courseIndex,
      stepIndex: json['stepIndex'] ?? 0,
      quizId: json['quizId']?.toString() ?? '',
      quizStatus: json['quizStatus'] ?? 'not_generated',
      bestScore: json['bestScore'] ?? 0,
      attemptCount: json['attemptCount'] ?? 0,
      cooldownUntil: json['cooldownUntil'] != null ? DateTime.tryParse(json['cooldownUntil']) : null,
      cooldownRemainingMinutes: json['cooldownRemainingMinutes'] ?? 0,
      canAttempt: json['canAttempt'] ?? false,
    );
  }
}

class QuizOverviewSummary {
  final int overallScore;
  final int highestScore;
  final int passRate;
  final int completionRate;
  final double avgAttemptsPerQuiz;
  final int totalQuizzesAttempted;
  final int totalQuizzesPassed;
  final int totalQuizzesFailed;

  QuizOverviewSummary({
    required this.overallScore,
    required this.highestScore,
    required this.passRate,
    required this.completionRate,
    required this.avgAttemptsPerQuiz,
    required this.totalQuizzesAttempted,
    required this.totalQuizzesPassed,
    required this.totalQuizzesFailed,
  });

  factory QuizOverviewSummary.fromJson(Map<String, dynamic> json) {
    return QuizOverviewSummary(
      overallScore: json['overallScore'] ?? 0,
      highestScore: json['highestScore'] ?? 0,
      passRate: json['passRate'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      avgAttemptsPerQuiz: (json['avgAttemptsPerQuiz'] ?? 0).toDouble(),
      totalQuizzesAttempted: json['totalQuizzesAttempted'] ?? 0,
      totalQuizzesPassed: json['totalQuizzesPassed'] ?? 0,
      totalQuizzesFailed: json['totalQuizzesFailed'] ?? 0,
    );
  }
}

class QuizScoreSummary {
  final int overallScore;
  final int highestScore;
  final int totalAttempts;
  final int quizzesPassed;
  final int totalQuizzes;
  final int totalPossibleQuizzes;
  final int completionRate;

  QuizScoreSummary({
    required this.overallScore,
    required this.highestScore,
    required this.totalAttempts,
    required this.quizzesPassed,
    required this.totalQuizzes,
    required this.totalPossibleQuizzes,
    required this.completionRate,
  });

  factory QuizScoreSummary.fromJson(Map<String, dynamic> json) {
    return QuizScoreSummary(
      overallScore: json['overallScore'] ?? 0,
      highestScore: json['highestScore'] ?? 0,
      totalAttempts: json['totalAttempts'] ?? 0,
      quizzesPassed: json['quizzesPassed'] ?? 0,
      totalQuizzes: json['totalQuizzes'] ?? 0,
      totalPossibleQuizzes: json['totalPossibleQuizzes'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
    );
  }
}
