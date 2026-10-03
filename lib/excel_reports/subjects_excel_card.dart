import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/teachers/services/subject_service.dart';
import '../excel_reports/excel_file_picker.dart';
import '../excel_reports/excel_import_dialogs.dart';

class SubjectsExcelCard extends StatefulWidget {
  const SubjectsExcelCard({super.key});

  @override
  State<SubjectsExcelCard> createState() => _SubjectsExcelCardState();
}

class _SubjectsExcelCardState extends State<SubjectsExcelCard> {
  bool _importing = false;
  bool _downloading = false;

  static const int schoolId = 1;

  // ============================================================
  // DOWNLOAD TEMPLATE
  // ============================================================

  Future<void> _generateExcel(BuildContext context) async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      final excel = ex.Excel.createExcel();

      // IMPORTANT:
      // Use the default first sheet and rename it.
      // This prevents an empty Sheet1 from appearing first.
      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception(
          'Unable to create Excel sheet.',
        );
      }

      excel.rename(
        defaultSheet,
        'Subjects',
      );

      final sheet = excel['Subjects'];

      // ========================================================
      // HEADER
      // ========================================================

      sheet.appendRow([
        ex.TextCellValue('code'),
        ex.TextCellValue('name'),
        ex.TextCellValue('description'),
        ex.TextCellValue('status'),
      ]);

      // ========================================================
      // SAMPLE DATA
      // ========================================================

      sheet.appendRow([
        ex.TextCellValue('TEL'),
        ex.TextCellValue('Telugu'),
        ex.TextCellValue('Telugu Language'),
        ex.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('ENG'),
        ex.TextCellValue('English'),
        ex.TextCellValue('English Language'),
        ex.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('MAT'),
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('SCI'),
        ex.TextCellValue('Science'),
        ex.TextCellValue('Science'),
        ex.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('SST'),
        ex.TextCellValue('Social Studies'),
        ex.TextCellValue('Social Studies'),
        ex.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('HIN'),
        ex.TextCellValue('Hindi'),
        ex.TextCellValue('Hindi Language'),
        ex.TextCellValue('ACTIVE'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate Subjects Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'subjects_data_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;

      await ExcelImportDialogs.showTemplateDownloaded(
        context,
        entityName: 'Subjects',
      );
    } catch (e) {
      if (!context.mounted) return;

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'Subjects',
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
      final pickedFile = await ExcelFilePicker.pick();

      if (pickedFile == null) {
        return;
      }

      if (!pickedFile.name
          .toLowerCase()
          .endsWith('.xlsx')) {
        throw Exception(
          'Please select a valid .xlsx Excel file.',
        );
      }

      if (pickedFile.bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected Excel file.',
        );
      }

      final prefs =
          await SharedPreferences.getInstance();

      final token = prefs.getString(
        'jwt_token',
      );

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Session expired. Please login again.',
        );
      }

      final subjectService = SubjectService(
        token,
      );

      final resultData =
          await subjectService.importSubjectsExcel(
        schoolId: schoolId,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      if (!context.mounted) return;

      await _showImportResult(
        context,
        resultData,
      );
    } catch (e) {
      if (!context.mounted) return;

      await ExcelImportDialogs.showFailed(
        context,
        entityName: 'Subjects',
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
    final total = _toInt(
      data['totalRows'],
    );

    final created = _toInt(
      data['createdCount'],
    );

    final updated = _toInt(
      data['updatedCount'],
    );

    final failed = _toInt(
      data['failedCount'],
    );

    final message =
        data['message']?.toString() ?? '';

    final rawErrors = data['errors'];

    final errors = rawErrors is List
        ? rawErrors
            .map(
              (e) => e.toString(),
            )
            .where(
              (e) => e.trim().isNotEmpty,
            )
            .toList()
        : <String>[];

    if (failed == 0) {
      await ExcelImportDialogs.showSuccess(
        context,
        entityName: 'Subjects',
        total: total,
        created: created,
        updated: updated,
        message: message,
      );
    } else {
      await ExcelImportDialogs.showPartial(
        context,
        entityName: 'Subjects',
        total: total,
        created: created,
        updated: updated,
        failed: failed,
        message: message,
        errors: errors,
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception:')) {
      return message
          .substring('Exception:'.length)
          .trim();
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
    return _SubjectsCard(
      importing: _importing,
      downloading: _downloading,
      onGenerate: () => _generateExcel(context),
      onImport: () => _importExcel(context),
    );
  }
}

// ================================================================
// PREMIUM SUBJECTS CARD
// ================================================================

class _SubjectsCard extends StatefulWidget {
  final VoidCallback onGenerate;
  final VoidCallback onImport;
  final bool importing;
  final bool downloading;

  const _SubjectsCard({
    required this.onGenerate,
    required this.onImport,
    required this.importing,
    required this.downloading,
  });

  @override
  State<_SubjectsCard> createState() =>
      _SubjectsCardState();
}

class _SubjectsCardState
    extends State<_SubjectsCard> {
  bool _hovering = false;

  String get _statusText {
    if (widget.downloading) {
      return 'Preparing';
    }

    if (widget.importing) {
      return 'Importing';
    }

    return 'Ready';
  }

  Color get _statusColor {
    if (widget.downloading ||
        widget.importing) {
      return const Color(0xFFD97706);
    }

    return const Color(0xFF059669);
  }

  Color get _statusBackground {
    if (widget.downloading ||
        widget.importing) {
      return const Color(0xFFFFF7ED);
    }

    return const Color(0xFFECFDF5);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 220,
        ),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: _hovering
                ? const Color(0xFFD6E4FF)
                : const Color(0xFFE8ECF2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                _hovering ? 0.075 : 0.035,
              ),
              blurRadius:
                  _hovering ? 22 : 12,
              offset: Offset(
                0,
                _hovering ? 8 : 4,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end: Alignment
                          .bottomRight,
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF4F46E5),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(
                          0xFF2563EB,
                        ).withOpacity(0.20),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Subjects',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Color(
                                  0xFF111827,
                                ),
                                letterSpacing:
                                    -0.2,
                              ),
                            ),
                          ),

                          // STATUS
                          AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 200,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  _statusBackground,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _statusColor,
                                    shape:
                                        BoxShape
                                            .circle,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  _statusText,
                                  style:
                                      TextStyle(
                                    fontSize:
                                        9.5,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    color:
                                        _statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Manage subject records using Excel',
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // INFO STRIP
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                      const Color(0xFFEEF2F7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 15,
                    color:
                        Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Code • Name • Description • Status',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Row(
              children: [
                // DOWNLOAD
                Expanded(
                  child:
                      _PremiumSubjectActionButton(
                    label: widget.downloading
                        ? 'Downloading...'
                        : 'Download Sample',
                    icon:
                        Icons.download_rounded,
                    primary: true,
                    loading:
                        widget.downloading,
                    onPressed:
                        widget.downloading
                            ? null
                            : widget.onGenerate,
                  ),
                ),

                const SizedBox(width: 9),

                // IMPORT
                Expanded(
                  child:
                      _PremiumSubjectActionButton(
                    label: widget.importing
                        ? 'Importing...'
                        : 'Import Excel',
                    icon:
                        Icons.upload_file_rounded,
                    primary: false,
                    loading:
                        widget.importing,
                    onPressed:
                        widget.importing
                            ? null
                            : widget.onImport,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // ==================================================
            // FOOTER
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 13,
                  color:
                      Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                const Text(
                  '.xlsx format supported',
                  style: TextStyle(
                    fontSize: 9.5,
                    color:
                        Color(0xFF94A3B8),
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color:
                      Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Secure import',
                  style: TextStyle(
                    fontSize: 9.5,
                    color:
                        Color(0xFF94A3B8),
                    fontWeight:
                        FontWeight.w500,
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

class _PremiumSubjectActionButton
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool loading;
  final VoidCallback? onPressed;

  const _PremiumSubjectActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF93C5FD),
          disabledForegroundColor:
              Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 180),
          child: Row(
            key: ValueKey(
              loading
                  ? 'loading'
                  : 'normal',
            ),
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 16,
                ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  label,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xFF2563EB),
        disabledForegroundColor:
            const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: loading
              ? const Color(0xFF93C5FD)
              : const Color(0xFFD4DDF0),
          width: 1.1,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 8,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
      child: AnimatedSwitcher(
        duration:
            const Duration(milliseconds: 180),
        child: Row(
          key: ValueKey(
            loading
                ? 'loading'
                : 'normal',
          ),
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 15,
                height: 15,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                icon,
                size: 16,
              ),

            const SizedBox(width: 7),

            Flexible(
              child: Text(
                label,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}