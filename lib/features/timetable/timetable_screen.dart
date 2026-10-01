import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/teacher_model.dart';

import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/class_subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/teacher_service.dart';

import 'package:smartkids_admin/features/timetable/models/timetable_model.dart';
import 'package:smartkids_admin/features/timetable/models/timetable_import_response_model.dart';
import 'package:smartkids_admin/features/timetable/services/timetable_service.dart';

import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';
import 'package:smartkids_admin/features/exams/services/excel_file_picker_service.dart';
import '../timetable/timetable_details_screen.dart';

import 'package:smartkids_admin/core/network/api_client.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final apiClient = ApiClient();
  ClassService? _classService;
  TeacherService? _teacherService;
  SectionService? _sectionService;
  ClassSubjectService? _classSubjectService;
  TimetableService? _timetableService;

  List<SchoolClass> _classes = [];
  List<dynamic> _sections = [];
  List<dynamic> _subjects = [];
  List<dynamic> _teachers = [];
  List<TimetableEntry> _timetable = [];

  int? _selectedClassId;
  int? _selectedSectionId;
  String _selectedDay = 'MONDAY';

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isImportingExcel = false;

  final List<String> _days = const [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        _showSnackBar('Session expired. Please login again.', isError: true);
        return;
      }

      _classService = ClassService(apiClient);
      _teacherService = TeacherService(token);
      _sectionService = SectionService(apiClient);
      _classSubjectService = ClassSubjectService(apiClient);
      _timetableService = TimetableService(token);

      final results = await Future.wait([
        _classService!.getClasses(),
        _teacherService!.getTeachers(),
      ]);

      _classes = results[0] as List<SchoolClass>;
      _teachers = results[1] as List<dynamic>;

      if (_classes.isNotEmpty && _classes.first.id != null) {
        _selectedClassId = _classes.first.id;
        await _loadClassData(_selectedClassId!);
      }
    } catch (e) {
      _showSnackBar('Failed to load timetable data', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadClassData(int classId) async {
    if (_sectionService == null ||
        _classSubjectService == null ||
        _timetableService == null) {
      return;
    }

    try {
      final results = await Future.wait([
        _sectionService!.getSectionsByClassId(classId),
        _classSubjectService!.getClassSubjects(classId),
        _timetableService!.getByClass(classId),
      ]);

      if (!mounted) return;

      setState(() {
        _sections = results[0] as List<dynamic>;
        _subjects = results[1] as List<dynamic>;
        _timetable = results[2] as List<TimetableEntry>;

        _selectedSectionId = null;
      });
    } catch (e) {
      _showSnackBar('Failed to load class timetable', isError: true);
    }
  }

  Future<void> _changeClass(int? classId) async {
    if (classId == null) return;

    setState(() {
      _selectedClassId = classId;
      _isRefreshing = true;
    });

    try {
      await _loadClassData(classId);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _refresh() async {
    if (_selectedClassId == null) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadClassData(_selectedClassId!);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  List<TimetableEntry> get _filteredTimetable {
    return _timetable.where((entry) {
      final dayMatch = entry.dayOfWeek.toUpperCase() == _selectedDay;

      if (!dayMatch) return false;

      if (_selectedSectionId == null) return true;

      return entry.sectionId == null || entry.sectionId == _selectedSectionId;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  int get _periodCount => _filteredTimetable.length;

  int get _subjectCount {
    return _filteredTimetable
        .map((e) => e.subject)
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .length;
  }

  int get _teacherCount {
    return _filteredTimetable.map((e) => e.teacherId).toSet().length;
  }

  int get _sectionCount {
    return _filteredTimetable
        .map((e) => e.sectionId)
        .where((e) => e != null)
        .toSet()
        .length;
  }

  SchoolClass? get _selectedClass {
    for (final item in _classes) {
      if (item.id == _selectedClassId) return item;
    }
    return null;
  }

  String _dayShortName(String day) {
    switch (day) {
      case 'MONDAY':
        return 'MON';
      case 'TUESDAY':
        return 'TUE';
      case 'WEDNESDAY':
        return 'WED';
      case 'THURSDAY':
        return 'THU';
      case 'FRIDAY':
        return 'FRI';
      case 'SATURDAY':
        return 'SAT';
      default:
        return day.substring(0, 3);
    }
  }

  String _dayFullName(String day) {
    switch (day) {
      case 'MONDAY':
        return 'Monday';
      case 'TUESDAY':
        return 'Tuesday';
      case 'WEDNESDAY':
        return 'Wednesday';
      case 'THURSDAY':
        return 'Thursday';
      case 'FRIDAY':
        return 'Friday';
      case 'SATURDAY':
        return 'Saturday';
      default:
        return day;
    }
  }

  Future<void> _openDetails(TimetableEntry entry) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TimetableDetailsScreen(entry: entry)),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _deleteTimetable(TimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Period'),
          content: Text(
            'Are you sure you want to delete ${entry.subject} '
            'from the timetable?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _timetableService!.deleteTimetable(entry.id);
      await _refresh();

      _showSnackBar('Period deleted successfully');
    } catch (e) {
      _showSnackBar('Failed to delete period', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  Future<void> _importTimetableExcel() async {
    if (_timetableService == null) {
      _showSnackBar('Timetable service is not ready.', isError: true);
      return;
    }

    if (_isImportingExcel) return;

    try {
      setState(() {
        _isImportingExcel = true;
      });

      // Open existing Excel picker
      final file = await ExcelFilePickerService.pickExcelFile();

      if (file == null) {
        return;
      }

      if (file.bytes.isEmpty) {
        _showSnackBar('Selected Excel file is empty.', isError: true);
        return;
      }

      _showSnackBar('Uploading ${file.fileName}...');

      // Upload to Spring Boot
      final result = await _timetableService!.importTimetableExcel(
        bytes: file.bytes,
        fileName: file.fileName,
      );

      if (!mounted) return;

      // Refresh timetable after import
      await _refresh();

      if (!mounted) return;

      await _showImportResultDialog(result);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingExcel = false;
        });
      }
    }
  }

  Future<void> _showImportResultDialog(
    TimetableImportResponseModel result,
  ) async {
    final success = result.failedCount == 0;
    final hasErrors = result.errors.isNotEmpty;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: success
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: success ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success ? 'Import Successful' : 'Import Completed',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  _buildImportStat(
                    'Total Rows',
                    result.totalRows.toString(),
                    Icons.table_rows_rounded,
                  ),

                  const SizedBox(height: 10),

                  _buildImportStat(
                    'Imported Successfully',
                    result.successCount.toString(),
                    Icons.check_circle_outline_rounded,
                  ),

                  const SizedBox(height: 10),

                  _buildImportStat(
                    'Failed Rows',
                    result.failedCount.toString(),
                    Icons.error_outline_rounded,
                  ),

                  if (hasErrors) ...[
                    const SizedBox(height: 22),

                    const Text(
                      'Import Errors',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE0E0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: result.errors.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final error = result.errors[index];

                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEAEA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Row ${error.row}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error.message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 28,
                        20,
                        isMobile ? 16 : 28,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isMobile),
                          const SizedBox(height: 24),
                          _buildFilterPanel(isMobile),
                          const SizedBox(height: 20),
                          _buildSummaryCards(isMobile),
                          const SizedBox(height: 24),
                          _buildDaySelector(isMobile),
                          const SizedBox(height: 22),
                          _buildTimetableHeader(isMobile),
                          const SizedBox(height: 14),
                          _buildTimetableList(isMobile),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(.10),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timetable',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage classes, periods, teachers and weekly schedules',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (!isMobile)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isImportingExcel ? null : _importTimetableExcel,
                icon: _isImportingExcel
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _isImportingExcel ? 'Importing...' : 'Import Excel',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Period'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFilterPanel(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildClassDropdown(),
                const SizedBox(height: 12),
                _buildSectionDropdown(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildClassDropdown()),
                const SizedBox(width: 14),
                Expanded(child: _buildSectionDropdown()),
                const SizedBox(width: 14),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isRefreshing ? null : _refresh,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedClassId,
      decoration: InputDecoration(
        labelText: 'Class',
        prefixIcon: const Icon(Icons.school_rounded),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: _classes.map((item) {
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text(item.name ?? 'Class', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _changeClass,
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<int?>(
      value: _selectedSectionId,
      decoration: InputDecoration(
        labelText: 'Section',
        prefixIcon: const Icon(Icons.groups_rounded),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All Sections')),
        ..._sections.map(
          (section) => DropdownMenuItem<int?>(
            value: section.id,
            child: Text(
              section.name ?? 'Section',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSectionId = value;
        });
      },
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    final cards = [
      _SummaryData(
        title: 'Periods',
        value: _periodCount.toString(),
        subtitle: _dayFullName(_selectedDay),
        icon: Icons.schedule_rounded,
      ),
      _SummaryData(
        title: 'Subjects',
        value: _subjectCount.toString(),
        subtitle: 'Scheduled',
        icon: Icons.menu_book_rounded,
      ),
      _SummaryData(
        title: 'Teachers',
        value: _teacherCount.toString(),
        subtitle: 'Assigned',
        icon: Icons.person_rounded,
      ),
      _SummaryData(
        title: 'Sections',
        value: _sectionCount.toString(),
        subtitle: 'Covered',
        icon: Icons.groups_rounded,
      ),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (_, index) {
          return _buildSummaryCard(cards[index]);
        },
      );
    }

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSummaryCard(card),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  data.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _days.map((day) {
            final selected = day == _selectedDay;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 15 : 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _dayShortName(day),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 7),
                        Text(
                          _periodCount.toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimetableHeader(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dayFullName(_selectedDay),
                style: TextStyle(
                  fontSize: isMobile ? 19 : 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_selectedClass?.name ?? 'Class'} • '
                '${_selectedSectionId == null ? 'All Sections' : 'Selected Section'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '${_filteredTimetable.length} periods',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableList(bool isMobile) {
    if (_filteredTimetable.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredTimetable.asMap().entries.map((item) {
        final index = item.key;
        final entry = item.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTimetableCard(entry, index, isMobile),
        );
      }).toList(),
    );
  }

  Widget _buildTimetableCard(TimetableEntry entry, int index, bool isMobile) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetails(entry),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 15 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF0)),
          ),
          child: isMobile
              ? _buildMobileTimetableContent(entry, index)
              : _buildDesktopTimetableContent(entry, index),
        ),
      ),
    );
  }

  Widget _buildDesktopTimetableContent(TimetableEntry entry, int index) {
    return Row(
      children: [
        Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Text(
                'PERIOD ${index + 1}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                entry.timeRange,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: _buildPeriodMainInfo(entry)),
        const SizedBox(width: 18),
        _buildSectionChip(entry),
        const SizedBox(width: 18),
        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ],
    );
  }

  Widget _buildMobileTimetableContent(TimetableEntry entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'PERIOD ${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            Text(
              entry.timeRange,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildPeriodMainInfo(entry),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSectionChip(entry),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodMainInfo(TimetableEntry entry) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      entry.teacherName ?? 'Teacher not assigned',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              if (entry.roomNumber != null &&
                  entry.roomNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Room ${entry.roomNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionChip(TimetableEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_outlined, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            entry.sectionName ?? 'All Sections',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No periods scheduled',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'There are no timetable entries for '
            '${_dayFullName(_selectedDay).toLowerCase()} '
            'with the selected filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}
