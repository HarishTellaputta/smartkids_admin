class AttendanceDashboardSummaryModel {
  final int totalStudents;
  final int marked;
  final int present;
  final int absent;
  final int leave;
  final double attendancePercentage;

  const AttendanceDashboardSummaryModel({
    required this.totalStudents,
    required this.marked,
    required this.present,
    required this.absent,
    required this.leave,
    required this.attendancePercentage,
  });

  factory AttendanceDashboardSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceDashboardSummaryModel(
      totalStudents: _toInt(json['totalStudents']),
      marked: _toInt(json['marked']),
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      leave: _toInt(json['leave']),
      attendancePercentage: _toDouble(
        json['attendancePercentage'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}