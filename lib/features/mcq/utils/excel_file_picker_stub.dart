class ExcelFileData {
  final String name;
  final List<int> bytes;

  ExcelFileData({
    required this.name,
    required this.bytes,
  });
}

Future<ExcelFileData?> pickExcelFile() async {
  throw UnsupportedError(
    'Excel import is currently supported only on Flutter Web.',
  );
}