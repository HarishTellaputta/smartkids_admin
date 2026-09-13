class Teacher {
  final int? id;
  final int? schoolId;
  final String? schoolName;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'joiningDate': joiningDate,
      'qualification': qualification,
      'designation': designation,
      'address': address,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Teacher copyWith({
    int? id,
    int? schoolId,
    String? schoolName,
    String? employeeId,
    String? name,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? joiningDate,
    String? qualification,
    String? designation,
    String? address,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      joiningDate: joiningDate ?? this.joiningDate,
      qualification: qualification ?? this.qualification,
      designation: designation ?? this.designation,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    if (result.isEmpty) return null;

    return result;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'Teacher('
        'id: $id, '
        'schoolId: $schoolId, '
        'employeeId: $employeeId, '
        'name: $name, '
        'email: $email, '
        'phone: $phone, '
        'dateOfBirth: $dateOfBirth, '
        'gender: $gender, '
        'joiningDate: $joiningDate, '
        'qualification: $qualification, '
        'designation: $designation, '
        'address: $address, '
        'status: $status'
        ')';
  }
}