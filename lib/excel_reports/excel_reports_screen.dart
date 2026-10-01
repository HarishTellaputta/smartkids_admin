import 'package:flutter/material.dart';
import '../excel_reports/academic_year_excel_card.dart';
import '../excel_reports/exam_schedule_excel_screen.dart';
import '../features/exams/services/examination_service.dart';
import '../features/exams/models/examination_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'package:smartkids_admin/excel_reports/exam_result_excel_screen.dart';

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
            .where((exam) => exam.status.toUpperCase() == 'PUBLISHED')
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
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            _buildSection(
              title: 'Master Data',
              subtitle: 'Download and import school master data',
              children: [
                const AcademicYearExcelCard(),
                _buildExcelCard(
                  icon: Icons.class_rounded,
                  title: 'Classes',
                  subtitle: 'Classes and sections',
                  onGenerate: () {},
                ),
                _buildExcelCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Subjects',
                  subtitle: 'Subject data',
                  onGenerate: () {},
                ),
                _buildExcelCard(
                  icon: Icons.schedule_rounded,
                  title: 'Timetable',
                  subtitle: 'Generate section-wise timetable template',
                  onGenerate: _generateTimetableExcel,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Examinations',
              subtitle: 'Manage examination Excel files',
              children: [
                _buildExcelCard(
                  icon: Icons.grade_rounded,
                  title: 'Examination',
                  subtitle: 'Generate examination Excel',
                  onGenerate: _generateExaminationExcel,
                ),
                _buildExcelCard(
                  icon: Icons.event_note_rounded,
                  title: 'Exam Schedule',
                  subtitle: 'Generate examination schedule',
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
                  subtitle: 'Generate student-wise marks Excel',
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
                  subtitle: 'Manage percentage and grades',
                  onGenerate: _generateGradeRulesExcel,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: 'MCQ',
              subtitle: 'Manage MCQ related Excel files',
              children: [
                _buildExcelCard(
                  icon: Icons.quiz_rounded,
                  title: 'MCQ Questions',
                  subtitle: 'Import and manage questions',
                  onGenerate: () {},
                ),
                _buildExcelCard(
                  icon: Icons.psychology_rounded,
                  title: 'MCQ Tests',
                  subtitle: 'Import and manage tests',
                  onGenerate: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateExaminationExcel() async {
    try {
      final excel = ex.Excel.createExcel();

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

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Examination Excel.');
      }

      await FileSaver.instance.saveFile(
        name: 'examination_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examination Excel generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate Examination Excel: $e')),
      );
    }
  }

  Future<void> _generateGradeRulesExcel() async {
    try {
      final excel = ex.Excel.createExcel();

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

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Grade Rules Excel.');
      }

      await FileSaver.instance.saveFile(
        name: 'grade_rules_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grade Rules Excel generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate Grade Rules Excel: $e')),
      );
    }
  }

  Future<void> _generateTimetableExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      final sheet = excel['Timetable'];

      // -----------------------------------------------------
      // HEADER
      // -----------------------------------------------------

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

      // -----------------------------------------------------
      // SAMPLE DATA
      // -----------------------------------------------------

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

      // -----------------------------------------------------
      // REMOVE DEFAULT SHEET
      // -----------------------------------------------------

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Timetable Excel.');
      }

      // -----------------------------------------------------
      // SAVE FILE
      // -----------------------------------------------------

      await FileSaver.instance.saveFile(
        name: 'timetable_template',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable Excel template generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate Timetable Excel: $e')),
      );
    }
  }

  Widget _buildExaminationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Examination',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),

        const SizedBox(height: 7),

        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _examinationError != null
                  ? Colors.red.shade300
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: _loadingExaminations
              ? const Row(
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading examinations...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<ExaminationModel>(
                    value: _selectedExamination,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                    ),
                    hint: const Row(
                      children: [
                        Icon(
                          Icons.assignment_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Select examination',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    items: _examinations.map((exam) {
                      return DropdownMenuItem<ExaminationModel>(
                        value: exam,
                        child: Text(
                          exam.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111827),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExamination = value;
                      });
                    },
                  ),
                ),
        ),

        if (_examinationError != null) ...[
          const SizedBox(height: 5),
          Text(
            _examinationError!,
            style: const TextStyle(fontSize: 10, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.table_view_rounded,
              color: Color(0xFF2563EB),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excel Reports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Download templates, update data and import Excel files',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int columns = 1;

              if (width >= 1100) {
                columns = 4;
              } else if (width >= 750) {
                columns = 2;
              }

              final itemWidth = (width - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: children
                    .map((child) => SizedBox(width: itemWidth, child: child))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExcelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onGenerate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Generate Excel',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
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
}
