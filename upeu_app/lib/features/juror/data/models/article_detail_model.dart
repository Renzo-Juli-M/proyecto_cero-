class ArticleDetailModel {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String? presentationDate;
  final String? presentationTime;
  final String? shift;
  final StudentDetailInfo student;
  final List<JurorInfo> assignedJurors;
  final EvaluationDetailInfo? myEvaluation;
  final List<OtherEvaluationInfo> otherEvaluations;
  final int totalEvaluations;
  final double averageScore;

  ArticleDetailModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.presentationDate,
    this.presentationTime,
    this.shift,
    required this.student,
    required this.assignedJurors,
    this.myEvaluation,
    required this.otherEvaluations,
    required this.totalEvaluations,
    required this.averageScore,
  });

  factory ArticleDetailModel.fromJson(Map<String, dynamic> json) {
    return ArticleDetailModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      presentationDate: json['presentation_date'] as String?,
      presentationTime: json['presentation_time'] as String?,
      shift: json['shift'] as String?,
      student: StudentDetailInfo.fromJson(json['student'] as Map<String, dynamic>),
      assignedJurors: (json['assigned_jurors'] as List)
          .map((j) => JurorInfo.fromJson(j as Map<String, dynamic>))
          .toList(),
      myEvaluation: json['my_evaluation'] != null
          ? EvaluationDetailInfo.fromJson(json['my_evaluation'] as Map<String, dynamic>)
          : null,
      otherEvaluations: (json['other_evaluations'] as List)
          .map((e) => OtherEvaluationInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEvaluations: json['total_evaluations'] as int,
      averageScore: (json['average_score'] as num).toDouble(),
    );
  }

  bool get isEvaluated => myEvaluation != null;
}

class StudentDetailInfo {
  final int id;
  final String fullName;
  final String studentCode;
  final String dni;

  StudentDetailInfo({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.dni,
  });

  factory StudentDetailInfo.fromJson(Map<String, dynamic> json) {
    return StudentDetailInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      studentCode: json['student_code'] as String,
      dni: json['dni'] as String,
    );
  }
}

class JurorInfo {
  final int id;
  final String fullName;
  final String? specialty;

  JurorInfo({
    required this.id,
    required this.fullName,
    this.specialty,
  });

  factory JurorInfo.fromJson(Map<String, dynamic> json) {
    return JurorInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      specialty: json['specialty'] as String?,
    );
  }
}

class EvaluationDetailInfo {
  final int id;
  final double introduccion;
  final double metodologia;
  final double desarrollo;
  final double conclusiones;
  final double presentacion;
  final double promedio;
  final String? comentarios;
  final String createdAt;

  EvaluationDetailInfo({
    required this.id,
    required this.introduccion,
    required this.metodologia,
    required this.desarrollo,
    required this.conclusiones,
    required this.presentacion,
    required this.promedio,
    this.comentarios,
    required this.createdAt,
  });

  factory EvaluationDetailInfo.fromJson(Map<String, dynamic> json) {
    return EvaluationDetailInfo(
      id: json['id'] as int,
      introduccion: (json['introduccion'] as num).toDouble(),
      metodologia: (json['metodologia'] as num).toDouble(),
      desarrollo: (json['desarrollo'] as num).toDouble(),
      conclusiones: (json['conclusiones'] as num).toDouble(),
      presentacion: (json['presentacion'] as num).toDouble(),
      promedio: (json['promedio'] as num).toDouble(),
      comentarios: json['comentarios'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class OtherEvaluationInfo {
  final String jurorName;
  final double promedio;
  final String evaluatedAt;

  OtherEvaluationInfo({
    required this.jurorName,
    required this.promedio,
    required this.evaluatedAt,
  });

  factory OtherEvaluationInfo.fromJson(Map<String, dynamic> json) {
    return OtherEvaluationInfo(
      jurorName: json['juror_name'] as String,
      promedio: (json['promedio'] as num).toDouble(),
      evaluatedAt: json['evaluated_at'] as String,
    );
  }
}