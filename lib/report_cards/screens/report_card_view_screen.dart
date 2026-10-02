import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';



import '../models/report_card_model.dart';
import '../services/report_card_service.dart';

class ReportCardViewScreen extends StatefulWidget {
  final ReportCardModel reportCard;
  final ReportCardService service;

  const ReportCardViewScreen({
    super.key,
    required this.reportCard,
    required this.service,
  });

  @override
  State<ReportCardViewScreen> createState() => _ReportCardViewScreenState();
}

class _ReportCardViewScreenState extends State<ReportCardViewScreen> {
  bool _downloading = false;
  bool _sharing = false;

  static const _primary = Color(0xFF4F46E5);
  static const _primaryDark = Color(0xFF3730A3);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _background = Color(0xFFF4F6FB);

  ReportCardModel get report => widget.reportCard;

  // ============================================================
  // PDF
  // ============================================================

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final primary = PdfColor.fromHex('#4F46E5');
    final primaryDark = PdfColor.fromHex('#3730A3');
    final text = PdfColor.fromHex('#111827');
    final muted = PdfColor.fromHex('#64748B');
    final border = PdfColor.fromHex('#E2E8F0');
    final light = PdfColor.fromHex('#F8FAFC');
    final headerBg = PdfColor.fromHex('#EEF2FF');
    final green = PdfColor.fromHex('#059669');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            // ==================================================
            // SCHOOL / REPORT HEADER
            // ==================================================

