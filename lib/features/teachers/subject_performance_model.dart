
class SubjectPerformanceModel {
  final int classId;
  final String className;

  final int? sectionId;
  final String sectionName;

  final int subjectId;
  final String subjectName;
  final String subjectCode;

  final int examScheduleId;
  final String examName;
  final DateTime? examDate;

  final int studentCount;
  final int assessedCount;

  final double averageMarks;
  final int maxMarks;

  final double performancePercentage;

  SubjectPerformanceModel({
    required this.classId,
    required this.className,
    this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.examScheduleId,
    required this.examName,
    required this.examDate,
    required this.studentCount,
    required this.assessedCount,
    required this.averageMarks,
    required this.maxMarks,
    required this.performancePercentage,
  });

  factory SubjectPerformanceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubjectPerformanceModel(
      classId: json['classId'] ?? 0,
      className: json['className'] ?? '',

      sectionId: json['sectionId'],
      sectionName: json['sectionName'] ?? 'All Sections',

      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',

      examScheduleId: json['examScheduleId'] ?? 0,
      examName: json['examName'] ?? '',

      examDate: json['examDate'] != null
          ? DateTime.tryParse(json['examDate'].toString())
          : null,

      studentCount: json['studentCount'] ?? 0,
      assessedCount: json['assessedCount'] ?? 0,

      averageMarks:
          (json['averageMarks'] ?? 0).toDouble(),

      maxMarks: json['maxMarks'] ?? 0,

      performancePercentage:
          (json['performancePercentage'] ?? 0).toDouble(),
    );
  }
}

