import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/mcq_performance_model.dart';
import '../services/report_service.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';

import '../models/mcq_performance_model.dart';
import '../services/report_service.dart';

import '../../teachers/models/class_model.dart';
import '../../teachers/models/class_subject_model.dart';
import '../../teachers/services/class_service.dart';
import '../../teachers/services/class_subject_service.dart';

import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';
import 'package:smartkids_admin/core/network/api_client.dart';

class McqPerformanceScreen extends StatefulWidget {
  const McqPerformanceScreen({super.key});

  @override
  State<McqPerformanceScreen> createState() => _McqPerformanceScreenState();
}

class _McqPerformanceScreenState extends State<McqPerformanceScreen> {
  ApiClient apiClient = ApiClient();
  late final ReportService _service;
  late final ClassService _classService;
  late final SectionService _sectionService;
  late final ClassSubjectService _classSubjectService;

  List<McqPerformanceModel> _items = [];

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<ClassSubjectModel> _subjects = [];

  bool _loading = false;
  bool _loadingFilters = false;
  bool _loadingSections = false;
  bool _loadingSubjects = false;

  String? _error;

  DateTime? _selectedDate;
  SchoolClass? _selectedClass;
  Section? _selectedSection;
  ClassSubjectModel? _selectedSubject;

  @override
  void initState() {
    super.initState();

    _service = ReportService(apiClient);
    _classService = ClassService(apiClient);
    _sectionService = SectionService(apiClient);
    _classSubjectService = ClassSubjectService(apiClient);

    _loadInitialData();
  }

