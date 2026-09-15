class FeeDashboardSummaryModel {
  final double totalFee;
  final double collected;
  final double pending;
  final double collectionPercentage;

  const FeeDashboardSummaryModel({
    required this.totalFee,
    required this.collected,
    required this.pending,
    required this.collectionPercentage,
  });

  factory FeeDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return FeeDashboardSummaryModel(
      totalFee: _toDouble(json['totalFee']),
      collected: _toDouble(json['collected']),
      pending: _toDouble(json['pending']),
      collectionPercentage: _toDouble(json['collectionPercentage']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}