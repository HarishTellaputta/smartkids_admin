class TeacherAssignment {
  final int? id;
  final int? teacherId;
  final String? teacherName;
  final int? classId;
  final String? className;
  final int? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final DateTime? assignedAt;

  const TeacherAssignment({
    this.id,
    this.teacherId,
    this.teacherName,
    this.classId,
    this.className,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.assignedAt,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      id: _parseInt(json['id']),
      teacherId: _parseInt(json['teacherId']),
      teacherName: _parseString(json['teacherName']),
      classId: _parseInt(json['classId']),
      className: _parseString(json['className']),
      subjectId: _parseInt(json['subjectId']),
      subjectName: _parseString(json['subjectName']),
      subjectCode: _parseString(json['subjectCode']),
      assignedAt: _parseDateTime(json['assignedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  TeacherAssignment copyWith({
    int? id,
    int? teacherId,
    String? teacherName,
    int? classId,
    String? className,
    int? subjectId,
    String? subjectName,
    String? subjectCode,
    DateTime? assignedAt,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
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
        'subjectId: $subjectId, '
        'subjectName: $subjectName, '
        'subjectCode: $subjectCode, '
        'assignedAt: $assignedAt'
        ')';
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
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
