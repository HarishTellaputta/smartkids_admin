import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/excel_reports/exam_result_excel_screen.dart';

import '../excel_reports/academic_year_excel_card.dart';
import '../excel_reports/classes_excel_card.dart';
import '../excel_reports/exam_schedule_excel_screen.dart';
import '../excel_reports/school_excel_card.dart';
import '../excel_reports/sections_excel_card.dart';
import '../excel_reports/subjects_excel_card.dart';
import '../features/exams/models/examination_model.dart';
import '../features/exams/services/examination_service.dart';

class ExcelReportsScreen extends StatefulWidget {
  const ExcelReportsScreen({super.key});

  @override
  State<ExcelReportsScreen> createState() => _ExcelReportsScreenState();
}

class _ExcelReportsScreenState extends State<ExcelReportsScreen> {
  List<ExaminationModel> _examinations = [];

  ExaminationModel? _selectedExamination;

  bool _loadingExaminations = false;
  String? _examinationError;

  @override
  void initState() {
    super.initState();
    _loadExaminations();
  }

  Future<void> _loadExaminations() async {
    setState(() {
      _loadingExaminations = true;
      _examinationError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = ExaminationService(token);
      final data = await service.getExaminations();

      if (!mounted) return;

      setState(() {
        _examinations = data
            .where(
              (exam) => exam.status.toUpperCase() == 'PUBLISHED',
            )
            .toList();

        _loadingExaminations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingExaminations = false;
        _examinationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),

            const SizedBox(height: 20),

            _buildQuickStats(),

            const SizedBox(height: 26),

            _buildSection(
              title: 'Master Data',
              subtitle:
                  'Download templates and manage school master data through Excel',
              icon: Icons.account_tree_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBackground: const Color(0xFFEFF6FF),
              badge: '5 Modules',
              children: [
                const AcademicYearExcelCard(),
                SchoolExcelCard(),
                const ClassesExcelCard(),
                const SectionsExcelCard(),
                const SubjectsExcelCard(),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Academic & Examination',
              subtitle:
                  'Create examination, schedule and academic configuration files',
              icon: Icons.school_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBackground: const Color(0xFFF5F3FF),
              badge: '4 Modules',
              children: [
                _buildExcelCard(
                  icon: Icons.schedule_rounded,
                  title: 'Timetable',
                  subtitle: 'Generate section-wise timetable template',
                  buttonText: 'Generate Excel',
                  iconColor: const Color(0xFF7C3AED),
                  iconBackground: const Color(0xFFF5F3FF),
                  onGenerate: _generateTimetableExcel,
                ),
                _buildExcelCard(
                  icon: Icons.assignment_rounded,
                  title: 'Examination',
                  subtitle: 'Create examination master data',
                  buttonText: 'Generate Excel',
                  iconColor: const Color(0xFF2563EB),
                  iconBackground: const Color(0xFFEFF6FF),
                  onGenerate: _generateExaminationExcel,
                ),
                _buildExcelCard(
                  icon: Icons.event_note_rounded,
                  title: 'Exam Schedule',
                  subtitle: 'Create examination schedule template',
                  buttonText: 'Open Manager',
                  iconColor: const Color(0xFF0891B2),
                  iconBackground: const Color(0xFFECFEFF),
                  onGenerate: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExamScheduleExcelScreen(),
                      ),
                    );
                  },
                ),
                _buildExcelCard(
                  icon: Icons.fact_check_rounded,
                  title: 'Exam Results',
                  subtitle: 'Manage student-wise marks Excel',
                  buttonText: 'Open Manager',
                  iconColor: const Color(0xFF059669),
                  iconBackground: const Color(0xFFECFDF5),
                  onGenerate: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamResultExcelScreen(),
                      ),
                    );
                  },
                ),
                _buildExcelCard(
                  icon: Icons.grade_rounded,
                  title: 'Grade Rules',
                  subtitle: 'Manage percentage and grade ranges',
                  buttonText: 'Generate Excel',
                  iconColor: const Color(0xFFD97706),
                  iconBackground: const Color(0xFFFFFBEB),
                  onGenerate: _generateGradeRulesExcel,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'MCQ & Student Data',
              subtitle:
                  'Prepare question banks and student information for bulk import',
              icon: Icons.quiz_rounded,
              iconColor: const Color(0xFFDB2777),
              iconBackground: const Color(0xFFFDF2F8),
              badge: '2 Modules',
              children: [
                _buildExcelCard(
                  icon: Icons.quiz_rounded,
                  title: 'MCQ Questions',
                  subtitle: 'Download MCQ question import template',
                  buttonText: 'Generate Excel',
                  iconColor: const Color(0xFFDB2777),
                  iconBackground: const Color(0xFFFDF2F8),
                  onGenerate: _generateMcqQuestionsExcel,
                ),
                _buildExcelCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Student Data',
                  subtitle: 'Download student import template',
                  buttonText: 'Generate Excel',
                  iconColor: const Color(0xFFEA580C),
                  iconBackground: const Color(0xFFFFF7ED),
                  onGenerate: _generateStudentDataExcel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREMIUM HEADER
  // ============================================================

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x252563EB),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.table_chart_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 17),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excel Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Download templates, manage bulk data and simplify school administration',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          if (_loadingExaminations)
            _buildHeaderStatus(
              icon: Icons.sync_rounded,
              text: 'Syncing',
              color: const Color(0xFF2563EB),
            )
          else
            _buildHeaderStatus(
              icon: Icons.cloud_done_rounded,
              text: 'Ready',
              color: const Color(0xFF059669),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  Widget _buildQuickStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = 4;

        if (width < 900) {
          columns = 2;
        }

        if (width < 520) {
          columns = 1;
        }

        final itemWidth =
            (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                icon: Icons.folder_copy_rounded,
                title: 'Master Data',
                value: '5',
                subtitle: 'Excel modules',
                iconColor: const Color(0xFF2563EB),
                background: const Color(0xFFEFF6FF),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                icon: Icons.assignment_rounded,
                title: 'Examinations',
                value: '5',
                subtitle: 'Excel modules',
                iconColor: const Color(0xFF7C3AED),
                background: const Color(0xFFF5F3FF),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                icon: Icons.quiz_rounded,
                title: 'MCQ',
                value: '2',
                subtitle: 'Import modules',
                iconColor: const Color(0xFFDB2777),
                background: const Color(0xFFFDF2F8),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                icon: Icons.cloud_done_rounded,
                title: 'System',
                value: 'Ready',
                subtitle: 'Excel services',
                iconColor: const Color(0xFF059669),
                background: const Color(0xFFECFDF5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String badge,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int columns = 1;

              if (width >= 1150) {
                columns = 3;
              } else if (width >= 700) {
                columns = 2;
              }

              final itemWidth =
                  (width - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: children
                    .map(
                      (child) => SizedBox(
                        width: itemWidth,
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXCEL CARD
  // ============================================================

  Widget _buildExcelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onGenerate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: Icon(
                buttonText == 'Open Manager'
                    ? Icons.open_in_new_rounded
                    : Icons.download_rounded,
                size: 15,
              ),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MCQ EXCEL
  // ============================================================

  Future<void> _generateMcqQuestionsExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'MCQ Questions');

      final sheet = excel['MCQ Questions'];

      sheet.appendRow([
        ex.TextCellValue('Subject'),
        ex.TextCellValue('Class'),
        ex.TextCellValue('Question'),
        ex.TextCellValue('Option A'),
        ex.TextCellValue('Option B'),
        ex.TextCellValue('Option C'),
        ex.TextCellValue('Option D'),
        ex.TextCellValue('Correct Answer'),
        ex.TextCellValue('Marks'),
        ex.TextCellValue('Explanation'),
        ex.TextCellValue('Question Date'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('1st Class'),
        ex.TextCellValue('What is 2 + 2?'),
        ex.TextCellValue('3'),
        ex.TextCellValue('4'),
        ex.TextCellValue('5'),
        ex.TextCellValue('6'),
        ex.TextCellValue('B'),
        ex.IntCellValue(1),
        ex.TextCellValue('2 + 2 = 4'),
        ex.TextCellValue('01-10-2026'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('1st Class'),
        ex.TextCellValue('What is 5 + 3?'),
        ex.TextCellValue('7'),
        ex.TextCellValue('8'),
        ex.TextCellValue('9'),
        ex.TextCellValue('10'),
        ex.TextCellValue('B'),
        ex.IntCellValue(1),
        ex.TextCellValue('5 + 3 = 8'),
        ex.TextCellValue('01-10-2026'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('1st Class'),
        ex.TextCellValue('What is 10 - 4?'),
        ex.TextCellValue('5'),
        ex.TextCellValue('6'),
        ex.TextCellValue('7'),
        ex.TextCellValue('8'),
        ex.TextCellValue('B'),
        ex.IntCellValue(1),
        ex.TextCellValue('10 - 4 = 6'),
        ex.TextCellValue('01-10-2026'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate MCQ Questions Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'mcq_questions_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      _showSuccess(
        'MCQ Questions Excel generated successfully',
      );
    } catch (e) {
      _showError(
        'Failed to generate MCQ Questions Excel: $e',
      );
    }
  }

  // ============================================================
  // STUDENT EXCEL
  // ============================================================

  Future<void> _generateStudentDataExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'Students');

      final sheet = excel['Students'];

      sheet.appendRow([
        ex.TextCellValue('rollNumber'),
        ex.TextCellValue('admissionNo'),
        ex.TextCellValue('name'),
        ex.TextCellValue('email'),
        ex.TextCellValue('phone'),
        ex.TextCellValue('dateOfBirth'),
        ex.TextCellValue('gender'),
        ex.TextCellValue('bloodGroup'),
        ex.TextCellValue('admissionDate'),
        ex.TextCellValue('address'),
        ex.TextCellValue('className'),
        ex.TextCellValue('sectionName'),
        ex.TextCellValue('academicYear'),
        ex.TextCellValue('status'),
        ex.TextCellValue('fatherName'),
        ex.TextCellValue('motherName'),
        ex.TextCellValue('guardianName'),
        ex.TextCellValue('parentPhone'),
        ex.TextCellValue('parentEmail'),
        ex.TextCellValue('relationship'),
        ex.TextCellValue('parentAddress'),
        ex.TextCellValue('transportRequired'),
      ]);

      sheet.appendRow([
        ex.IntCellValue(1),
        ex.TextCellValue('ADM2026011'),
        ex.TextCellValue('Arjun Reddy'),
        ex.TextCellValue('arjunreddy41@student.example.com'),
        ex.TextCellValue('9000000241'),
        ex.TextCellValue('03-01-2015'),
        ex.TextCellValue('Male'),
        ex.TextCellValue('O+'),
        ex.TextCellValue('01-06-2026'),
        ex.TextCellValue('Khammam'),
        ex.TextCellValue('4th Class'),
        ex.TextCellValue('A'),
        ex.TextCellValue('2026-2027'),
        ex.TextCellValue('ACTIVE'),
        ex.TextCellValue('Rajesh Reddy'),
        ex.TextCellValue('Sunitha Reddy'),
        ex.TextCellValue(''),
        ex.TextCellValue('9000000241'),
        ex.TextCellValue('rajeshreddy41@example.com'),
        ex.TextCellValue('Father'),
        ex.TextCellValue('Khammam'),
        ex.TextCellValue('TRUE'),
      ]);

      sheet.appendRow([
        ex.IntCellValue(2),
        ex.TextCellValue('ADM2026012'),
        ex.TextCellValue('Kavya Reddy'),
        ex.TextCellValue('kavyareddy42@student.example.com'),
        ex.TextCellValue('9000000242'),
        ex.TextCellValue('06-02-2015'),
        ex.TextCellValue('Female'),
        ex.TextCellValue('A+'),
        ex.TextCellValue('02-06-2026'),
        ex.TextCellValue('Khammam'),
        ex.TextCellValue('4th Class'),
        ex.TextCellValue('A'),
        ex.TextCellValue('2026-2027'),
        ex.TextCellValue('ACTIVE'),
        ex.TextCellValue('Suresh Reddy'),
        ex.TextCellValue('Lakshmi Reddy'),
        ex.TextCellValue(''),
        ex.TextCellValue('9000000242'),
        ex.TextCellValue('sureshreddy42@example.com'),
        ex.TextCellValue('Father'),
        ex.TextCellValue('Khammam'),
        ex.TextCellValue('FALSE'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate Student Data Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'student_data_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      _showSuccess(
        'Student Data Excel template generated successfully',
      );
    } catch (e) {
      _showError(
        'Failed to generate Student Data Excel: $e',
      );
    }
  }

  // ============================================================
  // EXAMINATION
  // ============================================================

  Future<void> _generateExaminationExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'Examination');

      final sheet = excel['Examination'];

      sheet.appendRow([
        ex.TextCellValue('name'),
        ex.TextCellValue('academicYear'),
        ex.TextCellValue('startDate'),
        ex.TextCellValue('endDate'),
        ex.TextCellValue('description'),
        ex.TextCellValue('status'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Annual Examination'),
        ex.TextCellValue('2026-2027'),
        ex.TextCellValue('2027-03-01'),
        ex.TextCellValue('2027-03-20'),
        ex.TextCellValue('Annual Examination'),
        ex.TextCellValue('DRAFT'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate Examination Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'examination_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      _showSuccess(
        'Examination Excel generated successfully',
      );
    } catch (e) {
      _showError(
        'Failed to generate Examination Excel: $e',
      );
    }
  }

  // ============================================================
  // GRADE RULES
  // ============================================================

  Future<void> _generateGradeRulesExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'Grade Rules');

      final sheet = excel['Grade Rules'];

      sheet.appendRow([
        ex.TextCellValue('grade'),
        ex.TextCellValue('minPercentage'),
        ex.TextCellValue('maxPercentage'),
        ex.TextCellValue('description'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('A+'),
        ex.DoubleCellValue(90),
        ex.DoubleCellValue(100),
        ex.TextCellValue('Outstanding'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('A'),
        ex.DoubleCellValue(80),
        ex.DoubleCellValue(89.99),
        ex.TextCellValue('Excellent'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('B+'),
        ex.DoubleCellValue(70),
        ex.DoubleCellValue(79.99),
        ex.TextCellValue('Very Good'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('B'),
        ex.DoubleCellValue(60),
        ex.DoubleCellValue(69.99),
        ex.TextCellValue('Good'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('C'),
        ex.DoubleCellValue(50),
        ex.DoubleCellValue(59.99),
        ex.TextCellValue('Average'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('D'),
        ex.DoubleCellValue(35),
        ex.DoubleCellValue(49.99),
        ex.TextCellValue('Pass'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('F'),
        ex.DoubleCellValue(0),
        ex.DoubleCellValue(34.99),
        ex.TextCellValue('Fail'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate Grade Rules Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'grade_rules_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      _showSuccess(
        'Grade Rules Excel generated successfully',
      );
    } catch (e) {
      _showError(
        'Failed to generate Grade Rules Excel: $e',
      );
    }
  }

  // ============================================================
  // TIMETABLE
  // ============================================================

  Future<void> _generateTimetableExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet == null) {
        throw Exception('Unable to create Excel sheet.');
      }

      excel.rename(defaultSheet, 'Timetable');

      final sheet = excel['Timetable'];

      sheet.appendRow([
        ex.TextCellValue('Teacher'),
        ex.TextCellValue('Class'),
        ex.TextCellValue('Section'),
        ex.TextCellValue('Subject'),
        ex.TextCellValue('Day'),
        ex.TextCellValue('Start Time'),
        ex.TextCellValue('End Time'),
        ex.TextCellValue('Room Number'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Ravi Kumar'),
        ex.TextCellValue('10th Class'),
        ex.TextCellValue('A'),
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('MONDAY'),
        ex.TextCellValue('09:00'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('101'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Suresh Kumar'),
        ex.TextCellValue('10th'),
        ex.TextCellValue('A'),
        ex.TextCellValue('Science'),
        ex.TextCellValue('MONDAY'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('11:00'),
        ex.TextCellValue('101'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Ravi Kumar'),
        ex.TextCellValue('10th'),
        ex.TextCellValue('B'),
        ex.TextCellValue('Mathematics'),
        ex.TextCellValue('MONDAY'),
        ex.TextCellValue('09:00'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('102'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Anil Kumar'),
        ex.TextCellValue('10th'),
        ex.TextCellValue('B'),
        ex.TextCellValue('Science'),
        ex.TextCellValue('MONDAY'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('11:00'),
        ex.TextCellValue('102'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Ravi Kumar'),
        ex.TextCellValue('10th'),
        ex.TextCellValue('A'),
        ex.TextCellValue('English'),
        ex.TextCellValue('TUESDAY'),
        ex.TextCellValue('09:00'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('101'),
      ]);

      sheet.appendRow([
        ex.TextCellValue('Anil Kumar'),
        ex.TextCellValue('10th'),
        ex.TextCellValue('B'),
        ex.TextCellValue('English'),
        ex.TextCellValue('TUESDAY'),
        ex.TextCellValue('09:00'),
        ex.TextCellValue('10:00'),
        ex.TextCellValue('102'),
      ]);

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception(
          'Failed to generate Timetable Excel.',
        );
      }

      await FileSaver.instance.saveFile(
        name: 'timetable_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      _showSuccess(
        'Timetable Excel template generated successfully',
      );
    } catch (e) {
      _showError(
        'Failed to generate Timetable Excel: $e',
      );
    }
  }

  // ============================================================
  // SNACKBAR HELPERS
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          margin: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF16A34A),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          margin: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}