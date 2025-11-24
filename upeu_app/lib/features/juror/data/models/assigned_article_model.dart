class AssignedArticleModel {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String? presentationDate;
  final String? presentationTime;
  final String? shift;
  final StudentInfo student;
  final bool isEvaluated;
  final EvaluationInfo? myEvaluation;

  AssignedArticleModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.presentationDate,
    this.presentationTime,
    this.shift,
    required this.student,
    required this.isEvaluated,
    this.myEvaluation,
  });

  factory AssignedArticleModel.fromJson(Map<String, dynamic> json) {
    return AssignedArticleModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      presentationDate: json['presentation_date'] as String?,
      presentationTime: json['presentation_time'] as String?,
      shift: json['shift'] as String?,
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      isEvaluated: json['is_evaluated'] as bool? ?? false,
      myEvaluation: json['my_evaluation'] != null
          ? EvaluationInfo.fromJson(json['my_evaluation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudentInfo {
  final int id;
  final String fullName;
  final String dni;

  StudentInfo({
    required this.id,
    required this.fullName,
    required this.dni,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      dni: json['dni'] as String,
    );
  }
}

class EvaluationInfo {
  final int id;
  final double introduccion;
  final double metodologia;
  final double desarrollo;
  final double conclusiones;
  final double presentacion;
  final double promedio;
  final String? comentarios;
  final String createdAt;

  EvaluationInfo({
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

  factory EvaluationInfo.fromJson(Map<String, dynamic> json) {
    return EvaluationInfo(
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