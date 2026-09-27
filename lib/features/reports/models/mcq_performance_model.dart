class McqPerformanceModel {
  final int? id;
  final int? testId;
  final String? testName;
  final int? studentId;
  final String? studentName;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final String? status;
  final int? score;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? wrongAnswers;
  final double? percentage;

  McqPerformanceModel({
    this.id,
    this.testId,
    this.testName,
    this.studentId,
    this.studentName,
    this.startedAt,
    this.expiresAt,
    this.submittedAt,
    this.status,
    this.score,
    this.totalQuestions,
    this.correctAnswers,
    this.wrongAnswers,
    this.percentage,
  });

  factory McqPerformanceModel.fromJson(
      Map<String, dynamic> json) {
    final test =
        json['test'] as Map<String, dynamic>?;
    final student =
        json['student'] as Map<String, dynamic>?;

    return McqPerformanceModel(
      id: json['id'],
      testId: json['testId'] ?? test?['id'],
      testName:
          json['testName'] ?? test?['title'],
      studentId:
          json['studentId'] ?? student?['id'],
      studentName: json['studentName'] ??
          student?['name'] ??
          student?['fullName'],
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(
              json['startedAt'].toString(),
            )
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(
              json['expiresAt'].toString(),
            )
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(
              json['submittedAt'].toString(),
            )
          : null,
      status: json['status']?.toString(),
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      wrongAnswers: json['wrongAnswers'],
      percentage: json['percentage'] != null
          ? double.tryParse(
              json['percentage'].toString(),
            )
          : null,
    );
  }
}