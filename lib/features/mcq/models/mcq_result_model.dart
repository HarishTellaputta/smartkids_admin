
class McqResultModel {
  final int? attemptId;
  final int? testId;

  // Student details
  final int? studentId;
  final String? studentName;
  final String? admissionNo;

  // Attempt details
  final String? status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;

  final int? score;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? wrongAnswers;
  final double? percentage;

  // Test details
  final McqTestResultModel? test;

  McqResultModel({
    this.attemptId,
    this.testId,
    this.studentId,
    this.studentName,
    this.admissionNo,
    this.status,
    this.startedAt,
    this.expiresAt,
    this.submittedAt,
    this.score,
    this.totalQuestions,
    this.correctAnswers,
    this.wrongAnswers,
    this.percentage,
    this.test,
  });

  factory McqResultModel.fromJson(Map<String, dynamic> json) {
    return McqResultModel(
      attemptId: _toInt(json['attemptId']),
      testId: _toInt(json['testId']),

      studentId: _toInt(json['studentId']),
      studentName: json['studentName']?.toString(),
      admissionNo: json['admissionNo']?.toString(),

      status: json['status']?.toString(),

      startedAt: _toDateTime(json['startedAt']),
      expiresAt: _toDateTime(json['expiresAt']),
      submittedAt: _toDateTime(json['submittedAt']),

      score: _toInt(json['score']),
      totalQuestions: _toInt(json['totalQuestions']),
      correctAnswers: _toInt(json['correctAnswers']),
      wrongAnswers: _toInt(json['wrongAnswers']),

      percentage: _toDouble(json['percentage']),

      test: json['test'] is Map<String, dynamic>
          ? McqTestResultModel.fromJson(
              json['test'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}


// ============================================================
// MCQ TEST RESULT MODEL
// ============================================================

class McqTestResultModel {
  final int? id;

  final int? classId;
  final int? sectionId;

  final String? className;
  final String? sectionName;

  final String? subject;
  final DateTime? date;

  final String? startTime;
  final int? duration;
  final int? numberOfQuestions;

  final String? status;

  final List<McqQuestionResultModel> questions;

  McqTestResultModel({
    this.id,
    this.classId,
    this.sectionId,
    this.className,
    this.sectionName,
    this.subject,
    this.date,
    this.startTime,
    this.duration,
    this.numberOfQuestions,
    this.status,
    this.questions = const [],
  });

  factory McqTestResultModel.fromJson(Map<String, dynamic> json) {
    final questionJson = json['questions'];

    return McqTestResultModel(
      id: McqResultModel._toInt(json['id']),

      classId: McqResultModel._toInt(json['classId']),
      sectionId: McqResultModel._toInt(json['sectionId']),

      className: json['className']?.toString(),
      sectionName: json['sectionName']?.toString(),

      subject: json['subject']?.toString(),

      date: McqResultModel._toDateTime(
        json['date'],
      ),

      startTime: json['startTime']?.toString(),

      duration: McqResultModel._toInt(
        json['duration'],
      ),

      numberOfQuestions: McqResultModel._toInt(
        json['numberOfQuestions'],
      ),

      status: json['status']?.toString(),

      questions: questionJson is List
          ? questionJson
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => McqQuestionResultModel.fromJson(item),
              )
              .toList()
          : [],
    );
  }
}


// ============================================================
// MCQ QUESTION RESULT MODEL
// ============================================================

class McqQuestionResultModel {
  final int? id;

  final String? question;

  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;

  final int? marks;

  McqQuestionResultModel({
    this.id,
    this.question,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.marks,
  });

  factory McqQuestionResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return McqQuestionResultModel(
      id: McqResultModel._toInt(json['id']),

      question: json['question']?.toString(),

      optionA: json['optionA']?.toString(),
      optionB: json['optionB']?.toString(),
      optionC: json['optionC']?.toString(),
      optionD: json['optionD']?.toString(),

      marks: McqResultModel._toInt(
        json['marks'],
      ),
    );
  }
}

