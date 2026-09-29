
class McqPerformanceModel {
  final int? id;
  final int? testId;
  final String? testName;
  final String? subject;

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
    this.subject,
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
    Map<String, dynamic> json,
  ) {
    final test = json['test'] is Map
        ? Map<String, dynamic>.from(json['test'])
        : null;

    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'])
        : null;

    return McqPerformanceModel(
      // Backend DTO uses attemptId.
      id: _toInt(
        json['attemptId'] ?? json['id'],
      ),

      testId: _toInt(
        json['testId'] ?? test?['id'],
      ),

      testName: _getTestName(
        json,
        test,
      ),

      // Subject is provided by McqTestResponseDto.
      subject: _toStringOrNull(
        test?['subject'] ?? json['subject'],
      ),

      studentId: _toInt(
        json['studentId'] ?? student?['id'],
      ),

      studentName:
          _toStringOrNull(json['studentName']) ??
          _toStringOrNull(student?['name']) ??
          _toStringOrNull(student?['fullName']),

      startedAt: _toDateTime(
        json['startedAt'],
      ),

      expiresAt: _toDateTime(
        json['expiresAt'],
      ),

      submittedAt: _toDateTime(
        json['submittedAt'],
      ),

      status: _toStringOrNull(
        json['status'],
      ),

      score: _toInt(
        json['score'],
      ),

      totalQuestions: _toInt(
        json['totalQuestions'],
      ),

      correctAnswers: _toInt(
        json['correctAnswers'],
      ),

      wrongAnswers: _toInt(
        json['wrongAnswers'],
      ),

      percentage: _toDouble(
        json['percentage'],
      ),
    );
  }

  // ============================================================
  // TEST NAME
  // ============================================================

  static String? _getTestName(
    Map<String, dynamic> json,
    Map<String, dynamic>? test,
  ) {
    // 1. Direct testName from API.
    final directName = _toStringOrNull(
      json['testName'],
    );

    if (directName != null) {
      return directName;
    }

    if (test == null) {
      return null;
    }

    // 2. Try title.
    final title = _toStringOrNull(
      test['title'],
    );

    if (title != null) {
      return title;
    }

    // 3. Try name.
    final name = _toStringOrNull(
      test['name'],
    );

    if (name != null) {
      return name;
    }

    // 4. Build a descriptive name from
    // subject + class + section.
    final subject = _toStringOrNull(
      test['subject'],
    );

    final className = _toStringOrNull(
      test['className'],
    );

    final sectionName = _toStringOrNull(
      test['sectionName'],
    );

    final parts = <String>[];

    if (subject != null) {
      parts.add(subject);
    }

    if (className != null) {
      parts.add(className);
    }

    if (sectionName != null) {
      parts.add('Section $sectionName');
    }

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    return null;
  }

  // ============================================================
  // STRING
  // ============================================================

  static String? _toStringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  // ============================================================
  // INT
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DATETIME
  // ============================================================

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}