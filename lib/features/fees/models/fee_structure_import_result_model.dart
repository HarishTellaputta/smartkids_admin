class FeeStructureImportErrorModel {
  final int row;
  final String message;

  FeeStructureImportErrorModel({required this.row, required this.message});

  factory FeeStructureImportErrorModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureImportErrorModel(
      row: json['row'] ?? 0,
      message: json['message']?.toString() ?? 'Unknown error',
    );
  }
}

class FeeStructureImportResultModel {
  final int totalRows;
  final int created;
  final int skipped;
  final int errors;
  final List<FeeStructureImportErrorModel> errorDetails;

  FeeStructureImportResultModel({
    required this.totalRows,
    required this.created,
    required this.skipped,
    required this.errors,
    required this.errorDetails,
  });

  factory FeeStructureImportResultModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureImportResultModel(
      totalRows: json['totalRows'] ?? 0,
      created: json['created'] ?? 0,
      skipped: json['skipped'] ?? 0,
      errors: json['errors'] ?? 0,
      errorDetails: (json['errorDetails'] as List? ?? [])
          .map(
            (item) => FeeStructureImportErrorModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}