  // ============================================================
  // INITIAL LOAD
  // ============================================================

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingFilters = true;
      _error = null;
    });

    try {
      final classes = await _classService.getClasses();

      if (!mounted) return;

      setState(() {
        _classes = classes;
      });

      await _load();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loadingFilters = false;
      });
    }
  }

  // ============================================================
  // LOAD MCQ PERFORMANCE
  // ============================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getMcqPerformance(
        date: _selectedDate == null ? null : _formatDate(_selectedDate!),
        classId: _selectedClass?.id,
        sectionId: _selectedSection?.id,
        subject: _selectedSubject?.subjectName,
      );

      if (!mounted) return;

      setState(() {
        _items = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // CLASS CHANGE
  // ============================================================

  Future<void> _onClassChanged(SchoolClass? value) async {
    setState(() {
      _selectedClass = value;

      // Section and subject depend on class.
      _selectedSection = null;
      _selectedSubject = null;

      _sections = [];
      _subjects = [];

      _loadingSections = value != null;
      _loadingSubjects = value != null;
    });

    if (value == null || value.id == null) {
      return;
    }

    try {
      final results = await Future.wait([
        _sectionService.getSectionsByClassId(value.id!),
        _classSubjectService.getClassSubjects(value.id!),
      ]);

      if (!mounted) return;

      setState(() {
        _sections = results[0] as List<Section>;
        _subjects = results[1] as List<ClassSubjectModel>;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loadingSections = false;
        _loadingSubjects = false;
      });
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // APPLY FILTERS
  // ============================================================

  Future<void> _applyFilters() async {
    await _load();
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  Future<void> _clearFilters() async {
    setState(() {
      _selectedDate = null;
      _selectedClass = null;
      _selectedSection = null;
      _selectedSubject = null;

      _sections = [];
      _subjects = [];
    });

    await _load();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        titleSpacing: 24,
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, size: 24),
            SizedBox(width: 10),
            Text(
              'MCQ Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(24), child: _body()),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    if (_loadingFilters) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _errorView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterPanel(),
        const SizedBox(height: 24),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(child: _errorView())
        else if (_items.isEmpty)
          Expanded(child: _emptyView())
        else ...[
          _summaryCards(),
          const SizedBox(height: 24),
          Expanded(child: _performanceTable()),
        ],
      ],
    );
  }

  // ============================================================
  // FILTER PANEL
  // ============================================================

  Widget _filterPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_alt_outlined,
                  size: 20,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Filter MCQ attempts by date, class, section and subject.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final fieldWidth = width >= 1100
                  ? (width - 48) / 4
                  : width >= 700
                  ? (width - 16) / 2
                  : width;

              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  SizedBox(width: fieldWidth, child: _dateField()),
                  SizedBox(width: fieldWidth, child: _classField()),
                  SizedBox(width: fieldWidth, child: _sectionField()),
                  SizedBox(width: fieldWidth, child: _subjectField()),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _loading ? null : _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _loading ? null : _applyFilters,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField() {
    return _filterField(
      label: 'Date',
      icon: Icons.calendar_today_outlined,
      value: _selectedDate == null
          ? 'All Dates'
          : _formatDisplayDate(_selectedDate!),
      onTap: _pickDate,
    );
  }

  // ============================================================
  // CLASS FIELD
  // ============================================================

  Widget _classField() {
    return DropdownButtonFormField<SchoolClass>(
      value: _selectedClass,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Class', icon: Icons.school_outlined),
      hint: const Text('All Classes'),
      items: _classes.map((item) {
        return DropdownMenuItem<SchoolClass>(
          value: item,
          child: Text(
            item.name ?? item.grade ?? item.code ?? 'Class ${item.id}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _loading ? null : _onClassChanged,
    );
  }

  // ============================================================
  // SECTION FIELD
  // ============================================================

  Widget _sectionField() {
    return DropdownButtonFormField<Section>(
      value: _selectedSection,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Section',
        icon: Icons.groups_outlined,
      ),
      hint: Text(
        _selectedClass == null
            ? 'Select class first'
            : _loadingSections
            ? 'Loading sections...'
            : 'All Sections',
      ),
      items: _sections.map((item) {
        return DropdownMenuItem<Section>(
          value: item,
          child: Text(item.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _selectedClass == null || _loadingSections
          ? null
          : (value) {
              setState(() {
                _selectedSection = value;
              });
            },
    );
  }

  // ============================================================
  // SUBJECT FIELD
  // ============================================================

  Widget _subjectField() {
    return DropdownButtonFormField<ClassSubjectModel>(
      value: _selectedSubject,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Subject',
        icon: Icons.menu_book_outlined,
      ),
      hint: Text(
        _selectedClass == null
            ? 'Select class first'
            : _loadingSubjects
            ? 'Loading subjects...'
            : 'All Subjects',
      ),
      items: _subjects.map((item) {
        return DropdownMenuItem<ClassSubjectModel>(
          value: item,
          child: Text(item.subjectName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _selectedClass == null || _loadingSubjects
          ? null
          : (value) {
              setState(() {
                _selectedSubject = value;
              });
            },
    );
  }

  // ============================================================
  // FILTER FIELD
  // ============================================================

  Widget _filterField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _inputDecoration(label: label, icon: icon),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _summaryCards() {
    final total = _items.length;

    final completed = _items
        .where(
          (e) =>
              (e.status ?? '').toUpperCase() == 'COMPLETED' ||
              (e.status ?? '').toUpperCase() == 'SUBMITTED',
        )
        .length;

    final totalCorrect = _items.fold<int>(
      0,
      (sum, item) => sum + (item.correctAnswers ?? 0),
    );

    final totalWrong = _items.fold<int>(
      0,
      (sum, item) => sum + (item.wrongAnswers ?? 0),
    );

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.assignment_outlined,
            title: 'Total Attempts',
            value: '$total',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline,
            title: 'Completed',
            value: '$completed',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            icon: Icons.task_alt_rounded,
            title: 'Correct Answers',
            value: '$totalCorrect',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            icon: Icons.cancel_outlined,
            title: 'Wrong Answers',
            value: '$totalWrong',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF374151), size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFORMANCE TABLE
  // ============================================================

  Widget _performanceTable() {
    const double tableWidth = 930;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: tableWidth, child: _tableHeader()),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];

                      return Container(
                        height: 72,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 220, child: _testCell(item)),

                            SizedBox(width: 190, child: _studentCell(item)),

                            SizedBox(width: 120, child: _scoreCell(item)),

                            SizedBox(
                              width: 90,
                              child: _numberCell(item.correctAnswers),
                            ),

                            SizedBox(
                              width: 80,
                              child: _numberCell(item.wrongAnswers),
                            ),

                            SizedBox(width: 100, child: _percentageCell(item)),

                            SizedBox(
                              width: 110,
                              child: _statusChip(item.status),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: const [
          SizedBox(width: 220, child: Text('TEST', style: _headerStyle)),
          SizedBox(width: 190, child: Text('STUDENT', style: _headerStyle)),
          SizedBox(width: 120, child: Text('SCORE', style: _headerStyle)),
          SizedBox(width: 90, child: Text('CORRECT', style: _headerStyle)),
          SizedBox(width: 80, child: Text('WRONG', style: _headerStyle)),
          SizedBox(width: 100, child: Text('PERCENTAGE', style: _headerStyle)),
          SizedBox(width: 110, child: Text('STATUS', style: _headerStyle)),
        ],
      ),
    );
  }

  // ============================================================
  // TEST CELL
  // ============================================================

  Widget _testCell(McqPerformanceModel item) {
    final subject = item.subject?.trim();

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 20,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject ?? 'MCQ Test',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 3),

                // if (item.testId != null)
                //   Text(
                //     'Test ID: ${item.testId}',
                //     style: const TextStyle(
                //       fontSize: 11,
                //       color: Color(0xFF9CA3AF),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  } // ============================================================
  // STUDENT CELL
  // ============================================================

  Widget _studentCell(McqPerformanceModel item) {
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF3F4F6),
            child: Text(
              _initial(item.studentName),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.studentName ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE
  // ============================================================

  Widget _scoreCell(McqPerformanceModel item) {
    return SizedBox(
      width: 120,
      child: Text(
        '${item.score ?? 0} / ${item.totalQuestions ?? 0}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _numberCell(int? value) {
    return SizedBox(
      width: 90,
      child: Text(
        '${value ?? 0}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
  // ============================================================
  // PERCENTAGE
  // ============================================================

  Widget _percentageCell(McqPerformanceModel item) {
    final percentage = item.percentage ?? 0;

    return SizedBox(
      width: 100,
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusChip(String? status) {
    final value = status?.trim().toUpperCase() ?? '';

    final label = value.isEmpty ? 'UNKNOWN' : value;

    IconData icon;

    if (value == 'COMPLETED' || value == 'SUBMITTED') {
      icon = Icons.check_circle_outline;
    } else if (value == 'IN_PROGRESS') {
      icon = Icons.timelapse_rounded;
    } else if (value == 'EXPIRED') {
      icon = Icons.timer_off_outlined;
    } else {
      icon = Icons.info_outline;
    }

    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF374151)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: _box(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'No MCQ attempts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Student MCQ performance will appear here.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: _box(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 45, color: Color(0xFF6B7280)),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF374151)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _initial(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF6B7280),
  letterSpacing: 0.5,
);
