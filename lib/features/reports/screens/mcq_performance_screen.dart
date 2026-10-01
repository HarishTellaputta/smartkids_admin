
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

class McqPerformanceScreen extends StatefulWidget {
  const McqPerformanceScreen({super.key});

  @override
  State<McqPerformanceScreen> createState() =>
      _McqPerformanceScreenState();
}

class _McqPerformanceScreenState
    extends State<McqPerformanceScreen> {
  late final ApiClient _apiClient;
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

    _apiClient = ApiClient();

    _service = ReportService(_apiClient);
    _classService = ClassService(_apiClient);
    _sectionService = SectionService(_apiClient);
    _classSubjectService =
        ClassSubjectService(_apiClient);

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
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loadingFilters = false;
      });
    }
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await _service.getMcqPerformance(
        date: _selectedDate == null
            ? null
            : _formatDate(_selectedDate!),
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
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
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

  Future<void> _onClassChanged(
    SchoolClass? value,
  ) async {
    setState(() {
      _selectedClass = value;
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
        _sectionService.getSectionsByClassId(
          value.id!,
        ),
        _classSubjectService.getClassSubjects(
          value.id!,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _sections = results[0] as List<Section>;
        _subjects =
            results[1] as List<ClassSubjectModel>;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary: Color(0xFF4F46E5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // FILTER ACTIONS
  // ============================================================

  Future<void> _applyFilters() async {
    await _load();
  }

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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF111827),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _appBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < 750;

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile ? 16 : 24,
            ),
            child: _pageContent(isMobile),
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111827),
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              size: 22,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'MCQ Performance',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Analyze student quiz performance',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding:
              const EdgeInsets.only(right: 24),
          child: IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            style: IconButton.styleFrom(
              backgroundColor:
                  const Color(0xFFF3F4F6),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 21,
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAGE
  // ============================================================

  Widget _pageContent(bool isMobile) {
    if (_loadingFilters) {
      return const SizedBox(
        height: 600,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_error != null && _items.isEmpty) {
      return SizedBox(
        height: 600,
        child: _errorView(),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _filterPanel(isMobile),
        const SizedBox(height: 20),

        if (_loading)
          const SizedBox(
            height: 500,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_error != null)
          SizedBox(
            height: 500,
            child: _errorView(),
          )
        else if (_items.isEmpty)
          SizedBox(
            height: 500,
            child: _emptyView(),
          )
        else ...[
          _summarySection(isMobile),
          const SizedBox(height: 20),
          _performanceSection(),
        ],
      ],
    );
  }

  // ============================================================
  // FILTER PANEL
  // ============================================================

  Widget _filterPanel(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 17 : 21,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Filter student performance by date, class, section and subject.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder:
                (context, constraints) {
              final width =
                  constraints.maxWidth;

              final fieldWidth =
                  width >= 1150
                      ? (width - 48) / 4
                      : width >= 720
                          ? (width - 16) / 2
                          : width;

              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _dateField(),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _classField(),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _sectionField(),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _subjectField(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed:
                    _loading ? null : _clearFilters,
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF374151),
                  side: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed:
                    _loading ? null : _applyFilters,
                icon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                ),
                label:
                    const Text('Apply Filters'),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
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
  // DATE
  // ============================================================

  Widget _dateField() {
    return _clickableField(
      label: 'Date',
      icon: Icons.calendar_today_outlined,
      value: _selectedDate == null
          ? 'All Dates'
          : _displayDate(_selectedDate!),
      onTap: _pickDate,
    );
  }

  // ============================================================
  // CLASS
  // ============================================================

  Widget _classField() {
    return DropdownButtonFormField<
        SchoolClass>(
      value: _selectedClass,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Class',
        icon: Icons.school_outlined,
      ),
      hint: const Text('All Classes'),
      items: _classes.map((item) {
        return DropdownMenuItem<SchoolClass>(
          value: item,
          child: Text(
            item.name ??
                item.grade ??
                item.code ??
                'Class ${item.id}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged:
          _loading ? null : _onClassChanged,
    );
  }

  // ============================================================
  // SECTION
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
          child: Text(
            item.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged:
          _selectedClass == null ||
                  _loadingSections
              ? null
              : (value) {
                  setState(() {
                    _selectedSection = value;
                  });
                },
    );
  }

  // ============================================================
  // SUBJECT
  // ============================================================

  Widget _subjectField() {
    return DropdownButtonFormField<
        ClassSubjectModel>(
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
        return DropdownMenuItem<
            ClassSubjectModel>(
          value: item,
          child: Text(
            item.subjectName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged:
          _selectedClass == null ||
                  _loadingSubjects
              ? null
              : (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },
    );
  }

  // ============================================================
  // CLICKABLE FIELD
  // ============================================================

  Widget _clickableField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(11),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          icon: icon,
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
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
      prefixIcon: Icon(
        icon,
        size: 18,
        color: const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFB),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: Color(0xFF818CF8),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summarySection(bool isMobile) {
    final total = _items.length;

    final completed = _items.where((item) {
      final status =
          (item.status ?? '').toUpperCase();

      return status == 'COMPLETED' ||
          status == 'SUBMITTED';
    }).length;

    final correct = _items.fold<int>(
      0,
      (sum, item) =>
          sum + (item.correctAnswers ?? 0),
    );

    final wrong = _items.fold<int>(
      0,
      (sum, item) =>
          sum + (item.wrongAnswers ?? 0),
    );

    final cards = [
      _summaryCard(
        title: 'Total Attempts',
        value: '$total',
        icon: Icons.quiz_outlined,
        iconColor: const Color(0xFF4F46E5),
        iconBackground:
            const Color(0xFFEEF2FF),
      ),
      _summaryCard(
        title: 'Completed',
        value: '$completed',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF059669),
        iconBackground:
            const Color(0xFFECFDF5),
      ),
      _summaryCard(
        title: 'Correct Answers',
        value: '$correct',
        icon: Icons.task_alt_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBackground:
            const Color(0xFFEFF6FF),
      ),
      _summaryCard(
        title: 'Wrong Answers',
        value: '$wrong',
        icon: Icons.close_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBackground:
            const Color(0xFFFEF2F2),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0;
            i < cards.length;
            i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1)
            const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
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
  // PERFORMANCE SECTION
  // ============================================================

  Widget _performanceSection() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              17,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Performance',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Detailed MCQ performance for the selected filters',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _recordBadge(),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
          ),
          _performanceTable(),
        ],
      ),
    );
  }

  Widget _recordBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        '${_items.length} Records',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _performanceTable() {
    const tableWidth = 1050.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _tableHeader(),

              const Divider(
                height: 1,
                color: Color(0xFFE5E7EB),
              ),

              ...List.generate(
                _items.length,
                (index) {
                  return _tableRow(
                    _items[index],
                    index,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 52,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      color: const Color(0xFFFAFAFB),
      child: Row(
        children: const [
          SizedBox(
            width: 230,
            child: Text(
              'TEST',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 205,
            child: Text(
              'STUDENT',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 125,
            child: Text(
              'SCORE',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'CORRECT',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'WRONG',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'PERCENTAGE',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'STATUS',
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
    McqPerformanceModel item,
    int index,
  ) {
    return Container(
      height: 72,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 230,
            child: _testCell(item),
          ),
          SizedBox(
            width: 205,
            child: _studentCell(item),
          ),
          SizedBox(
            width: 125,
            child: _scoreCell(item),
          ),
          SizedBox(
            width: 90,
            child: _numberCell(
              item.correctAnswers,
            ),
          ),
          SizedBox(
            width: 80,
            child: _numberCell(
              item.wrongAnswers,
            ),
          ),
          SizedBox(
            width: 120,
            child: _percentageCell(item),
          ),
          SizedBox(
            width: 120,
            child: _statusChip(item.status),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEST CELL
  // ============================================================

  Widget _testCell(
    McqPerformanceModel item,
  ) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.quiz_rounded,
            size: 19,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                item.subject?.trim().isNotEmpty ==
                        true
                    ? item.subject!
                    : 'MCQ Test',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'MCQ Assessment',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT
  // ============================================================

  Widget _studentCell(
    McqPerformanceModel item,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor:
              const Color(0xFFF3F4F6),
          child: Text(
            _initial(item.studentName),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SCORE
  // ============================================================

  Widget _scoreCell(
    McqPerformanceModel item,
  ) {
    return Text(
      '${item.score ?? 0} / ${item.totalQuestions ?? 0}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }

  // ============================================================
  // NUMBER
  // ============================================================

  Widget _numberCell(int? value) {
    return Text(
      '${value ?? 0}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  // ============================================================
  // PERCENTAGE
  // ============================================================

  Widget _percentageCell(
    McqPerformanceModel item,
  ) {
    final percentage =
        item.percentage ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (percentage / 100)
                  .clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF4F46E5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusChip(String? status) {
    final value =
        status?.trim().toUpperCase() ?? '';

    Color background;
    Color foreground;
    IconData icon;

    switch (value) {
      case 'COMPLETED':
      case 'SUBMITTED':
        background = const Color(0xFFECFDF5);
        foreground = const Color(0xFF047857);
        icon = Icons.check_circle_rounded;
        break;

      case 'IN_PROGRESS':
        background = const Color(0xFFEFF6FF);
        foreground = const Color(0xFF2563EB);
        icon = Icons.timelapse_rounded;
        break;

      case 'EXPIRED':
        background = const Color(0xFFFEF2F2);
        foreground = const Color(0xFFDC2626);
        icon = Icons.timer_off_outlined;
        break;

      default:
        background = const Color(0xFFF3F4F6);
        foreground = const Color(0xFF4B5563);
        icon = Icons.info_outline_rounded;
    }

    final label = value.isEmpty
        ? 'UNKNOWN'
        : _capitalizeStatus(value);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeStatus(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() +
                  word.substring(1),
        )
        .join(' ');
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 38,
        ),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius:
                    BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 32,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'No MCQ performance found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try changing the selected filters to view performance records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 520,
        ),
        padding:
            const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 31,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text('Try Again'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF4F46E5),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
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
    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _initial(String? name) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w800,
  color: Color(0xFF6B7280),
  letterSpacing: 0.6,
);

