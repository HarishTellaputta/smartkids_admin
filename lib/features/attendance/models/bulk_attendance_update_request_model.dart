class BulkAttendanceUpdateRequestModel {
  final int? teacherId;
  final List<AttendanceUpdateRecordModel> attendanceRecords;

  BulkAttendanceUpdateRequestModel({
    this.teacherId,
    required this.attendanceRecords,
  });

  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'attendanceRecords': attendanceRecords
          .map((record) => record.toJson())
          .toList(),
    };
  }
}

class AttendanceUpdateRecordModel {
  final int attendanceId;
  final String status;
  final String? remarks;

  AttendanceUpdateRecordModel({
    required this.attendanceId,
    required this.status,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {'attendanceId': attendanceId, 'status': status, 'remarks': remarks};
  }
}
