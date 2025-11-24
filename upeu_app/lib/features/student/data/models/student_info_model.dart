class StudentInfoModel {
  final int id;
  final String fullName;
  final String dni;
  final String studentCode;
  final String type;
  final String email;

  StudentInfoModel({
    required this.id,
    required this.fullName,
    required this.dni,
    required this.studentCode,
    required this.type,
    required this.email,
  });

  factory StudentInfoModel.fromJson(Map<String, dynamic> json) {
    return StudentInfoModel(
      id: json['id'],
      fullName: json['full_name'],
      dni: json['dni'],
      studentCode: json['student_code'],
      type: json['type'],
      email: json['email'],
    );
  }

  bool get isPonente => type == 'ponente';
  bool get isOyente => type == 'oyente';
}