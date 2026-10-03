import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../services/school_service.dart';
import '../excel_reports/excel_file_picker.dart';
import '../excel_reports/excel_import_dialogs.dart';

class SchoolExcelCard extends StatefulWidget {
  const SchoolExcelCard({super.key});

  @override
  State<SchoolExcelCard> createState() => _SchoolExcelCardState();
}

class _SchoolExcelCardState extends State<SchoolExcelCard> {
  bool _importing = false;
  bool _downloading = false;

  late final SchoolService _schoolService;

  @override
  void initState() {
    super.initState();
    _schoolService = SchoolService(ApiClient());
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<void> _generateExcel(BuildContext context) async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      final excel = ex.Excel.createExcel();

      // Use the default first sheet.
      // This prevents an empty Sheet1 from appearing before Schools.
      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'Schools');

      final sheet = excel['Schools'];

      sheet.appendRow([
        ex.TextCellValue('name'),
        ex.TextCellValue('code'),
        ex.TextCellValue('address'),
        ex.TextCellValue('affiliationNumber'),
        ex.TextCellValue('city'),
        ex.TextCellValue('country'),
        ex.TextCellValue('email'),
        ex.TextCellValue('establishmentYear'),
        ex.TextCellValue('facilities'),
        ex.TextCellValue('facultyInfo'),
        ex.TextCellValue('logoUrl'),
        ex.TextCellValue('phone'),
        ex.TextCellValue('postalCode'),
        ex.TextCellValue('principalMessage'),
        ex.TextCellValue('principalName'),
        ex.TextCellValue('schoolType'),
        ex.TextCellValue('state'),
        ex.TextCellValue('status'),
        ex.TextCellValue('website'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Test School'),
        ex.TextCellValue('TEST001'),
        ex.TextCellValue('Khammam, Telangana'),
        ex.TextCellValue('TEST-AFF-001'),
        ex.TextCellValue('Khammam'),
        ex.TextCellValue('India'),
        ex.TextCellValue('testschool@example.com'),
        ex.IntCellValue(2020),
        ex.TextCellValue(
          'Smart Classrooms, Computer Lab, Library, Sports',
        ),
        ex.TextCellValue('Experienced Teaching Faculty'),
        ex.TextCellValue(''),
        ex.TextCellValue('9876543210'),
        ex.TextCellValue('507001'),
        ex.TextCellValue('Welcome to our school.'),
        ex.TextCellValue('Test Principal'),
        ex.TextCellValue('PRIVATE'),
        ex.TextCellValue('Telangana'),
        ex.TextCellValue('ACTIVE'),
        ex.TextCellValue(''),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate School Excel.');
      }

      await FileSaver.instance.saveFile(
        name: 'school_data_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;

      await ExcelImportDialogs.showTemplateDownloaded(
        context,
        entityName: 'School',
      );
    } catch (e) {
      if (!context.mounted) return;

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'School',
        message: _cleanErrorMessage(e),
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
  // IMPORT
  // ============================================================

  Future<void> _importExcel(BuildContext context) async {
    if (_importing) return;

    setState(() {
      _importing = true;
    });

    try {
      debugPrint('========================================');
      debugPrint('SCHOOL EXCEL IMPORT STARTED');
      debugPrint('========================================');

      final pickedFile = await ExcelFilePicker.pick();

      if (pickedFile == null) {
        debugPrint('SCHOOL IMPORT CANCELLED');
        return;
      }

      debugPrint('SCHOOL FILE: ${pickedFile.name}');
      debugPrint(
        'SCHOOL FILE SIZE: ${pickedFile.bytes.length}',
      );

      final data = await _schoolService.importSchoolsExcel(
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      debugPrint('SCHOOL IMPORT API SUCCESS');
      debugPrint('RESPONSE: $data');

      if (!context.mounted) return;

      await _showImportResult(
        context,
        data,
      );
    } catch (e) {
      debugPrint('SCHOOL IMPORT ERROR: $e');

      if (!context.mounted) return;

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'School',
        message: _cleanErrorMessage(e),
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
  // RESULT
  // ============================================================

  Future<void> _showImportResult(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final total = _toInt(data['totalRows']);
    final created = _toInt(data['createdCount']);
    final updated = _toInt(data['updatedCount']);
    final failed = _toInt(data['failedCount']);

    final message = data['message']?.toString() ?? '';

    final errors = _parseErrors(data['errors']);

    if (failed == 0) {
      await ExcelImportDialogs.showSuccess(
        context,
        entityName: 'School',
        total: total,
        created: created,
        updated: updated,
        message: message,
      );
    } else {
      await ExcelImportDialogs.showPartial(
        context,
        entityName: 'School',
        total: total,
        created: created,
        updated: updated,
        failed: failed,
        message: message,
        errors: errors,
      );
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  List<String> _parseErrors(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message.isEmpty
        ? 'Something went wrong.'
        : message;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return _SchoolCard(
      importing: _importing,
      downloading: _downloading,
      onGenerate: () => _generateExcel(context),
      onImport: () => _importExcel(context),
    );
  }
}

// ================================================================
// PREMIUM SCHOOL CARD
// ================================================================

class _SchoolCard extends StatefulWidget {
  final VoidCallback onGenerate;
  final VoidCallback onImport;
  final bool importing;
  final bool downloading;

  const _SchoolCard({
    required this.onGenerate,
    required this.onImport,
    required this.importing,
    required this.downloading,
  });

  @override
  State<_SchoolCard> createState() => _SchoolCardState();
}

class _SchoolCardState extends State<_SchoolCard> {
  bool _hoveringDownload = false;
  bool _hoveringImport = false;

  @override
  Widget build(BuildContext context) {
    final busy = widget.importing || widget.downloading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: busy
              ? const Color(0xFFD6E4FF)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // TOP
          // ------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEFF6FF),
                      Color(0xFFDBEAFE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'School master data',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.importing
                      ? const Color(0xFFFFF7ED)
                      : widget.downloading
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.importing
                            ? const Color(0xFFF97316)
                            : widget.downloading
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.importing
                          ? 'Importing'
                          : widget.downloading
                              ? 'Preparing'
                              : 'Ready',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: widget.importing
                            ? const Color(0xFFEA580C)
                            : widget.downloading
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Download the template, update school details and import the Excel file.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.2,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // ACTIONS
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveringDownload = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveringDownload = false;
                    });
                  },
                  cursor: widget.downloading
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _hoveringDownload &&
                              !widget.downloading
                          ? const [
                              BoxShadow(
                                color: Color(0x202563EB),
                                blurRadius: 9,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: widget.downloading
                          ? null
                          : widget.onGenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF93C5FD),
                        disabledForegroundColor:
                            Colors.white,
                        elevation: 0,
                        minimumSize: const Size(
                          double.infinity,
                          40,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: widget.downloading
                            ? const Row(
                                key: ValueKey('download-loading'),
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Downloading...',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                key: ValueKey('download'),
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Download Sample',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveringImport = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveringImport = false;
                    });
                  },
                  cursor: widget.importing
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _hoveringImport &&
                              !widget.importing
                          ? const [
                              BoxShadow(
                                color: Color(0x142563EB),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: OutlinedButton(
                      onPressed: widget.importing
                          ? null
                          : widget.onImport,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF2563EB),
                        disabledForegroundColor:
                            const Color(0xFF2563EB),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: widget.importing
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFF2563EB),
                        ),
                        minimumSize: const Size(
                          double.infinity,
                          40,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: widget.importing
                            ? const Row(
                                key: ValueKey('import-loading'),
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Color(0xFF2563EB),
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Importing...',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                key: ValueKey('import'),
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Import Excel',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // FOOTER
          // ------------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 13,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 5),
              const Text(
                '.xlsx format supported',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.verified_rounded,
                size: 13,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 4),
              const Text(
                'Secure import',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}