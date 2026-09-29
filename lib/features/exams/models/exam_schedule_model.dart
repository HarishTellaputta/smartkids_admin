class ExamScheduleModel {
  final int? id;

  final int? examinationId;
  final String examinationName;

  final int? classId;
  final String className;

  final int? sectionId;
  final String sectionName;

  final int? subjectId;
  final String subjectName;
  final String subjectCode;

  final int? subjectTeacherId;
  final String subjectTeacherName;

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
    this.examinationName = '',
    this.classId,
    this.className = '',
    this.sectionId,
    this.sectionName = '',
    this.subjectId,
    this.subjectName = '',
    this.subjectCode = '',
    this.subjectTeacherId,
    this.subjectTeacherName = '',
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
      examinationName: json['examinationName']?.toString() ?? '',

      classId: _toInt(json['classId']),
      className: json['className']?.toString() ?? '',

      sectionId: _toInt(json['sectionId']),
      sectionName: json['sectionName']?.toString() ?? '',

      subjectId: _toInt(json['subjectId']),
      subjectName: json['subjectName']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',

      subjectTeacherId: _toInt(json['subjectTeacherId']),
      subjectTeacherName:
          json['subjectTeacherName']?.toString() ?? '',

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