import '../../domain/entities/juror_entity.dart';

class JurorModel extends JurorEntity {
  const JurorModel({
    required super.id,
    required super.userId,
    required super.dni,
    required super.username,
    required super.firstName,
    required super.lastName,
    super.specialty,
  });

  factory JurorModel.fromJson(Map<String, dynamic> json) {
    return JurorModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      dni: json['dni'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      specialty: json['specialty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dni': dni,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'specialty': specialty,
    };
  }

  JurorEntity toEntity() {
    return JurorEntity(
      id: id,
      userId: userId,
      dni: dni,
      username: username,
      firstName: firstName,
      lastName: lastName,
      specialty: specialty,
    );
  }
}