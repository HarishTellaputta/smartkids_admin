import 'dart:convert';

class Section {
  final int id;
  final int classId;
  final String? className;
  final String name;
  final int? capacity;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Section({
    required this.id,
    required this.classId,
    this.className,
    required this.name,
    this.capacity,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: _parseInt(json['id']),
      classId: _parseInt(json['classId']),
      className: json['className']?.toString(),
      name: json['name']?.toString() ?? '',
      capacity: json['capacity'] != null
          ? _parseInt(json['capacity'])
          : null,
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'className': className,
      'name': name,
      'capacity': capacity,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
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
    return jsonEncode(toJson());
  }
}