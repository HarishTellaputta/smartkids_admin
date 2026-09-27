class AttendanceReportModel {
  final int id;
  final int? studentId;
  final String studentName;
  final int? classId;
  final String className;
  final String attendanceDate;
  final String status;
  final String? remarks;
  final String? markedAt;

  AttendanceReportModel({
    required this.id,
    this.studentId,
    required this.studentName,
    this.classId,
    required this.className,
    required this.attendanceDate,
    required this.status,
    this.remarks,
    this.markedAt,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final classEntity = json['classEntity'];

    return AttendanceReportModel(
      id: _toInt(json['id']) ?? 0,
      studentId: _toInt(json['studentId']) ??
          (student is Map ? _toInt(student['id']) : null),
      studentName: json['studentName']?.toString() ??
          (student is Map
              ? student['fullName']?.toString() ??
                  student['name']?.toString() ??
                  '-'
              : '-'),
      classId: _toInt(json['classId']) ??
          (classEntity is Map ? _toInt(classEntity['id']) : null),
      className: json['className']?.toString() ??
          (classEntity is Map
              ? classEntity['name']?.toString() ?? '-'
              : '-'),
      attendanceDate: json['attendanceDate']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      remarks: json['remarks']?.toString(),
      markedAt: json['markedAt']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}