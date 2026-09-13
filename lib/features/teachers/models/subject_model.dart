class SubjectModel {
  final int id;
  final int schoolId;
  final String name;
  final String code;
  final String? description;
  final String? status;

  SubjectModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    this.description,
    this.status,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? 0,
      schoolId: json['schoolId'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'name': name,
      'code': code,
      'description': description,
      'status': status,
    };
  }
}