class ExaminationModel {
  final int? id;
  final int? academicYearId;
  final String? academicYearName;
  final String name;
  final String description;
  final String examType;
  final int year;
  final String status;

  ExaminationModel({
    this.id,
    this.academicYearId,
    this.academicYearName,
    required this.name,
    required this.description,
    required this.examType,
    required this.year,
    required this.status,
  });

  factory ExaminationModel.fromJson(Map<String, dynamic> json) {
    return ExaminationModel(
      id: _toInt(json['id']),
      academicYearId: _toInt(json['academicYearId']),
      academicYearName: json['academicYearName']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      examType: json['examType']?.toString() ?? '',
      year: _toInt(json['year']) ?? DateTime.now().year,
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academicYearId': academicYearId,
      'name': name,
      'description': description,
      'examType': examType,
      'year': year,
      'status': status,
    };
  }

  ExaminationModel copyWith({
    int? id,
    int? academicYearId,
    String? academicYearName,
    String? name,
    String? description,
    String? examType,
    int? year,
    String? status,
  }) {
    return ExaminationModel(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      academicYearName: academicYearName ?? this.academicYearName,
      name: name ?? this.name,
      description: description ?? this.description,
      examType: examType ?? this.examType,
      year: year ?? this.year,
      status: status ?? this.status,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}