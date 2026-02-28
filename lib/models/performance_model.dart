class PerformanceData {
  final int score;
  final String riskLevel;
  final String trends;
  final List<String> recommendations;
  final int attendance;
  final int internalMarks;

  PerformanceData({
    required this.score,
    required this.riskLevel,
    required this.trends,
    required this.recommendations,
    required this.attendance,
    required this.internalMarks,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      score: (double.tryParse((json['score'] ?? json['overallScore'] ?? 0).toString()) ?? 0).toInt(),
      riskLevel: json['riskLevel']?.toString() ?? 'Unknown',
      trends: json['trends']?.toString() ?? 'Stable',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      attendance: (double.tryParse((json['attendance'] ?? 0).toString()) ?? 0).toInt(),
      internalMarks: (double.tryParse((json['internalMarks'] ?? 0).toString()) ?? 0).toInt(),
    );
  }
}

class RiskData {
  final bool isAtRisk;
  final String riskLevel;
  final List<String> riskFactors;

  RiskData({
    required this.isAtRisk,
    required this.riskLevel,
    required this.riskFactors,
  });

  factory RiskData.fromJson(Map<String, dynamic> json) {
    return RiskData(
      isAtRisk: json['isAtRisk'] ?? false,
      riskLevel: json['riskLevel'] ?? 'Unknown',
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
    );
  }
}

class ScoreBreakdown {
  final int attendance;
  final int internalMarks;
  final int assignmentScore;
  final int overallScore;
  final int lmsEngagement;

  ScoreBreakdown({
    required this.attendance,
    required this.internalMarks,
    required this.assignmentScore,
    required this.overallScore,
    required this.lmsEngagement,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      attendance: (double.tryParse((json['attendance'] ?? 0).toString()) ?? 0).toInt(),
      internalMarks: (double.tryParse((json['internalMarks'] ?? 0).toString()) ?? 0).toInt(),
      assignmentScore: (double.tryParse((json['assignmentScore'] ?? 0).toString()) ?? 0).toInt(),
      overallScore: (double.tryParse((json['overallScore'] ?? json['score'] ?? 0).toString()) ?? 0).toInt(),
      lmsEngagement: (double.tryParse((json['lmsEngagement'] ?? 0).toString()) ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance': attendance,
      'internalMarks': internalMarks,
      'assignmentScore': assignmentScore,
      'overallScore': overallScore,
      'lmsEngagement': lmsEngagement,
    };
  }
}

class TrendsData {
  final String trends;
  final String analysisDate;
  final int totalAnalyses;

  TrendsData({
    required this.trends,
    required this.analysisDate,
    required this.totalAnalyses,
  });

  factory TrendsData.fromJson(Map<String, dynamic> json) {
    final tr = json['trendAnalysis'] as Map<String, dynamic>? ?? {};
    final activeTrend = tr['trend']?.toString() ?? json['dbTrend']?.toString() ?? json['trends']?.toString() ?? 'Stable';
    return TrendsData(
      trends: activeTrend,
      analysisDate: json['analysisDate']?.toString() ?? '',
      totalAnalyses: json['totalAnalyses'] ?? 0,
    );
  }
}

class RecommendationsData {
  final List<String> recommendations;
  final List<String> strengths;
  final List<String> concerns;

  RecommendationsData({
    required this.recommendations,
    required this.strengths,
    required this.concerns,
  });

