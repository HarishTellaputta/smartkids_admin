import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../models/examination_model.dart';
import '../models/exam_result_model.dart';
import '../models/exam_schedule_model.dart';
import '../services/examination_service.dart';
import '/report_cards/services/report_card_service.dart';
import '/report_cards/screens/report_card_view_screen.dart';

class ExamResultsScreen extends StatefulWidget {
  final ExaminationModel exam;
  final List<ExamScheduleModel> schedules;
  final List<ExamResultResponseModel> results;
  final ExaminationService service;
  final ReportCardService reportCardService;
  final Future<void> Function()? onChanged;

  const ExamResultsScreen({
    super.key,
    required this.exam,
    required this.schedules,
    required this.results,
    required this.service,
    required this.reportCardService,
    this.onChanged,
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  late List<ExamResultResponseModel> results;

  List<ExamScheduleModel> schedules = [];

  bool loadingSchedules = true;
  bool downloadingAll = false;

  String? errorMessage;

  int? selectedClassId;
  int? selectedSectionId;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    results = List.from(widget.results);

    _loadSchedules();
  }

  // ============================================================
  // LOAD SCHEDULES
  // ============================================================

  Future<void> _loadSchedules() async {
    try {
      setState(() {
        loadingSchedules = true;
        errorMessage = null;
      });

      final examinationId = widget.exam.id;

      if (examinationId == null) {
        throw Exception('Examination ID is missing.');
      }

      final loadedSchedules = await widget.service.getSchedulesByExamination(
        examinationId,
      );

      if (!mounted) return;

      setState(() {
        schedules = loadedSchedules;
        loadingSchedules = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingSchedules = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // SCHEDULE MAP
  // ============================================================

  Map<int, ExamScheduleModel> get scheduleMap {
    final map = <int, ExamScheduleModel>{};

    for (final schedule in schedules) {
      if (schedule.id != null) {
        map[schedule.id!] = schedule;
      }
    }

    return map;
  }

  // ============================================================
  // CLASS OPTIONS
  // ============================================================

  List<ExamScheduleModel> get classOptions {
    final map = <int, ExamScheduleModel>{};

    for (final schedule in schedules) {
      if (schedule.classId == null) continue;

      map.putIfAbsent(schedule.classId!, () => schedule);
    }

    final list = map.values.toList();

    list.sort((a, b) => _naturalCompare(a.className, b.className));

    return list;
  }

  // ============================================================
  // SECTION OPTIONS
  // ============================================================

  List<ExamScheduleModel> get sectionOptions {
    final map = <int, ExamScheduleModel>{};

    for (final schedule in schedules) {
      if (selectedClassId != null && schedule.classId != selectedClassId) {
        continue;
      }

      if (schedule.sectionId == null) continue;

      map.putIfAbsent(schedule.sectionId!, () => schedule);
    }

    final list = map.values.toList();

    list.sort((a, b) => _naturalCompare(a.sectionName, b.sectionName));

    return list;
  }

  // ============================================================
  // FILTERED SCHEDULES
  // ============================================================

  List<ExamScheduleModel> get filteredSchedules {
    return schedules.where((schedule) {
      if (selectedClassId != null && schedule.classId != selectedClassId) {
        return false;
      }

      if (selectedSectionId != null &&
          schedule.sectionId != selectedSectionId) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============================================================
  // FILTERED RESULTS
  // ============================================================

  List<ExamResultResponseModel> get filteredResults {
    final allowedScheduleIds = filteredSchedules
        .map((e) => e.id)
        .whereType<int>()
        .toSet();

    final query = searchQuery.trim().toLowerCase();

    return results.where((result) {
      if (allowedScheduleIds.isNotEmpty &&
          !allowedScheduleIds.contains(result.examScheduleId)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final studentName = result.studentName?.toLowerCase() ?? '';

      final rollNumber = result.studentRollNumber?.toLowerCase() ?? '';

      final grade = result.grade?.toLowerCase() ?? '';

      return studentName.contains(query) ||
          rollNumber.contains(query) ||
          grade.contains(query);
    }).toList();
  }

  // ============================================================
  // SUBJECTS
  // ============================================================

  List<String> get subjects {
    final subjectNames = <String>{};

    for (final schedule in filteredSchedules) {
      final subject = schedule.subjectName.trim();

      if (subject.isNotEmpty) {
        subjectNames.add(subject);
      }
    }

    final list = subjectNames.toList();

    const preferredOrder = [
      'Telugu',
      'English',
      'Maths',
      'Mathematics',
      'Science',
      'Social',
      'Social Science',
      'Hindi',
    ];

    list.sort((a, b) {
      final ai = preferredOrder.indexWhere(
        (e) => e.toLowerCase() == a.toLowerCase(),
      );

      final bi = preferredOrder.indexWhere(
        (e) => e.toLowerCase() == b.toLowerCase(),
      );

      if (ai != -1 && bi != -1) {
        return ai.compareTo(bi);
      }

      if (ai != -1) return -1;
      if (bi != -1) return 1;

      return _naturalCompare(a, b);
    });

    return list;
  }

  // ============================================================
  // STUDENT ROWS
  // ============================================================

  List<_StudentResultRow> get studentRows {
    final map = <int, _StudentResultRow>{};

    final scheduleLookup = scheduleMap;

    for (final result in filteredResults) {
      final schedule = scheduleLookup[result.examScheduleId];

      if (schedule == null) continue;

      final row = map.putIfAbsent(
        result.studentId,
        () => _StudentResultRow(
          studentId: result.studentId,
          studentName: result.studentName ?? '-',
          rollNumber: result.studentRollNumber ?? '-',
        ),
      );

      row.subjectMarks[schedule.subjectName] = _SubjectMark(
        subjectName: schedule.subjectName,
        marksObtained: result.marksObtained,
        maxMarks: result.maxMarks,
        percentage: result.percentage,
        grade: result.grade,
      );

      row.results.add(result);
    }

    final rows = map.values.toList();

    // ==========================================================
    // IMPORTANT:
    // Numeric roll number sorting.
    //
    // 1, 2, 3 ... 9, 10, 11
    // NOT
    // 1, 10, 11, 2, 3
    // ==========================================================

    rows.sort((a, b) => _compareRollNumbers(a.rollNumber, b.rollNumber));

    return rows;
  }

  // ============================================================
  // NUMERIC ROLL NUMBER SORT
  // ============================================================

  int _compareRollNumbers(String a, String b) {
    final aValue = int.tryParse(a.trim());

    final bValue = int.tryParse(b.trim());

    if (aValue != null && bValue != null) {
      return aValue.compareTo(bValue);
    }

    if (aValue != null) return -1;
    if (bValue != null) return 1;

    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  // ============================================================
  // NATURAL SORT
  // ============================================================

  int _naturalCompare(String a, String b) {
    final aa = a.toLowerCase().trim();
    final bb = b.toLowerCase().trim();

    final aNum = int.tryParse(aa);
    final bNum = int.tryParse(bb);

    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }

    return aa.compareTo(bb);
  }

  // ============================================================
  // TOTAL
  // ============================================================

  int totalMarks(_StudentResultRow student) {
    return student.subjectMarks.values.fold(
      0,
      (sum, mark) => sum + mark.marksObtained,
    );
  }

  // ============================================================
  // MAX MARKS
  // ============================================================

  int totalMaximumMarks(_StudentResultRow student) {
    return student.subjectMarks.values.fold(
      0,
      (sum, mark) => sum + mark.maxMarks,
    );
  }

  // ============================================================
  // PERCENTAGE
  // ============================================================

  double? percentage(_StudentResultRow student) {
    final total = totalMarks(student);
    final maximum = totalMaximumMarks(student);

    if (maximum <= 0) {
      return null;
    }

    return total / maximum * 100;
  }

  // ============================================================
  // GRADE
  // ============================================================

  String grade(_StudentResultRow student) {
    final grades = student.results
        .map((e) => e.grade)
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (grades.isNotEmpty && grades.toSet().length == 1) {
      return grades.first;
    }

    final value = percentage(student);

    if (value == null) return '-';

    if (value >= 90) return 'A+';
    if (value >= 80) return 'A';
    if (value >= 70) return 'B+';
    if (value >= 60) return 'B';
    if (value >= 50) return 'C';
    if (value >= 40) return 'D';

    return 'F';
  }

  // ============================================================
  // PUBLISHED
  // ============================================================

  int get publishedCount {
    return filteredResults.where((e) => e.isPublished).length;
  }

  // ============================================================
  // PENDING
  // ============================================================

  int get pendingCount {
    return filteredResults.where((e) => !e.isPublished).length;
  }

  // ============================================================
  // DOWNLOAD REPORT CARD PDF
  // ============================================================

  Future<void> _downloadReportCard(_StudentResultRow student) async {
    try {
      final examinationId = widget.exam.id;

      if (examinationId == null) {
        throw Exception('Examination ID is missing.');
      }

      // Get complete report-card data from backend
      final reportCard = await widget.reportCardService.getReportCard(
        studentId: student.studentId,
        examinationId: examinationId,
      );

      if (!mounted) return;

      // Open the existing Report Card screen.
      // That screen already generates the real PDF.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportCardViewScreen(
            reportCard: reportCard,
            service: widget.reportCardService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
  // ============================================================
  // DOWNLOAD ALL RESULTS
  // ============================================================

  Future<void> _downloadAllResults() async {
    if (downloadingAll) return;

    final rows = studentRows;

    if (rows.isEmpty) {
      _showMessage(
        'No results available for the selected filters.',
        error: true,
      );
      return;
    }

    setState(() {
      downloadingAll = true;
    });

    try {
      final csvRows = <List<String>>[];

      csvRows.add([
        'Roll Number',
        'Student Name',
        ...subjects,
        'Total Marks',
        'Maximum Marks',
        'Percentage',
        'Grade',
      ]);

      for (final student in rows) {
        final studentPercentage = percentage(student);

        csvRows.add([
          student.rollNumber,
          student.studentName,

          ...subjects.map((subject) {
            final mark = student.subjectMarks[subject];

            return mark == null ? '-' : mark.marksObtained.toString();
          }),

          totalMarks(student).toString(),
          totalMaximumMarks(student).toString(),

          studentPercentage == null
              ? '-'
              : studentPercentage.toStringAsFixed(1),

          grade(student),
        ]);
      }

      final csv = csvRows
          .map((row) => row.map(_escapeCsv).join(','))
          .join('\r\n');

      final bytes = utf8.encode('\uFEFF$csv');

      final blob = html.Blob(<dynamic>[bytes], 'text/csv;charset=utf-8');

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..download = _resultsFileName()
        ..style.display = 'none';

      html.document.body?.children.add(anchor);

      anchor.click();

      anchor.remove();

      html.Url.revokeObjectUrl(url);

      if (!mounted) return;

      _showMessage('${rows.length} student results downloaded successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to download results.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          downloadingAll = false;
        });
      }
    }
  }

  // ============================================================
  // CSV ESCAPE
  // ============================================================

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');

    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }

    return escaped;
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  String _resultsFileName() {
    final examName = widget.exam.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final className = _selectedClassName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]+'),
      '_',
    );

    final sectionName = _selectedSectionName.replaceAll(
      RegExp(r'[^a-zA-Z0-9]+'),
      '_',
    );

    return '${examName}_${className}_${sectionName}_Results.csv';
  }

  // ============================================================
  // SELECTED CLASS NAME
  // ============================================================

  String get _selectedClassName {
    if (selectedClassId == null) {
      return 'All_Classes';
    }

    for (final schedule in classOptions) {
      if (schedule.classId == selectedClassId) {
        return schedule.className;
      }
    }

    return 'Class';
  }

  // ============================================================
  // SELECTED SECTION NAME
  // ============================================================

  String get _selectedSectionName {
    if (selectedSectionId == null) {
      return 'All_Sections';
    }

    for (final schedule in sectionOptions) {
      if (schedule.sectionId == selectedSectionId) {
        return schedule.sectionName;
      }
    }

    return 'Section';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.assessment_rounded,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exam.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Examination Results',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadingSchedules ? null : _loadSchedules,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loadingSchedules
          ? _loading()
          : errorMessage != null
          ? _error()
          : _body(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _filters(),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 14),
          Expanded(
            child: studentRows.isEmpty ? _emptyState() : _resultsTable(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<int?>(
              value: selectedClassId,
              decoration: InputDecoration(
                labelText: 'Class',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Classes'),
                ),
                ...classOptions.map(
                  (schedule) => DropdownMenuItem<int?>(
                    value: schedule.classId,
                    child: Text(schedule.className),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedClassId = value;
                  selectedSectionId = null;
                });
              },
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 210,
            child: DropdownButtonFormField<int?>(
              value: selectedSectionId,
              decoration: InputDecoration(
                labelText: 'Section',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Sections'),
                ),
                ...sectionOptions.map(
                  (schedule) => DropdownMenuItem<int?>(
                    value: schedule.sectionId,
                    child: Text(schedule.sectionName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSectionId = value;
                });
              },
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search student / roll number / grade...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton.icon(
            onPressed: downloadingAll || studentRows.isEmpty
                ? null
                : _downloadAllResults,
            icon: downloadingAll
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(downloadingAll ? 'Downloading...' : 'Download Results'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summaryCards() {
    return Row(
      children: [
        _summary(
          'Students',
          '${studentRows.length}',
          Icons.people_outline,
          const Color(0xFF2563EB),
        ),
        const SizedBox(width: 10),
        _summary(
          'Subjects',
          '${subjects.length}',
          Icons.menu_book_outlined,
          const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 10),
        _summary(
          'Published',
          '$publishedCount',
          Icons.check_circle_outline,
          const Color(0xFF16A34A),
        ),
        const SizedBox(width: 10),
        _summary(
          'Pending',
          '$pendingCount',
          Icons.pending_actions_outlined,
          const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _summary(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.14)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _resultsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
              dataRowMinHeight: 58,
              dataRowMaxHeight: 65,
              columns: [
                const DataColumn(
                  label: Text(
                    'Roll Number',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Student Name',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ...subjects.map(
                  (subject) => DataColumn(
                    label: Text(
                      subject,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    '%',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Grade',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Report Card',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              rows: studentRows.map((student) {
                final percent = percentage(student);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        student.rollNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          student.studentName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    ...subjects.map((subject) {
                      final mark = student.subjectMarks[subject];

                      return DataCell(
                        Text(
                          mark == null ? '-' : '${mark.marksObtained}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }),

                    DataCell(
                      Text(
                        '${totalMarks(student)}/${totalMaximumMarks(student)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    DataCell(
                      Text(
                        percent == null
                            ? '-'
                            : '${percent.toStringAsFixed(1)}%',
                      ),
                    ),

                    DataCell(_gradeBadge(grade(student))),

                    DataCell(
                      OutlinedButton.icon(
                        onPressed: () => _downloadReportCard(student),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                        ),
                        label: const Text('PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRADE BADGE
  // ============================================================

  Widget _gradeBadge(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading examination results...'),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _error() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            errorMessage ?? 'Unable to load schedules.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 55,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          const Text(
            'No results found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            results.isEmpty
                ? 'No examination results have been entered yet.'
                : 'Try a different class, section or search.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFDC2626)
            : const Color(0xFF111827),
        content: Text(message),
      ),
    );
  }
}

// ================================================================
// STUDENT RESULT ROW
// ================================================================

class _StudentResultRow {
  final int studentId;
  final String studentName;
  final String rollNumber;

  final Map<String, _SubjectMark> subjectMarks = {};

  final List<ExamResultResponseModel> results = [];

  _StudentResultRow({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
  });
}

// ================================================================
// SUBJECT MARK
// ================================================================

class _SubjectMark {
  final String subjectName;
  final int marksObtained;
  final int maxMarks;
  final double? percentage;
  final String? grade;

  _SubjectMark({
    required this.subjectName,
    required this.marksObtained,
    required this.maxMarks,
    this.percentage,
    this.grade,
  });
}
