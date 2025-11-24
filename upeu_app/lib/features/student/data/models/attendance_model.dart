class AttendanceModel {
  final int id;
  final ArticleBasicInfo article;
  final PonenteBasicInfo ponente;
  final String attendedAt;

  AttendanceModel({
    required this.id,
    required this.article,
    required this.ponente,
    required this.attendedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      article: ArticleBasicInfo.fromJson(json['article']),
      ponente: PonenteBasicInfo.fromJson(json['ponente']),
      attendedAt: json['attended_at'],
    );
  }
}

class ArticleBasicInfo {
  final int id;
  final String title;
  final String type;
  final String? presentationDate;
  final String? presentationTime;

  ArticleBasicInfo({
    required this.id,
    required this.title,
    required this.type,
    this.presentationDate,
    this.presentationTime,
  });

  factory ArticleBasicInfo.fromJson(Map<String, dynamic> json) {
    return ArticleBasicInfo(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      presentationDate: json['presentation_date'],
      presentationTime: json['presentation_time'],
    );
  }
}

class PonenteBasicInfo {
  final String fullName;
  final String studentCode;

  PonenteBasicInfo({
    required this.fullName,
    required this.studentCode,
  });

  factory PonenteBasicInfo.fromJson(Map<String, dynamic> json) {
    return PonenteBasicInfo(
      fullName: json['full_name'],
      studentCode: json['student_code'],
    );
  }
}