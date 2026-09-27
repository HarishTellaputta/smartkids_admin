class AcademicPerformanceModel {
  final int? id;
  final int? studentId;
  final String? studentName;
  final int? scheduleId;
  final String? subjectName;
  final String? examinationName;
  final int? marksObtained;
  final int? maxMarks;
  final double? percentage;
  final String? grade;
  final int? classRank;
  final int? sectionRank;
  final String? status;
  final bool? isPublished;

  AcademicPerformanceModel({
    this.id,
    this.studentId,
    this.studentName,
    this.scheduleId,
    this.subjectName,
    this.examinationName,
    this.marksObtained,
    this.maxMarks,
    this.percentage,
    this.grade,
    this.classRank,
    this.sectionRank,
    this.status,
    this.isPublished,
  });

  factory AcademicPerformanceModel.fromJson(
      Map<String, dynamic> json) {
    final student =
        json['student'] as Map<String, dynamic>?;
    final schedule =
        json['examSchedule'] as Map<String, dynamic>?;

    final examination =
        schedule?['examination'] as Map<String, dynamic>?;
    final subject =
        schedule?['subject'] as Map<String, dynamic>?;

    return AcademicPerformanceModel(
      id: json['id'],
      studentId: json['studentId'] ?? student?['id'],
      studentName: json['studentName'] ??
          student?['name'] ??
          student?['fullName'],
      scheduleId:
          json['scheduleId'] ?? schedule?['id'],
      subjectName:
          json['subjectName'] ?? subject?['name'],
      examinationName:
          json['examinationName'] ?? examination?['name'],
      marksObtained: json['marksObtained'],
      maxMarks: json['maxMarks'] ??
          schedule?['maxMarks'],
      percentage: json['percentage'] != null
          ? double.tryParse(
              json['percentage'].toString(),
            )
          : null,
      grade: json['grade']?.toString(),
      classRank: json['classRank'],
      sectionRank: json['sectionRank'],
      status: json['status']?.toString(),
      isPublished: json['isPublished'],
    );
  }
}