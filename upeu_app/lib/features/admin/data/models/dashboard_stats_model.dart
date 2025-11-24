class DashboardStatsModel {
  final int totalStudents;
  final int totalPonentes;
  final int totalOyentes;
  final int totalJurors;
  final int totalArticles;
  final int totalEvaluations;
  final int totalAttendances;

  DashboardStatsModel({
    required this.totalStudents,
    required this.totalPonentes,
    required this.totalOyentes,
    required this.totalJurors,
    required this.totalArticles,
    required this.totalEvaluations,
    required this.totalAttendances,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalStudents: json['total_students'] ?? 0,
      totalPonentes: json['total_ponentes'] ?? 0,
      totalOyentes: json['total_oyentes'] ?? 0,
      totalJurors: json['total_jurors'] ?? 0,
      totalArticles: json['total_articles'] ?? 0,
      totalEvaluations: json['total_evaluations'] ?? 0,
      totalAttendances: json['total_attendances'] ?? 0,
    );
  }
}