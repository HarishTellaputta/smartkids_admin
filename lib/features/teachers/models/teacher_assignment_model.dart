class TeacherAssignment {
  final int? id;
  final int? teacherId;
  final String? teacherName;
  final int? classId;
  final String? className;
  final String? subject;
  final DateTime? assignedAt;

  const TeacherAssignment({
    this.id,
    this.teacherId,
    this.teacherName,
    this.classId,
    this.className,
    this.subject,
    this.assignedAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory TeacherAssignment.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherAssignment(
      id: _parseInt(json['id']),
      teacherId: _parseInt(json['teacherId']),
      teacherName: _parseString(json['teacherName']),
      classId: _parseInt(json['classId']),
      className: _parseString(json['className']),
      subject: _parseString(json['subject']),
      assignedAt: _parseDateTime(json['assignedAt']),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'subject': subject,
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  TeacherAssignment copyWith({
    int? id,
    int? teacherId,
    String? teacherName,
    int? classId,
    String? className,
    String? subject,
    DateTime? assignedAt,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  @override
  String toString() {
    return 'TeacherAssignment('
        'id: $id, '
        'teacherId: $teacherId, '
        'teacherName: $teacherName, '
        'classId: $classId, '
        'className: $className, '
        'subject: $subject, '
        'assignedAt: $assignedAt'
        ')';
  }
}

// ============================================================
// HELPERS
// ============================================================

int? _parseInt(dynamic value) {
  if (value == null) return null;

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

String? _parseString(dynamic value) {
  if (value == null) return null;

  final result = value.toString().trim();

  if (result.isEmpty) {
    return null;
  }

  return result;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}