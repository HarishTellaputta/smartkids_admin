class AttendanceLastSixDaysModel {
  final DateTime date;
  final String day;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int leave;
  final int totalStudents;
  final int marked;

  AttendanceLastSixDaysModel({
    required this.date,
    required this.day,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.leave,
    required this.totalStudents,
    required this.marked,
  });

  factory AttendanceLastSixDaysModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLastSixDaysModel(
      date: DateTime.parse(json['date'].toString()),
      day: json['day']?.toString() ?? '',
      attendancePercentage:
          (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      leave: (json['leave'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      marked: (json['marked'] as num?)?.toInt() ?? 0,
    );
  }
}