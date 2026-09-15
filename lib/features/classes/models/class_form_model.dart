class ClassFormModel {
  final int id;
  final int schoolId;
  final String? schoolName;
  final String name;
  final String code;
  final String grade;
  final int year;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Subject IDs selected in Add/Edit Class
  final List<int> subjectIds;

  ClassFormModel({
    required this.id,
    required this.schoolId,
    this.schoolName,
    required this.name,
    required this.code,
    required this.grade,
    required this.year,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.subjectIds = const [],
  });

  factory ClassFormModel.fromJson(Map<String, dynamic> json) {
    return ClassFormModel(
      id: json['id'] ?? 0,
      schoolId: json['schoolId'] ?? 0,
      schoolName: json['schoolName'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      grade: json['grade'] ?? '',
      year: json['year'] ?? 0,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      subjectIds: json['subjectIds'] is List
          ? (json['subjectIds'] as List)
                .map((e) => int.tryParse(e.toString()))
                .whereType<int>()
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'name': name,
      'code': code,
      'grade': grade,
      'year': year,
      'description': description,
      'subjectIds': subjectIds,
    };
  }
}
