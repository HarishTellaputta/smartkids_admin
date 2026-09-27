class ExaminationReportModel {
  final int? id;
  final int? examinationId;
  final String? examinationName;
  final int? classId;
  final String? className;
  final int? sectionId;
  final String? sectionName;
  final int? subjectId;
  final String? subjectName;
  final DateTime? examDate;
  final String? startTime;
  final int? duration;
  final int? maxMarks;
  final String? examType;
  final String? roomNumber;
  final String? status;

  ExaminationReportModel({
    this.id,
    this.examinationId,
    this.examinationName,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.subjectId,
    this.subjectName,
    this.examDate,
    this.startTime,
    this.duration,
    this.maxMarks,
    this.examType,
    this.roomNumber,
    this.status,
  });

  factory ExaminationReportModel.fromJson(Map<String, dynamic> json) {
    final examination =
        json['examination'] as Map<String, dynamic>?;
    final classEntity =
        json['classEntity'] as Map<String, dynamic>?;
    final section =
        json['section'] as Map<String, dynamic>?;
    final subject =
        json['subject'] as Map<String, dynamic>?;

    return ExaminationReportModel(
      id: json['id'],
      examinationId: json['examinationId'] ?? examination?['id'],
      examinationName: json['examinationName'] ??
          examination?['name'],
      classId: json['classId'] ?? classEntity?['id'],
      className: json['className'] ?? classEntity?['name'],
      sectionId: json['sectionId'] ?? section?['id'],
      sectionName: json['sectionName'] ?? section?['name'],
      subjectId: json['subjectId'] ?? subject?['id'],
      subjectName: json['subjectName'] ?? subject?['name'],
      examDate: json['examDate'] != null
          ? DateTime.tryParse(json['examDate'].toString())
          : null,
      startTime: json['startTime']?.toString(),
      duration: json['duration'],
      maxMarks: json['maxMarks'],
      examType: json['examType']?.toString(),
      roomNumber: json['roomNumber']?.toString(),
      status: json['status']?.toString(),
    );
  }
}