  factory RecommendationsData.fromJson(Map<String, dynamic> json) {
    return RecommendationsData(
      recommendations: List<String>.from(json['recommendations'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
    );
  }
}

class SmartAlertData {
  final String level;
  final String message;
  final String icon;
  final String color;

  SmartAlertData({
    required this.level,
    required this.message,
    required this.icon,
    required this.color,
  });

  factory SmartAlertData.fromJson(Map<String, dynamic> json) {
    return SmartAlertData(
      level: json['level']?.toString() ?? 'Safe',
      message: json['message']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
    );
  }
}

class PredictiveSummaryData {
  final int stabilityScore;
  final int failureProbability;
  final String trend;
  final String trendDirection;
  final SmartAlertData smartAlert;

  PredictiveSummaryData({
    required this.stabilityScore,
    required this.failureProbability,
    required this.trend,
    required this.trendDirection,
    required this.smartAlert,
  });

  factory PredictiveSummaryData.fromJson(Map<String, dynamic> json) {
    return PredictiveSummaryData(
      stabilityScore: (json['stabilityScore'] as num?)?.toInt() ?? 0,
      failureProbability: (json['failureProbability'] as num?)?.toInt() ?? 0,
      trend: json['trend']?.toString() ?? 'Stable',
      trendDirection: json['trendDirection']?.toString() ?? 'stable',
      smartAlert: SmartAlertData.fromJson(json['smartAlert'] ?? {}),
    );
  }
}

class OverviewData {
  final String riskLevel;
  final int attendance;
  final int internalMarks;
  final int assignmentScore;
  final int lmsEngagement;
  final PredictiveSummaryData predictiveSummary;

  OverviewData({
    required this.riskLevel,
    required this.attendance,
    required this.internalMarks,
    required this.assignmentScore,
    required this.lmsEngagement,
    required this.predictiveSummary,
  });

  factory OverviewData.fromJson(Map<String, dynamic> json) {
    return OverviewData(
      riskLevel: json['riskLevel']?.toString() ?? 'Unknown',
      attendance: (json['attendance'] as num?)?.toInt() ?? 0,
      internalMarks: (json['internalMarks'] as num?)?.toInt() ?? 0,
      assignmentScore: (json['assignmentScore'] as num?)?.toInt() ?? 0,
      lmsEngagement: (json['lmsEngagement'] as num?)?.toInt() ?? 0,
      predictiveSummary: PredictiveSummaryData.fromJson(json['predictiveSummary'] ?? {}),
    );
  }
}

class CouncilDecisionData {
  final String priorityFocusArea;
  final String urgency;       // mapped from urgencyLevel
  final String summary;       // mapped from overallSummary
  final String recommendedAction;
  final String riskSentence;

  CouncilDecisionData({
    required this.priorityFocusArea,
    required this.urgency,
    required this.summary,
    required this.recommendedAction,
    required this.riskSentence,
  });

  factory CouncilDecisionData.fromJson(Map<String, dynamic> json) {
    var council = json['councilDecision'] ?? json;
    return CouncilDecisionData(
      priorityFocusArea: council['priorityFocusArea']?.toString() ?? '',
      urgency: council['urgencyLevel']?.toString() ?? council['urgency']?.toString() ?? 'Low',
      summary: council['overallSummary']?.toString() ?? council['summary']?.toString() ?? '',
      recommendedAction: council['recommendedAction']?.toString() ?? '',
      riskSentence: council['riskSentence']?.toString() ?? '',
    );
  }
}

class LearningStep {
  final String title;
  final String description;
  final String content; // Theory or detailed data
  final String status; // 'completed', 'in-progress', 'locked'
  final int courseIndex;
  final int stepIndex;
  final String quizStatus; // 'passed', 'cooldown', 'unlocked', 'not_generated'
  final String? quizId;

  LearningStep({
    required this.title,
    required this.description,
    required this.content,
    required this.status,
    required this.courseIndex,
    required this.stepIndex,
    required this.quizStatus,
    this.quizId,
  });

  factory LearningStep.fromJson(Map<String, dynamic> json) {
    return LearningStep(
      title: json['title'] ?? 'Untitled Step',
      description: json['description'] ?? '',
      content: json['content'] ?? json['theory'] ?? 'Detailed theory and learning materials for this step will appear here. Mastering this concept is key to progressing further in your roadmap.',
      status: json['status'] ?? 'locked',
      courseIndex: json['courseIndex'] ?? 0,
      stepIndex: json['stepIndex'] ?? 0,
      quizStatus: json['quizStatus'] ?? 'not_generated',
      quizId: json['quizId'],
    );
  }
}

class LearningPath {
  final String id;
  final String title;
  final String description;
  final int progress;
  final List<LearningStep> steps;

  LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.steps,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    int completedCount = json['completedSteps'] ?? 0;
    
    // 1. Flatten all steps from all courses into a single list of raw maps
    List<Map<String, dynamic>> headers = [];
    if (json['courses'] != null) {
      for (int cIdx = 0; cIdx < json['courses'].length; cIdx++) {
        final course = json['courses'][cIdx];
        if (course['steps'] != null) {
          for (int sIdx = 0; sIdx < course['steps'].length; sIdx++) {
            final step = Map<String, dynamic>.from(course['steps'][sIdx]);
            step['courseIndex'] = cIdx;
            step['stepIndex'] = sIdx;
            step['courseStatus'] = course['status'];
            headers.add(step);
          }
        }
      }
    } else if (json['steps'] != null) {
      for (int sIdx = 0; sIdx < json['steps'].length; sIdx++) {
        final step = Map<String, dynamic>.from(json['steps'][sIdx]);
        step['courseIndex'] = 0;
        step['stepIndex'] = sIdx;
        headers.add(step);
      }
    }

    // 2. Map raw data to LearningStep objects with calculated status
    List<LearningStep> parsedSteps = [];
    for (int i = 0; i < headers.length; i++) {
       String derivedStatus;
       final courseStatus = headers[i]['courseStatus']?.toString();
       if (headers[i]['quizStatus'] == 'passed') {
         derivedStatus = 'completed';
       } else if (courseStatus == 'locked') {
         derivedStatus = 'locked';
       } else if (i < completedCount) {
         derivedStatus = 'completed';
       } else if (i == completedCount) {
         derivedStatus = 'in-progress';
       } else {
         derivedStatus = 'locked';
       }

       parsedSteps.add(LearningStep(
         title: headers[i]['title'] ?? 'Untitled Step',
         description: headers[i]['description'] ?? '',
         content: headers[i]['content'] ?? headers[i]['theory'] ?? 'Overview of ${headers[i]['title']}: \n\nThis module covers the fundamental concepts and practical applications. Read through the provided materials and complete the exercises to verify your understanding.',
         status: derivedStatus,
         courseIndex: headers[i]['courseIndex'] ?? 0,
         stepIndex: headers[i]['stepIndex'] ?? 0,
         quizStatus: headers[i]['quizStatus'] ?? 'not_generated',
         quizId: headers[i]['quizId'],
       ));
    }

    // Calculate progress based on total steps in the roadmap
    int calculatedProgress = json['progress'] ?? 0;
    if (headers.isNotEmpty) {
      calculatedProgress = ((completedCount / headers.length) * 100).round();
    }

    return LearningPath(
      id: json['_id'] ?? '',
      title: json['topic'] ?? 'General Path',
      description: json['description'] ?? 'Your personalized roadmap',
      progress: calculatedProgress,
      steps: parsedSteps,
    );
  }
}

class InterventionAction {
  final String id;
  final String title;
  final String description;
  final String status;

  InterventionAction({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  factory InterventionAction.fromJson(Map<String, dynamic> json) {
    // Map 'type' to title if title is missing, and handle description
    String displayTitle = json['title'] ?? json['type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION';
    
    return InterventionAction(
      id: json['_id'] ?? json['id'] ?? '',
      title: displayTitle,
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class InterventionData {
  final bool interventionRequired;
  final String priority;
  final String owner;
  final List<InterventionAction> actions;
  final int daysUntilReview;
  final int pendingActions;

  InterventionData({
    required this.interventionRequired,
    required this.priority,
    required this.owner,
    required this.actions,
    required this.daysUntilReview,
    required this.pendingActions,
  });

  factory InterventionData.fromJson(Map<String, dynamic> json) {
    return InterventionData(
      interventionRequired: json['interventionRequired'] ?? false,
      priority: json['priority'] ?? 'Low',
      owner: json['owner'] ?? 'Unknown',
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => InterventionAction.fromJson(e))
              .toList() ??
          [],
      daysUntilReview: json['daysUntilReview'] ?? 0,
      pendingActions: json['pendingActions'] ?? 0,
    );
  }
}
