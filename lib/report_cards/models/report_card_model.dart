class ReportCardSubjectModel {
  final int? scheduleId;
  final String subject;
  final String? examDate;
  final int? marksObtained;
  final int? maximumMarks;
  final double? percentage;
  final String? grade;

  ReportCardSubjectModel({
    this.scheduleId,
    required this.subject,
    this.examDate,
    this.marksObtained,
    this.maximumMarks,
    this.percentage,
    this.grade,
  });

  factory ReportCardSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReportCardSubjectModel(
      scheduleId: _toInt(json['scheduleId']),
      subject: json['subject']?.toString() ?? '',
      examDate: json['examDate']?.toString(),
      marksObtained: _toInt(json['marksObtained']),
      maximumMarks: _toInt(json['maximumMarks']),
      percentage: _toDouble(json['percentage']),
      grade: json['grade']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'subject': subject,
      'examDate': examDate,
      'marksObtained': marksObtained,
      'maximumMarks': maximumMarks,
      'percentage': percentage,
      'grade': grade,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

// ============================================================
// REPORT CARD
// ============================================================

class ReportCardModel {
  final int? studentId;
  final String studentName;
  final String? rollNumber;

  final int? classId;
  final String? className;

  final int? sectionId;
  final String? sectionName;

  final int? examinationId;
  final String? examinationName;

  final List<ReportCardSubjectModel> subjects;

  final int? totalMarks;
  final int? totalMaximumMarks;
  final double? percentage;
  final String? grade;
  final int? rank;

  final int? attendancePresent;
  final int? attendanceTotal;
  final double? attendancePercentage;

  final String? overallResult;

  ReportCardModel({
    this.studentId,
    required this.studentName,
    this.rollNumber,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.examinationId,
    this.examinationName,
    required this.subjects,
    this.totalMarks,
    this.totalMaximumMarks,
    this.percentage,
    this.grade,
    this.rank,
    this.attendancePresent,
    this.attendanceTotal,
    this.attendancePercentage,
    this.overallResult,
  });

  factory ReportCardModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final subjectsJson = json['subjects'];

    final subjects = <ReportCardSubjectModel>[];

    if (subjectsJson is List) {
      for (final item in subjectsJson) {
        if (item is Map) {
          subjects.add(
            ReportCardSubjectModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return ReportCardModel(
      studentId: _toInt(json['studentId']),
      studentName: json['studentName']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString(),

      classId: _toInt(json['classId']),
      className: json['className']?.toString(),

      sectionId: _toInt(json['sectionId']),
      sectionName: json['sectionName']?.toString(),

      examinationId: _toInt(json['examinationId']),
      examinationName: json['examinationName']?.toString(),

      subjects: subjects,

      totalMarks: _toInt(json['totalMarks']),
      totalMaximumMarks: _toInt(json['totalMaximumMarks']),
      percentage: _toDouble(json['percentage']),
      grade: json['grade']?.toString(),
      rank: _toInt(json['rank']),

      attendancePresent: _toInt(json['attendancePresent']),
      attendanceTotal: _toInt(json['attendanceTotal']),
      attendancePercentage: _toDouble(
        json['attendancePercentage'],
      ),

      overallResult: json['overallResult']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'examinationId': examinationId,
      'examinationName': examinationName,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'totalMarks': totalMarks,
      'totalMaximumMarks': totalMaximumMarks,
      'percentage': percentage,
      'grade': grade,
      'rank': rank,
      'attendancePresent': attendancePresent,
      'attendanceTotal': attendanceTotal,
      'attendancePercentage': attendancePercentage,
      'overallResult': overallResult,
    };
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}