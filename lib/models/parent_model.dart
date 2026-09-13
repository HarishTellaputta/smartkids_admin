
class Parent {
  final int? id;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? contactPhone;
  final String? contactEmail;
  final String? relationship;
  final String? address;

  // Optional student information returned by backend
  final List<ParentStudent> students;

  Parent({
    this.id,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.contactPhone,
    this.contactEmail,
    this.relationship,
    this.address,
    this.students = const [],
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    final dynamic studentsJson =
        json['students'] ??
        json['studentList'] ??
        json['children'] ??
        [];

    List<ParentStudent> parsedStudents = [];

    if (studentsJson is List) {
      parsedStudents = studentsJson
          .whereType<Map>()
          .map(
            (e) => ParentStudent.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    return Parent(
      id: _toInt(json['id']),
      fatherName: _toString(json['fatherName']),
      motherName: _toString(json['motherName']),
      guardianName: _toString(json['guardianName']),
      contactPhone: _toString(json['contactPhone']),
      contactEmail: _toString(json['contactEmail']),
      relationship: _toString(json['relationship']),
      address: _toString(json['address']),
      students: parsedStudents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fatherName': fatherName ?? '',
      'motherName': motherName ?? '',
      'guardianName': guardianName ?? '',
      'contactPhone': contactPhone ?? '',
      'contactEmail': contactEmail ?? '',
      'relationship': relationship ?? '',
      'address': address ?? '',
    };
  }

  String get displayName {
    if (relationship?.toLowerCase() == 'mother' &&
        _hasValue(motherName)) {
      return motherName!;
    }

    if (relationship?.toLowerCase() == 'guardian' &&
        _hasValue(guardianName)) {
      return guardianName!;
    }

    if (_hasValue(fatherName)) {
      return fatherName!;
    }

    if (_hasValue(motherName)) {
      return motherName!;
    }

    if (_hasValue(guardianName)) {
      return guardianName!;
    }

    return 'Unnamed Parent';
  }

  String get initials {
    final name = displayName.trim();

    if (name.isEmpty) return 'P';

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get studentSummary {
    if (students.isEmpty) {
      return 'No student linked';
    }

    if (students.length == 1) {
      return students.first.name ?? 'Student';
    }

    return '${students.length} students';
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class ParentStudent {
  final int? id;
  final String? name;
  final String? admissionNo;
  final String? sectionName;

  ParentStudent({
    this.id,
    this.name,
    this.admissionNo,
    this.sectionName,
  });

  factory ParentStudent.fromJson(Map<String, dynamic> json) {
    return ParentStudent(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      admissionNo: _toString(json['admissionNo']),
      sectionName: _toString(
        json['sectionName'] ?? json['className'],
      ),
    );
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }
}

