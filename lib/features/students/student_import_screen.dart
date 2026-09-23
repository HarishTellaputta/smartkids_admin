import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/student_service.dart';

import 'package:smartkids_admin/features/exams/services/excel_file_picker_service.dart';

class StudentImportScreen extends StatefulWidget {
  final StudentService studentService;

  const StudentImportScreen({super.key, required this.studentService});

  @override
  State<StudentImportScreen> createState() => _StudentImportScreenState();
}

class _StudentImportScreenState extends State<StudentImportScreen> {
  String? selectedFileName;

  List<List<String>> rows = [];

  String? errorMessage;

  bool isLoading = false;
  bool isImporting = false;

  // Store selected Excel bytes so we can send
  // the same file to the backend.
  List<int>? selectedFileBytes;

  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<void> _pickExcelFile() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      // Use the same working Excel picker service
      // already used by TimetableScreen.
      final selectedFile = await ExcelFilePickerService.pickExcelFile();

      if (selectedFile == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      debugPrint('SELECTED FILE: ${selectedFile.fileName}');

      final bytes = selectedFile.bytes;

      debugPrint('FILE BYTES: ${bytes.length}');

      if (bytes.isEmpty) {
        throw Exception('Selected Excel file is empty or could not be read.');
      }

      // ========================================================
      // READ EXCEL
      // ========================================================

      final workbook = excel.Excel.decodeBytes(bytes);

      if (workbook.tables.isEmpty) {
        throw Exception('Excel file does not contain any worksheet.');
      }

      final sheetName = workbook.tables.keys.first;
      final sheet = workbook.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel worksheet is empty.');
      }

      final List<List<String>> parsedRows = [];

      for (final row in sheet.rows) {
        final List<String> rowData = [];

        for (final cell in row) {
          rowData.add(cell?.value?.toString().trim() ?? '');
        }

        parsedRows.add(rowData);
      }

      if (parsedRows.length < 2) {
        throw Exception(
          'Excel file must contain a header row and at least one student.',
        );
      }

      if (!mounted) return;

      setState(() {
        selectedFileName = selectedFile.fileName;

        // IMPORTANT:
        // Keep the Excel bytes for backend upload.
        selectedFileBytes = bytes;

        rows = parsedRows;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('EXCEL READ ERROR: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');

        isLoading = false;
        rows = [];
        selectedFileBytes = null;
      });
    }
  }

  // ============================================================
  // IMPORT EXCEL TO BACKEND
  // ============================================================
  Future<void> _importStudents() async {
    if (selectedFileBytes == null || selectedFileBytes!.isEmpty) {
      setState(() {
        errorMessage = 'Please select an Excel file first.';
      });

      return;
    }

    setState(() {
      errorMessage = null;
      isImporting = true;
    });

    try {
      debugPrint('========== STUDENT EXCEL IMPORT ==========');
      debugPrint('FILE NAME: $selectedFileName');
      debugPrint('FILE SIZE: ${selectedFileBytes!.length}');

      // IMPORTANT:
      // Use the existing StudentService.
      // It already contains:
      // 1. Backend base URL
      // 2. JWT Authorization header
      final result = await widget.studentService.importStudentsExcel(
        bytes: selectedFileBytes!,
        fileName: selectedFileName ?? 'students.xlsx',
      );

      debugPrint('========== IMPORT SUCCESS ==========');
      debugPrint('RESULT: $result');

      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      await _showImportSuccess(result);
    } on DioException catch (e) {
      debugPrint('IMPORT DIO ERROR: ${e.message}');
      debugPrint('IMPORT STATUS: ${e.response?.statusCode}');
      debugPrint('IMPORT RESPONSE: ${e.response?.data}');

      if (!mounted) return;

      setState(() {
        isImporting = false;
        errorMessage = _getBackendErrorMessage(e);
      });
    } catch (e) {
      debugPrint('IMPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isImporting = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
  // ============================================================
  // BACKEND ERROR MESSAGE
  // ============================================================

  String _getBackendErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is Map) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    if (e.response?.statusCode == 403) {
      return 'You do not have permission to import students.';
    }

    if (e.response?.statusCode == 400) {
      return 'Invalid Excel file or student data.';
    }

    return e.message ?? 'Failed to import students.';
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showImportSuccess(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Import Successful'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                // Return to StudentsScreen.
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Import Students'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadSection(),

            const SizedBox(height: 20),

            if (errorMessage != null) _buildError(),

            if (rows.isNotEmpty) ...[
              _buildPreviewHeader(),

              const SizedBox(height: 12),

              Expanded(child: _buildPreviewTable()),

              const SizedBox(height: 14),

              _buildImportButton(),
            ] else if (!isLoading)
              Expanded(child: _buildEmptyState()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPLOAD SECTION
  // ============================================================

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.table_chart_outlined, color: Colors.green),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Students from Excel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 4),

                Text(
                  selectedFileName ??
                      'Select an .xlsx file containing student details.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          OutlinedButton.icon(
            onPressed: isLoading || isImporting ? null : _pickExcelFile,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(isLoading ? 'Reading...' : 'Choose Excel'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMPORT BUTTON
  // ============================================================

  Widget _buildImportButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: isImporting ? null : _importStudents,
        icon: isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 19),
        label: Text(isImporting ? 'Importing...' : 'Import Students'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREVIEW HEADER
  // ============================================================

  Widget _buildPreviewHeader() {
    final dataRows = rows.length - 1;

    return Row(
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        const SizedBox(width: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$dataRows students',
            style: const TextStyle(
              color: Colors.indigo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PREVIEW TABLE
  // ============================================================

  Widget _buildPreviewTable() {
    final headers = rows.first;
    final dataRows = rows.skip(1).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
            columns: [
              ...headers.map(
                (header) => DataColumn(
                  label: Text(
                    header.isEmpty ? '-' : header,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            rows: dataRows.map((row) {
              return DataRow(
                cells: List.generate(headers.length, (index) {
                  final value = index < row.length ? row[index] : '';

                  return DataCell(
                    Text(
                      value.isEmpty ? '-' : value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No Excel file selected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            'Choose an .xlsx file to preview student records.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
