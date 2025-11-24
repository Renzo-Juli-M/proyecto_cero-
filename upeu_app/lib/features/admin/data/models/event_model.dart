class EventModel {
  final int id;
  final int periodId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final bool isActive;
  final String? periodName;
  final int? studentsCount;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.periodId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    required this.isActive,
    this.periodName,
    this.studentsCount,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      periodId: json['period_id'],
      name: json['name'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      location: json['location'],
      isActive: json['is_active'] ?? true,
      periodName: json['period'] != null ? json['period']['name'] : null,
      studentsCount: json['students_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_id': periodId,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'location': location,
      'is_active': isActive,
    };
  }

  String get dateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }

  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }
}