class StudentFeeModel {
  final int? id;
  final int? studentId;
  final int? feeStructureId;
  final String studentName;
  final String feeName;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String dueDate;

  StudentFeeModel({
    this.id,
    this.studentId,
    this.feeStructureId,
    required this.studentName,
    required this.feeName,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.dueDate,
  });

  factory StudentFeeModel.fromJson(Map<String, dynamic> json) {
    return StudentFeeModel(
      id: _toInt(json['id']),
      studentId: _toInt(json['studentId']),
      feeStructureId: _toInt(json['feeStructureId']),
      studentName: json['studentName']?.toString() ?? '',
      feeName: json['feeName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      pendingAmount: _toDouble(json['pendingAmount']),
      dueDate: json['dueDate']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}


class FeePaymentModel {
  final int? id;
  final int? studentFeeId;
  final int? studentId;
  final String studentName;
  final String receiptNumber;
  final String paymentMethod;
  final String remarks;
  final double amount;
  final String paymentDate;

  FeePaymentModel({
    this.id,
    this.studentFeeId,
    this.studentId,
    required this.studentName,
    required this.receiptNumber,
    required this.paymentMethod,
    required this.remarks,
    required this.amount,
    required this.paymentDate,
  });

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) {
    return FeePaymentModel(
      id: _toInt(json['id']),
      studentFeeId: _toInt(json['studentFeeId']),
      studentId: _toInt(json['studentId']),
      studentName: json['studentName']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      paymentDate: json['paymentDate']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}