class FeeReportModel {
  final int id;
  final int? studentFeeId;
  final int? studentId;
  final String studentName;
  final String? receiptNumber;
  final String? paymentMethod;
  final String? remarks;
  final double amount;
  final String paymentDate;

  FeeReportModel({
    required this.id,
    this.studentFeeId,
    this.studentId,
    required this.studentName,
    this.receiptNumber,
    this.paymentMethod,
    this.remarks,
    required this.amount,
    required this.paymentDate,
  });

  factory FeeReportModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'];

    return FeeReportModel(
      id: _toInt(json['id']) ?? 0,
      studentFeeId: _toInt(json['studentFeeId']),
      studentId: _toInt(json['studentId']) ??
          (student is Map ? _toInt(student['id']) : null),
      studentName: json['studentName']?.toString() ??
          (student is Map
              ? student['fullName']?.toString() ??
                  student['name']?.toString() ??
                  '-'
              : '-'),
      receiptNumber: json['receiptNumber']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      remarks: json['remarks']?.toString(),
      amount: _toDouble(json['amount']) ?? 0,
      paymentDate: json['paymentDate']?.toString() ?? '-',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}