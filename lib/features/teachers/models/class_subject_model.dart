class ClassSubjectModel {
  final int id;
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final String subjectCode;

  const ClassSubjectModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  factory ClassSubjectModel.fromJson(Map<String, dynamic> json) {
    return ClassSubjectModel(
      id: _parseInt(json['id']),
      classId: _parseInt(json['classId']),
      className: _parseString(json['className']),
      subjectId: _parseInt(json['subjectId']),
      subjectName: _parseString(json['subjectName']),
      subjectCode: _parseString(json['subjectCode']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
    };
  }

  ClassSubjectModel copyWith({
    int? id,
    int? classId,
    String? className,
    int? subjectId,
    String? subjectName,
    String? subjectCode,
  }) {
    return ClassSubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
    );
  }

  @override
  String toString() {
    return 'ClassSubjectModel('
        'id: $id, '
        'classId: $classId, '
        'className: $className, '
        'subjectId: $subjectId, '
        'subjectName: $subjectName, '
        'subjectCode: $subjectCode'
        ')';
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString()) ?? 0;
}

String _parseString(dynamic value) {
  if (value == null) return '';

  return value.toString().trim();
}
