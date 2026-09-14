import 'package:flutter/foundation.dart';

class TimetableEntry {
  final int id;
  final int teacherId;
  final String? teacherName;
  final int classId;
  final String? className;
  final int? sectionId;
  final String? sectionName;
  final String subject;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimetableEntry({
    required this.id,
    required this.teacherId,
    this.teacherName,
    required this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: _toInt(json['id']),
      teacherId: _toInt(json['teacherId']),
      teacherName: json['teacherName']?.toString(),
      classId: _toInt(json['classId']),
      className: json['className']?.toString(),
      sectionId:
          json['sectionId'] == null ? null : _toInt(json['sectionId']),
      sectionName: json['sectionName']?.toString(),
      subject: json['subject']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      startTime: _cleanTime(json['startTime']),
      endTime: _cleanTime(json['endTime']),
      roomNumber: json['roomNumber']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange {
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  static String formatTime(String value) {
    try {
      final parts = value.split(':');

      if (parts.length < 2) {
        return value;
      }

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';

      int displayHour = hour % 12;

      if (displayHour == 0) {
        displayHour = 12;
      }

      return '${displayHour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return value;
    }
  }

  static String _cleanTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return '$subject | $dayOfWeek | $startTime-$endTime';
  }
}