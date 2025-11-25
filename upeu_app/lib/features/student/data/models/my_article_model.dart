class MyArticleModel {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String? presentationDate;
  final String? presentationTime;
  final String? shift;
  final List<JurorBasicInfo> jurors;
  final List<EvaluationDetail> evaluations;
  final int totalEvaluations;
  final double averageScore;
  final int totalAttendances;
  final CriteriaAverages criteriaAverages;

  MyArticleModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.presentationDate,
    this.presentationTime,
    this.shift,
    required this.jurors,
    required this.evaluations,
    required this.totalEvaluations,
    required this.averageScore,
    required this.totalAttendances,
    required this.criteriaAverages,
  });

  factory MyArticleModel.fromJson(Map<String, dynamic> json) {
    return MyArticleModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      presentationDate: json['presentation_date'],
      presentationTime: json['presentation_time'],
      shift: json['shift'],
      jurors: (json['jurors'] as List)
          .map((j) => JurorBasicInfo.fromJson(j))
          .toList(),
      evaluations: (json['evaluations'] as List)
          .map((e) => EvaluationDetail.fromJson(e))
          .toList(),
      totalEvaluations: json['total_evaluations'],
      // ✅ FIX: Parsear desde String o double
      averageScore: _parseDouble(json['average_score']),
      totalAttendances: json['total_attendances'],
      criteriaAverages: CriteriaAverages.fromJson(json['criteria_averages']),
    );
  }

  // ✅ HELPER PARA PARSEAR DOUBLE
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class JurorBasicInfo {
  final int id;
  final String fullName;
  final String? specialty;

  JurorBasicInfo({
    required this.id,
    required this.fullName,
    this.specialty,
  });

  factory JurorBasicInfo.fromJson(Map<String, dynamic> json) {
    return JurorBasicInfo(
      id: json['id'],
      fullName: json['full_name'],
      specialty: json['specialty'],
    );
  }
}

class EvaluationDetail {
  final String juror;
  final String? jurorSpecialty;
  final double introduccion;
  final double metodologia;
  final double desarrollo;
  final double conclusiones;
  final double presentacion;
  final double promedio;
  final String? comentarios;
  final String evaluatedAt;

  EvaluationDetail({
    required this.juror,
    this.jurorSpecialty,
    required this.introduccion,
    required this.metodologia,
    required this.desarrollo,
    required this.conclusiones,
    required this.presentacion,
    required this.promedio,
    this.comentarios,
    required this.evaluatedAt,
  });

  factory EvaluationDetail.fromJson(Map<String, dynamic> json) {
    return EvaluationDetail(
      juror: json['juror'],
      jurorSpecialty: json['juror_specialty'],
      // ✅ FIX: Parsear desde String
      introduccion: _parseDouble(json['introduccion']),
      metodologia: _parseDouble(json['metodologia']),
      desarrollo: _parseDouble(json['desarrollo']),
      conclusiones: _parseDouble(json['conclusiones']),
      presentacion: _parseDouble(json['presentacion']),
      promedio: _parseDouble(json['promedio']),
      comentarios: json['comentarios'],
      evaluatedAt: json['evaluated_at'],
    );
  }

  // ✅ HELPER PARA PARSEAR DOUBLE
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CriteriaAverages {
  final double introduccion;
  final double metodologia;
  final double desarrollo;
  final double conclusiones;
  final double presentacion;

  CriteriaAverages({
    required this.introduccion,
    required this.metodologia,
    required this.desarrollo,
    required this.conclusiones,
    required this.presentacion,
  });

  factory CriteriaAverages.fromJson(Map<String, dynamic> json) {
    return CriteriaAverages(
      // ✅ FIX: Parsear desde String
      introduccion: _parseDouble(json['introduccion']),
      metodologia: _parseDouble(json['metodologia']),
      desarrollo: _parseDouble(json['desarrollo']),
      conclusiones: _parseDouble(json['conclusiones']),
      presentacion: _parseDouble(json['presentacion']),
    );
  }

  // ✅ HELPER PARA PARSEAR DOUBLE
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}