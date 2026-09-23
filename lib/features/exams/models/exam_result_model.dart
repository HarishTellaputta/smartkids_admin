
class ExamResultResponseModel {
  final int id;
  final int examScheduleId;
  final int studentId;
  final String? studentName;
  final String? studentRollNumber;
  final int? markedByTeacherId;
  final String? markedByTeacherName;
  final int marksObtained;
  final int maxMarks;
  final double? percentage;
  final String? grade;
  final int? classRank;
  final int? sectionRank;
  final String? remarks;
  final String? status;
  final bool isPublished;
  final DateTime? markedAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamResultResponseModel({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    this.studentName,
    this.studentRollNumber,
    this.markedByTeacherId,
    this.markedByTeacherName,
    required this.marksObtained,
    required this.maxMarks,
    this.percentage,
    this.grade,
    this.classRank,
    this.sectionRank,
    this.remarks,
    this.status,
    required this.isPublished,
    this.markedAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamResultResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExamResultResponseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,

      examScheduleId:
          (json['examScheduleId'] as num?)?.toInt() ?? 0,

      studentId:
          (json['studentId'] as num?)?.toInt() ?? 0,

      studentName:
          json['studentName']?.toString(),

      studentRollNumber:
          json['studentRollNumber']?.toString(),

      markedByTeacherId:
          (json['markedByTeacherId'] as num?)?.toInt(),

      markedByTeacherName:
          json['markedByTeacherName']?.toString(),

      marksObtained:
          (json['marksObtained'] as num?)?.toInt() ?? 0,

      maxMarks:
          (json['maxMarks'] as num?)?.toInt() ?? 0,

      percentage:
          (json['percentage'] as num?)?.toDouble(),

      grade:
          json['grade']?.toString(),

      classRank:
          (json['classRank'] as num?)?.toInt(),

      sectionRank:
          (json['sectionRank'] as num?)?.toInt(),

      remarks:
          json['remarks']?.toString(),

      status:
          json['status']?.toString(),

      isPublished:
          json['isPublished'] == true,

      markedAt: json['markedAt'] != null
          ? DateTime.tryParse(
              json['markedAt'].toString(),
            )
          : null,

      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(
              json['publishedAt'].toString(),
            )
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(
              json['updatedAt'].toString(),
            )
          : null,
    );
  }
}

