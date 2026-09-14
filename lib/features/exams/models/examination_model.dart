class ExaminationModel {
  final int? id;
  final int? academicYearId;
  final String name;
  final String description;
  final String examType;
  final int year;
  final String status;

  ExaminationModel({
    this.id,
    this.academicYearId,
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
    String? name,
    String? description,
    String? examType,
    int? year,
    String? status,
  }) {
    return ExaminationModel(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
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

class ExamScheduleModel {
  final int? id;
  final int? examinationId;
  final int? classId;
  final int? sectionId;
  final int? subjectTeacherId;

  final String subject;
  final String examDate;
  final String startTime;
  final int duration;
  final int maxMarks;
  final String examType;
  final String roomNumber;
  final String status;

  ExamScheduleModel({
    this.id,
    this.examinationId,
    this.classId,
    this.sectionId,
    this.subjectTeacherId,
    required this.subject,
    required this.examDate,
    required this.startTime,
    required this.duration,
    required this.maxMarks,
    required this.examType,
    required this.roomNumber,
    required this.status,
  });

  factory ExamScheduleModel.fromJson(Map<String, dynamic> json) {
    return ExamScheduleModel(
      id: _toInt(json['id']),
      examinationId: _toInt(json['examinationId']),
      classId: _toInt(json['classId']),
      sectionId: _toInt(json['sectionId']),
      subjectTeacherId: _toInt(json['subjectTeacherId']),
      subject: json['subject']?.toString() ?? '',
      examDate: json['examDate']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      duration: _toInt(json['duration']) ?? 0,
      maxMarks: _toInt(json['maxMarks']) ?? 0,
      examType: json['examType']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}
