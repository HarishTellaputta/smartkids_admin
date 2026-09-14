class AttendanceRequestModel {
  final int studentId;
  final int classId;
  final int teacherId;
  final String attendanceDate;
  final String status;
  final String? remarks;

  AttendanceRequestModel({
    required this.studentId,
    required this.classId,
    required this.teacherId,
    required this.attendanceDate,
    required this.status,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'classId': classId,
      'teacherId': teacherId,
      'attendanceDate': attendanceDate,
      'status': status,
      'remarks': remarks,
    };
  }
}