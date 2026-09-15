class AcademicYear {
  final int? id;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? current;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AcademicYear({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.current,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      current: json['current'] is bool
          ? json['current']
          : json['current']?.toString().toLowerCase() == 'true',
      description: _parseString(json['description']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate?.toIso8601String().split('T').first,
      'endDate': endDate?.toIso8601String().split('T').first,
      'current': current,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

String? _parseString(dynamic value) {
  if (value == null) return null;

  final result = value.toString().trim();

  if (result.isEmpty || result == 'null') {
    return null;
  }

  return result;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}