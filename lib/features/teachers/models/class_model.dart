class SchoolClass {
  final int? id;
  final int? schoolId;
  final String? schoolName;
  final String? name;
  final String? code;
  final String? grade;
  final int? year;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolClass({
    this.id,
    this.schoolId,
    this.schoolName,
    this.name,
    this.code,
    this.grade,
    this.year,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: _parseInt(json['id']),
      schoolId: _parseInt(json['schoolId']),
      schoolName: _parseString(json['schoolName']),
      name: _parseString(json['name']),
      code: _parseString(json['code']),
      grade: _parseString(json['grade']),
      year: _parseInt(json['year']),
      description: _parseString(json['description']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'name': name,
      'code': code,
      'grade': grade,
      'year': year,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SchoolClass copyWith({
    int? id,
    int? schoolId,
    String? schoolName,
    String? name,
    String? code,
    String? grade,
    int? year,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      name: name ?? this.name,
      code: code ?? this.code,
      grade: grade ?? this.grade,
      year: year ?? this.year,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SchoolClass('
        'id: $id, '
        'schoolId: $schoolId, '
        'name: $name, '
        'code: $code, '
        'grade: $grade, '
        'year: $year'
        ')';
  }
}

// ============================================================
// HELPERS
// ============================================================

int? _parseInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  return int.tryParse(value.toString());
}

String? _parseString(dynamic value) {
  if (value == null) return null;

  final result = value.toString().trim();

  if (result.isEmpty) return null;

  return result;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}