class Teacher {
  final int? id;
  final int? schoolId;
  final String? schoolName;
  final int? userId;

  final String? employeeId;
  final String? name;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? joiningDate;
  final String? qualification;
  final String? designation;
  final String? address;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Teacher({
    this.id,
    this.schoolId,
    this.schoolName,
    this.userId,
    this.employeeId,
    this.name,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.joiningDate,
    this.qualification,
    this.designation,
    this.address,
    this.status,
    this.createdAt,
    this.updatedAt,
  });
  factory Teacher.fromJson(Map<String, dynamic> json) {
  return Teacher(
    id: _parseInt(json['id']),
    schoolId: _parseInt(json['schoolId']),
    schoolName: _parseString(json['schoolName']),
    userId: _parseInt(json['userId']),

    employeeId: _parseString(json['employeeId']),
    name: _parseString(json['name']),
    email: _parseString(json['email']),
    phone: _parseString(json['phone']),
    dateOfBirth: _parseString(json['dateOfBirth']),
    gender: _parseString(json['gender']),
    joiningDate: _parseString(json['joiningDate']),
    qualification: _parseString(json['qualification']),
    designation: _parseString(json['designation']),
    address: _parseString(json['address']),
    status: _parseString(json['status']),
    createdAt: _parseDateTime(json['createdAt']),
    updatedAt: _parseDateTime(json['updatedAt']),
  );
}

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}