class JurorStatsModel {
  final int totalArticlesAssigned;
  final int totalEvaluationsDone;
  final int pendingEvaluations;
  final double averageScoreGiven;

  JurorStatsModel({
    required this.totalArticlesAssigned,
    required this.totalEvaluationsDone,
    required this.pendingEvaluations,
    required this.averageScoreGiven,
  });

  factory JurorStatsModel.fromJson(Map<String, dynamic> json) {
    return JurorStatsModel(
      totalArticlesAssigned: json['total_articles_assigned'] ?? 0,
      totalEvaluationsDone: json['total_evaluations_done'] ?? 0,
      pendingEvaluations: json['pending_evaluations'] ?? 0,
      averageScoreGiven: (json['average_score_given'] ?? 0).toDouble(),
    );
  }
}