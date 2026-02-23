class ResumeAnalysisResponse {
  final String status;
  final ResumeAnalysisData? data;
  final String? message;

  ResumeAnalysisResponse({
    required this.status,
    this.data,
    this.message,
  });

  factory ResumeAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysisResponse(
      status: json['status'] ?? 'unknown',
      message: json['message'],
      data: json['data'] != null ? ResumeAnalysisData.fromJson(json['data']) : null,
    );
  }
}

class ResumeAnalysisData {
  final String analysisId;
  final int atsScore;
  final String overallRating;
  final AnalysisDetails analysis;
  final AnalysisSummary summary;

  ResumeAnalysisData({
    required this.analysisId,
    required this.atsScore,
    required this.overallRating,
    required this.analysis,
    required this.summary,
  });

  factory ResumeAnalysisData.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysisData(
      analysisId: json['analysisId'] ?? '',
      atsScore: json['atsScore'] is int ? json['atsScore'] : int.tryParse(json['atsScore']?.toString() ?? '0') ?? 0,
      overallRating: json['overallRating'] ?? 'N/A',
      analysis: AnalysisDetails.fromJson(json['analysis'] ?? {}),
      summary: AnalysisSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class AnalysisDetails {
  final List<String> mainStrengths;
  final List<String> criticalImprovements;
  final List<String> missingOrSuggestedSkills;
  final List<String> keywordOptimization;
  final List<String> formattingAndStructureAdvice;

  AnalysisDetails({
    required this.mainStrengths,
    required this.criticalImprovements,
    required this.missingOrSuggestedSkills,
    required this.keywordOptimization,
    required this.formattingAndStructureAdvice,
  });

  factory AnalysisDetails.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic list) {
      if (list == null) return [];
      if (list is List) return list.map((e) => e.toString()).toList();
      return [];
    }

    return AnalysisDetails(
      mainStrengths: parseList(json['mainStrengths']),
      criticalImprovements: parseList(json['criticalImprovements']),
      missingOrSuggestedSkills: parseList(json['missingOrSuggestedSkills']),
      keywordOptimization: parseList(json['keywordOptimization']),
      formattingAndStructureAdvice: parseList(json['formattingAndStructureAdvice']),
    );
  }
}

class AnalysisSummary {
  final int strengthsCount;
  final int improvementsCount;
  final int skillsSuggested;

  AnalysisSummary({
    required this.strengthsCount,
    required this.improvementsCount,
    required this.skillsSuggested,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      strengthsCount: json['strengthsCount'] ?? 0,
      improvementsCount: json['improvementsCount'] ?? 0,
      skillsSuggested: json['skillsSuggested'] ?? 0,
    );
  }
}
