import 'dart:typed_data';

import 'package:flutter/material.dart';

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

  Future<void> _download() async {
    setState(() => _downloading = true);

    try {
      await widget.service.downloadReportCard(
        studentId: widget.reportCard.studentId!,
        examinationId: widget.reportCard.examinationId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report card downloaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  void _showDownloadInfo(List<int> bytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report generated successfully (${bytes.length} bytes).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.reportCard;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      appBar: AppBar(
        title: const Text(
          'Report Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.all(35),
            color: Colors.white,
            child: Column(
              children: [
                _header(report),
                const SizedBox(height: 30),

                _studentInfo(report),

                const SizedBox(height: 28),

                _subjectTable(report),

                const SizedBox(height: 28),

                _summary(report),

                const SizedBox(height: 28),

                _attendance(report),

                const SizedBox(height: 45),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Class Teacher',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Principal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ReportCardModel report) {
    return Column(
      children: [
        const Text(
          'STUDENT REPORT CARD',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          report.examinationName ?? 'Examination',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _studentInfo(ReportCardModel report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _info('Student', report.studentName),
          _info('Roll Number', report.rollNumber ?? '-'),
          _info('Class', report.className ?? '-'),
          _info('Section', report.sectionName ?? '-'),
        ],
      ),
    );
  }

  Widget _info(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectTable(ReportCardModel report) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE2E8F0)),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.3),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.1),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          children: [
            _cell('Subject', bold: true),
            _cell('Exam Date', bold: true),
            _cell('Marks', bold: true),
            _cell('Maximum', bold: true),
            _cell('%', bold: true),
            _cell('Grade', bold: true),
          ],
        ),
        ...report.subjects.map((subject) {
          return TableRow(
            children: [
              _cell(subject.subject),
              _cell(subject.examDate ?? '-'),
              _cell('${subject.marksObtained ?? '-'}'),
              _cell('${subject.maximumMarks ?? '-'}'),
              _cell(
                subject.percentage == null
                    ? '-'
                    : subject.percentage!.toStringAsFixed(1),
              ),
              _cell(subject.grade ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _summary(ReportCardModel report) {
    return Row(
      children: [
        _summaryCard(
          'Total Marks',
          '${report.totalMarks ?? 0} / ${report.totalMaximumMarks ?? 0}',
        ),
        _summaryCard(
          'Percentage',
          report.percentage == null
              ? '-'
              : '${report.percentage!.toStringAsFixed(1)}%',
        ),
        _summaryCard('Grade', report.grade ?? '-'),
        _summaryCard('Rank', '${report.rank ?? '-'}'),
      ],
    );
  }

  Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendance(ReportCardModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Color(0xFF059669)),
          const SizedBox(width: 12),
          const Text(
            'Attendance',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            '${report.attendancePresent ?? 0} / ${report.attendanceTotal ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 20),
          Text(
            report.attendancePercentage == null
                ? '-'
                : '${report.attendancePercentage!.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
