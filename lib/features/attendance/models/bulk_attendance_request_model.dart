class BulkAttendanceRequestModel {
  final int classId;
  final int teacherId;
  final String attendanceDate;
  final List<StudentAttendanceModel> attendanceRecords;

  BulkAttendanceRequestModel({
    required this.classId,
    required this.teacherId,
    required this.attendanceDate,
    required this.attendanceRecords,
  });

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'teacherId': teacherId,
      'attendanceDate': attendanceDate,
      'attendanceRecords': attendanceRecords
          .map((record) => record.toJson())
          .toList(),
    };
  }
}

class StudentAttendanceModel {
  final int studentId;
  final String status;
  final String? remarks;

  StudentAttendanceModel({
    required this.studentId,
    required this.status,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'status': status,
      'remarks': remarks,
    };
  }
}