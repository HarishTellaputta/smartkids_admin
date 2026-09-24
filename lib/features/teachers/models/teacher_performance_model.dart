class TeacherPerformance {
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final String? subjectCode;
  final int latestExamScheduleId;
  final String latestExamName;
  final String examDate;
  final int studentCount;
  final int assessedCount;
  final double averageMarks;
  final int maxMarks;
  final double performancePercentage;

  TeacherPerformance({
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    required this.latestExamScheduleId,
    required this.latestExamName,
    required this.examDate,
    required this.studentCount,
    required this.assessedCount,
    required this.averageMarks,
    required this.maxMarks,
    required this.performancePercentage,
  });

  factory TeacherPerformance.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherPerformance(
      classId: json['classId'] ?? 0,
      className: json['className'] ?? '-',
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '-',
      subjectCode: json['subjectCode'],
      latestExamScheduleId:
          json['latestExamScheduleId'] ?? 0,
      latestExamName:
          json['latestExamName'] ?? '-',
      examDate:
          json['examDate'] ?? '-',
      studentCount:
          json['studentCount'] ?? 0,
      assessedCount:
          json['assessedCount'] ?? 0,
      averageMarks:
          (json['averageMarks'] ?? 0).toDouble(),
      maxMarks:
          json['maxMarks'] ?? 0,
      performancePercentage:
          (json['performancePercentage'] ?? 0).toDouble(),
    );
  }
}