            pw.Container(
              padding: const pw.EdgeInsets.all(22),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    primaryDark,
                    primary,
                  ],
                ),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'STUDENT REPORT CARD',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    report.examinationName ?? 'Academic Examination',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: 55,
                    height: 3,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ==================================================
            // STUDENT INFORMATION
            // ==================================================

            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: light,
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _pdfInfo(
                      'STUDENT',
                      report.studentName,
                      text,
                      muted,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfInfo(
                      'ROLL NUMBER',
                      report.rollNumber ?? '-',
                      text,
                      muted,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfInfo(
                      'CLASS',
                      report.className ?? '-',
                      text,
                      muted,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfInfo(
                      'SECTION',
                      report.sectionName ?? '-',
                      text,
                      muted,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ==================================================
            // SUBJECT PERFORMANCE
            // ==================================================

            pw.Text(
              'Subject Performance',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: text,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(
                color: border,
                width: 0.7,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.6),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: headerBg,
                  ),
                  children: [
                    _pdfCell('SUBJECT', bold: true, color: primaryDark),
                    _pdfCell('EXAM DATE', bold: true, color: primaryDark),
                    _pdfCell('MARKS', bold: true, color: primaryDark),
                    _pdfCell('MAX', bold: true, color: primaryDark),
                    _pdfCell('%', bold: true, color: primaryDark),
                    _pdfCell('GRADE', bold: true, color: primaryDark),
                  ],
                ),
                ...report.subjects.map(
                  (subject) {
                    return pw.TableRow(
                      children: [
                        _pdfCell(subject.subject),
                        _pdfCell(subject.examDate ?? '-'),
                        _pdfCell('${subject.marksObtained ?? '-'}'),
                        _pdfCell('${subject.maximumMarks ?? '-'}'),
                        _pdfCell(
                          subject.percentage == null
                              ? '-'
                              : subject.percentage!.toStringAsFixed(1),
                        ),
                        _pdfCell(subject.grade ?? '-'),
                      ],
                    );
                  },
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            // ==================================================
            // SUMMARY
            // ==================================================

            pw.Text(
              'Overall Performance',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: text,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                _pdfSummaryCard(
                  'TOTAL MARKS',
                  '${report.totalMarks ?? 0} / ${report.totalMaximumMarks ?? 0}',
                  primary,
                  text,
                  muted,
                ),
                pw.SizedBox(width: 8),
                _pdfSummaryCard(
                  'PERCENTAGE',
                  report.percentage == null
                      ? '-'
                      : '${report.percentage!.toStringAsFixed(1)}%',
                  primary,
                  text,
                  muted,
                ),
                pw.SizedBox(width: 8),
                _pdfSummaryCard(
                  'GRADE',
                  report.grade ?? '-',
                  primary,
                  text,
                  muted,
                ),
                pw.SizedBox(width: 8),
                _pdfSummaryCard(
                  'CLASS RANK',
                  '${report.rank ?? '-'}',
                  primary,
                  text,
                  muted,
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            // ==================================================
            // ATTENDANCE
            // ==================================================

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#ECFDF5'),
                border: pw.Border.all(
                  color: PdfColor.fromHex('#A7F3D0'),
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'ATTENDANCE',
                    style: pw.TextStyle(
                      color: green,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    '${report.attendancePresent ?? 0} / ${report.attendanceTotal ?? 0}',
                    style: pw.TextStyle(
                      color: text,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    report.attendancePercentage == null
                        ? '-'
                        : '${report.attendancePercentage!.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      color: green,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 45),

            // ==================================================
            // SIGNATURES
            // ==================================================

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfSignature('Class Teacher', text, muted),
                _pdfSignature('Principal', text, muted),
              ],
            ),

            pw.SizedBox(height: 25),

            pw.Center(
              child: pw.Text(
                'Generated by SmartKids School Management System',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: muted,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfInfo(
    String title,
    String value,
    PdfColor text,
    PdfColor muted,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8,
            color: muted,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: text,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 9,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColor.fromHex('#334155'),
        ),
      ),
    );
  }

  pw.Widget _pdfSummaryCard(
    String title,
    String value,
    PdfColor primary,
    PdfColor text,
    PdfColor muted,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(11),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          border: pw.Border.all(
            color: PdfColor.fromHex('#E2E8F0'),
          ),
          borderRadius: pw.BorderRadius.circular(9),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7,
                color: muted,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                color: text,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSignature(
    String title,
    PdfColor text,
    PdfColor muted,
  ) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        children: [
          pw.SizedBox(height: 25),
          pw.Container(
            height: 1,
            color: PdfColor.fromHex('#CBD5E1'),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              color: text,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
    });

    try {
      final bytes = await _generatePdf();

      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(),
      );

      if (!mounted) return;

      _showMessage(
        'Report card PDF generated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to generate PDF: ${e.toString()}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  String _pdfFileName() {
    final student =
        (report.studentName ?? 'Student')
            .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

    final exam =
        (report.examinationName ?? 'Report_Card')
            .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

    return '${student}_${exam}_Report_Card.pdf';
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> _copyReport() async {
    final text = _buildCopyText();

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    _showMessage('Report card copied to clipboard.');
  }

  String _buildCopyText() {
    final buffer = StringBuffer();

    buffer.writeln('STUDENT REPORT CARD');
    buffer.writeln(
      report.examinationName ?? 'Examination',
    );
    buffer.writeln();

    buffer.writeln(
      'Student: ${report.studentName}',
    );
    buffer.writeln(
      'Roll Number: ${report.rollNumber ?? '-'}',
    );
    buffer.writeln(
      'Class: ${report.className ?? '-'}',
    );
    buffer.writeln(
      'Section: ${report.sectionName ?? '-'}',
    );

    buffer.writeln();
    buffer.writeln('SUBJECT PERFORMANCE');

    for (final subject in report.subjects) {
      buffer.writeln(
        '${subject.subject} | '
        '${subject.marksObtained ?? '-'} / '
        '${subject.maximumMarks ?? '-'} | '
        '${subject.percentage == null ? '-' : subject.percentage!.toStringAsFixed(1)}% | '
        '${subject.grade ?? '-'}',
      );
    }

    buffer.writeln();
    buffer.writeln('OVERALL PERFORMANCE');
    buffer.writeln(
      'Total Marks: ${report.totalMarks ?? 0} / ${report.totalMaximumMarks ?? 0}',
    );
    buffer.writeln(
      'Percentage: ${report.percentage == null ? '-' : '${report.percentage!.toStringAsFixed(1)}%'}',
    );
    buffer.writeln(
      'Grade: ${report.grade ?? '-'}',
    );
    buffer.writeln(
      'Rank: ${report.rank ?? '-'}',
    );

    buffer.writeln();
    buffer.writeln('ATTENDANCE');
    buffer.writeln(
      '${report.attendancePresent ?? 0} / ${report.attendanceTotal ?? 0}'
      ' (${report.attendancePercentage == null ? '-' : '${report.attendancePercentage!.toStringAsFixed(1)}%'})',
    );

    return buffer.toString();
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<void> _shareReport() async {
    if (_sharing) return;

    setState(() {
      _sharing = true;
    });

    try {
      final bytes = await _generatePdf();

      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: _pdfFileName(),
      );

      await SharePlus.instance.share(
        ShareParams(
          text:
              'Student Report Card - ${report.studentName ?? 'Student'}',
          files: [file],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to share report card.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _text,
        elevation: 0,
        surfaceTintColor: Colors.white,

        titleSpacing: 24,

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Report Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        actions: [
          _topAction(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: _copyReport,
          ),
          const SizedBox(width: 8),
          _topAction(
            icon: Icons.share_rounded,
            label: 'Share',
            loading: _sharing,
            onTap: _shareReport,
          ),
          const SizedBox(width: 8),
          _downloadButton(),
          const SizedBox(width: 20),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 1080,
            ),
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                _header(),

                const SizedBox(height: 28),

                _studentInfo(),

                const SizedBox(height: 30),

                _sectionTitle(
                  'Subject Performance',
                  Icons.menu_book_rounded,
                ),

                const SizedBox(height: 12),

                _subjectTable(),

                const SizedBox(height: 30),

                _sectionTitle(
                  'Overall Performance',
                  Icons.insights_rounded,
                ),

                const SizedBox(height: 12),

                _summary(),

                const SizedBox(height: 24),

                _attendance(),

                const SizedBox(height: 55),

                _signatures(),

                const SizedBox(height: 25),

                const Text(
                  'Generated by SmartKids School Management System',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _primaryDark,
            _primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'STUDENT REPORT CARD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            report.examinationName ?? 'Academic Examination',
            style: const TextStyle(
              color: Color(0xFFE0E7FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _studentAvatar(),

          const SizedBox(width: 18),

          Expanded(
            child: _info(
              'Student',
              report.studentName,
            ),
          ),

          Expanded(
            child: _info(
              'Roll Number',
              report.rollNumber ?? '-',
            ),
          ),

          Expanded(
            child: _info(
              'Class',
              report.className ?? '-',
            ),
          ),

          Expanded(
            child: _info(
              'Section',
              report.sectionName ?? '-',
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentAvatar() {
    final name = report.studentName?.trim() ?? '';
    final initial =
        name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _primary,
            _primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _info(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: _muted,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: _text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _subjectTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        border: TableBorder.all(
          color: _border,
          width: .7,
        ),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.3),
          2: FlexColumnWidth(1.1),
          3: FlexColumnWidth(1.1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(.9),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
            ),
            children: [
              _cell('Subject', bold: true),
              _cell('Exam Date', bold: true),
              _cell('Marks', bold: true),
              _cell('Maximum', bold: true),
              _cell('%', bold: true),
              _cell('Grade', bold: true),
            ],
          ),
          ...report.subjects.map(
            (subject) {
              return TableRow(
                children: [
                  _cell(subject.subject),
                  _cell(subject.examDate ?? '-'),
                  _cell('${subject.marksObtained ?? '-'}'),
                  _cell('${subject.maximumMarks ?? '-'}'),
                  _cell(
                    subject.percentage == null
                        ? '-'
                        : subject.percentage!
                            .toStringAsFixed(1),
                  ),
                  _gradeCell(subject.grade ?? '-'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              bold ? FontWeight.w800 : FontWeight.w600,
          color: bold ? _primaryDark : _text,
        ),
      ),
    );
  }

  Widget _gradeCell(String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            grade,
            style: const TextStyle(
              fontSize: 11,
              color: _primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    return Row(
      children: [
        _summaryCard(
          'Total Marks',
          '${report.totalMarks ?? 0} / ${report.totalMaximumMarks ?? 0}',
          Icons.score_rounded,
        ),
        _summaryCard(
          'Percentage',
          report.percentage == null
              ? '-'
              : '${report.percentage!.toStringAsFixed(1)}%',
          Icons.percent_rounded,
        ),
        _summaryCard(
          'Grade',
          report.grade ?? '-',
          Icons.workspace_premium_rounded,
        ),
        _summaryCard(
          'Rank',
          '${report.rank ?? '-'}',
          Icons.emoji_events_rounded,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: _primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Attendance',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF065F46),
            ),
          ),
          const Spacer(),
          Text(
            '${report.attendancePresent ?? 0} / ${report.attendanceTotal ?? 0}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            report.attendancePercentage == null
                ? '-'
                : '${report.attendancePercentage!.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _signature('Class Teacher'),
        _signature('Principal'),
      ],
    );
  }

  Widget _signature(String title) {
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          const SizedBox(height: 25),
          Container(
            height: 1,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP ACTIONS
  // ============================================================

  Widget _topAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Icon(
              icon,
              size: 17,
            ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(
          color: _border,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }

  Widget _downloadButton() {
    return ElevatedButton.icon(
      onPressed: _downloading ? null : _downloadPdf,
      icon: _downloading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
            ),
      label: Text(
        _downloading ? 'Generating...' : 'Download PDF',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? const Color(0xFFDC2626) : const Color(0xFF111827),
        content: Text(message),
      ),
    );
  }
}