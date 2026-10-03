import 'dart:typed_data';

import 'package:excel/excel.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../excel_reports/excel_import_dialogs.dart';
import '../services/academic_year_service.dart';
import '../excel_reports/excel_file_picker.dart';

class AcademicYearExcelCard extends StatefulWidget {
  const AcademicYearExcelCard({super.key});

  @override
  State<AcademicYearExcelCard> createState() => _AcademicYearExcelCardState();
}

class _AcademicYearExcelCardState extends State<AcademicYearExcelCard> {
  bool _downloading = false;
  bool _importing = false;
  bool _isHovering = false;

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ============================================================
  // DOWNLOAD SAMPLE EXCEL
  // ============================================================

  Future<void> _downloadTemplate() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      final workbook = excel.Excel.createExcel();

      // Use the default first sheet itself.
      final defaultSheet = workbook.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      workbook.rename(defaultSheet, 'Academic Years');

      final academicSheet = workbook['Academic Years'];

      // Header
      academicSheet.appendRow([
        excel.TextCellValue('Name'),
        excel.TextCellValue('Start Date'),
        excel.TextCellValue('End Date'),
        excel.TextCellValue('Current'),
        excel.TextCellValue('Description'),
      ]);

      // Sample row 1
      academicSheet.appendRow([
        excel.TextCellValue('2026-2027'),
        excel.TextCellValue('2026-06-01'),
        excel.TextCellValue('2027-04-30'),
        excel.TextCellValue('TRUE'),
        excel.TextCellValue('Current Academic Year'),
      ]);

      // Sample row 2
      academicSheet.appendRow([
        excel.TextCellValue('2025-2026'),
        excel.TextCellValue('2025-06-01'),
        excel.TextCellValue('2026-04-30'),
        excel.TextCellValue('FALSE'),
        excel.TextCellValue('Previous Academic Year'),
      ]);

      final bytes = workbook.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel template.');
      }

      final fileBytes = Uint8List.fromList(bytes);

      final savedPath = await FileSaver.instance.saveFile(
        name: 'academic_years_data_template.xlsx',
        bytes: fileBytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      if (savedPath.isNotEmpty) {
        await ExcelImportDialogs.showTemplateDownloaded(
          context,
          entityName: 'Academic Years',
        );
      }
    } catch (e) {
      if (!mounted) return;

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'Academic Years',
        message: 'Failed to download sample Excel file.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  // ============================================================
  // IMPORT EXCEL
  // ============================================================

  Future<void> _importExcel() async {
    if (_importing) return;

    setState(() {
      _importing = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session expired. Please login again.');
      }

      final pickedFile = await ExcelFilePicker.pick();

      if (pickedFile == null) {
        return;
      }

      final bytes = pickedFile.bytes;

      if (bytes.isEmpty) {
        throw Exception('Selected Excel file is empty.');
      }

      if (!pickedFile.name.toLowerCase().endsWith('.xlsx')) {
        throw Exception('Please select a valid .xlsx Excel file.');
      }

      final academicYearService = AcademicYearService(token);

      final result = await academicYearService.importAcademicYears(
        bytes,
        pickedFile.name,
      );

      if (!mounted) return;

      final totalRows = _toInt(result['totalRows']);

      final created = _toInt(
        result['created'] ?? result['createdCount'],
      );

      final updated = _toInt(
        result['updated'] ?? result['updatedCount'],
      );

      final errors = _toInt(
        result['errors'] ?? result['failedCount'],
      );

      final errorDetails =
          result['errorDetails'] ??
          result['errorsDetails'] ??
          result['failedRows'];

      if (errors > 0) {
        await ExcelImportDialogs.showPartial(
          context,
          entityName: 'Academic Years',
          total: totalRows,
          created: created,
          updated: updated,
          failed: errors,
          message:
              'Academic Years import completed with some errors.',
          errors: _parseErrors(errorDetails),
        );
      } else {
        await ExcelImportDialogs.showSuccess(
          context,
          entityName: 'Academic Years',
          total: totalRows,
          created: created,
          updated: updated,
          message:
              'All academic year records were imported successfully.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith('Exception:')) {
        message = message.substring('Exception:'.length).trim();
      }

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'Academic Years',
        message: message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // ERROR PARSER
  // ============================================================

  List<String> _parseErrors(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          final row = item['row'];
          final message =
              item['message'] ??
              item['error'] ??
              item.toString();

          if (row != null) {
            return 'Row $row: $message';
          }

          return message.toString();
        }

        return item.toString();
      }).toList();
    }

    return [value.toString()];
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get _statusText {
    if (_downloading) return 'Preparing';
    if (_importing) return 'Importing';
    return 'Ready';
  }

  Color get _statusColor {
    if (_downloading) {
      return const Color(0xFF2563EB);
    }

    if (_importing) {
      return const Color(0xFF7C3AED);
    }

    return const Color(0xFF16A34A);
  }

  Color get _statusBackground {
    if (_downloading) {
      return const Color(0xFFEFF6FF);
    }

    if (_importing) {
      return const Color(0xFFF5F3FF);
    }

    return const Color(0xFFECFDF3);
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovering
                ? const Color(0xFFD5DDF0)
                : const Color(0xFFE8ECF3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                _isHovering ? 0.075 : 0.035,
              ),
              blurRadius: _isHovering ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF4F46E5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF2563EB,
                        ).withOpacity(0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic Years',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        'Manage academic year records',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ====================================================
            // INFO STRIP
            // ====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFFE8EDF3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_chart_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'Name  •  Start Date  •  End Date  •  Current  •  Description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // ACTION BUTTONS
            // ====================================================

            Row(
              children: [
                // DOWNLOAD
                Expanded(
                  child: _AcademicActionButton(
                    label: _downloading
                        ? 'Downloading...'
                        : 'Download Sample',
                    icon: Icons.download_rounded,
                    loading: _downloading,
                    primary: true,
                    onPressed: _downloading
                        ? null
                        : _downloadTemplate,
                  ),
                ),

                const SizedBox(width: 10),

                // IMPORT
                Expanded(
                  child: _AcademicActionButton(
                    label: _importing
                        ? 'Importing...'
                        : 'Import Excel',
                    icon: Icons.upload_file_rounded,
                    loading: _importing,
                    primary: false,
                    onPressed:
                        _importing ? null : _importExcel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ====================================================
            // FOOTER
            // ====================================================

            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),

                const SizedBox(width: 5),

                const Text(
                  '.xlsx format supported',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),

                const SizedBox(width: 4),

                const Text(
                  'Secure import',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PREMIUM ACTION BUTTON
// ================================================================

class _AcademicActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool primary;
  final VoidCallback? onPressed;

  const _AcademicActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        height: 42,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    key: const ValueKey('icon'),
                    size: 17,
                  ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                const Color(0xFF93C5FD),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  key: const ValueKey('icon'),
                  size: 17,
                ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            label,
            key: ValueKey(label),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          disabledForegroundColor: const Color(0xFF93C5FD),
          side: BorderSide(
            color: onPressed == null
                ? const Color(0xFFBFDBFE)
                : const Color(0xFF2563EB),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}