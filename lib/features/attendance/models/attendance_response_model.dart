class AttendanceResponseModel {
  final int id;
  final int? studentId;
  final String? studentName;
  final String? studentRollNumber;
  final int? classId;
  final String? className;
  final int? markedByTeacherId;
  final String? markedByTeacherName;
  final DateTime? attendanceDate;
  final String status;
  final String? remarks;
  final DateTime? markedAt;
  final DateTime? updatedAt;
  final int? updatedByTeacherId;
  final String? updatedByTeacherName;

  AttendanceResponseModel({
    required this.id,
    this.studentId,
    this.studentName,
    this.studentRollNumber,
    this.classId,
    this.className,
    this.markedByTeacherId,
    this.markedByTeacherName,
    this.attendanceDate,
    required this.status,
    this.remarks,
    this.markedAt,
    this.updatedAt,
    this.updatedByTeacherId,
    this.updatedByTeacherName,
  });

  factory AttendanceResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceResponseModel(
      id: json['id'] ?? 0,
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentRollNumber: json['studentRollNumber'],
      classId: json['classId'],
      className: json['className'],
      markedByTeacherId: json['markedByTeacherId'],
      markedByTeacherName: json['markedByTeacherName'],
      attendanceDate: json['attendanceDate'] != null
          ? DateTime.tryParse(json['attendanceDate'].toString())
          : null,
      status: json['status'] ?? '',
      remarks: json['remarks'],
      markedAt: json['markedAt'] != null
          ? DateTime.tryParse(json['markedAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      updatedByTeacherId: json['updatedByTeacherId'],
      updatedByTeacherName: json['updatedByTeacherName'],
    );
  }
}