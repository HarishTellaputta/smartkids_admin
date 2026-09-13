class Student {
  final int? id;
  final String? admissionNo;
  final String? name;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? admissionDate;
  final int? sectionId;
  final String? sectionName;
  final int? parentId;
  final String? parentName;
  final int? academicYearId;
  final String? academicYearName;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  Student({
    this.id,
    this.admissionNo,
    this.name,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.admissionDate,
    this.sectionId,
    this.sectionName,
    this.parentId,
    this.parentName,
    this.academicYearId,
    this.academicYearName,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      admissionNo: json['admissionNo'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'],
      admissionDate: json['admissionDate'],
      sectionId: json['sectionId'],
      sectionName: json['sectionName'],
      parentId: json['parentId'],
      parentName: json['parentName'],
      academicYearId: json['academicYearId'],
      academicYearName: json['academicYearName'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class StudentPage {
  final List<Student> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final int size;

  StudentPage({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
  });

  factory StudentPage.fromJson(Map<String, dynamic> json) {
    return StudentPage(
      content: (json['content'] as List)
          .map((e) => Student.fromJson(e))
          .toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      number: json['number'] ?? 0,
      size: json['size'] ?? 10,
    );
  }
}