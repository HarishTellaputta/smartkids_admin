import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/classes/models/class_form_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/teacher_model.dart';

import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/class_subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/teacher_service.dart';
import 'package:smartkids_admin/features/timetable/models/timetable_model.dart';
import 'package:smartkids_admin/features/timetable/services/timetable_service.dart';
import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _token;

  ClassService? _classService;
  ClassSubjectService? _classSubjectService;
  TeacherService? _teacherService;
  SectionService? _sectionService;
  TimetableService? _timetableService;

  bool _loading = true;
  bool _loadingTimetable = false;

  String? _error;

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<ClassSubjectModel> _classSubjects = [];
  List<Teacher> _teachers = [];
  List<TimetableEntry> _timetable = [];

  SchoolClass? _selectedClass;
  Section? _selectedSection;

  String _selectedDay = 'MONDAY';

  final List<Map<String, String>> _days = const [
    {'label': 'Monday', 'value': 'MONDAY'},
    {'label': 'Tuesday', 'value': 'TUESDAY'},
    {'label': 'Wednesday', 'value': 'WEDNESDAY'},
    {'label': 'Thursday', 'value': 'THURSDAY'},
    {'label': 'Friday', 'value': 'FRIDAY'},
    {'label': 'Saturday', 'value': 'SATURDAY'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'JWT token not found. Please login again.';
        });
        return;
      }

      _token = token;

      _classService = ClassService(token);
      _classSubjectService = ClassSubjectService(token);
      _teacherService = TeacherService(token);
      _sectionService = SectionService(token);
      _timetableService = TimetableService(token);

      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD CLASSES + TEACHERS
  // ============================================================

  Future<void> _loadInitialData() async {
    try {
      final classes = await _classService!.getClasses();
      final teachers = await _teacherService!.getTeachers();

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _teachers = teachers;
        _loading = false;
      });

      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first;

        await _loadClassData(_selectedClass!.id!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD SECTION + SUBJECT + TIMETABLE
  // ============================================================

  Future<void> _loadClassData(int classId) async {
    try {
      setState(() {
        _loadingTimetable = true;
      });

      final results = await Future.wait([
        _sectionService!.getSectionsByClassId(classId),
        _classSubjectService!.getClassSubjects(classId),
        _timetableService!.getByClass(classId),
      ]);

      final sections = results[0] as List<Section>;
      final subjects = results[1] as List<ClassSubjectModel>;
      final timetable = results[2] as List<TimetableEntry>;

      if (!mounted) return;

      Section? selectedSection;

      if (sections.isNotEmpty) {
        selectedSection = sections.first;
      }

      setState(() {
        _sections = sections;
        _classSubjects = subjects;
        _selectedSection = selectedSection;
        _timetable = timetable;
        _loadingTimetable = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTimetable = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshTimetable() async {
    if (_selectedClass == null) return;

    try {
      setState(() {
        _loadingTimetable = true;
      });

      final data = await _timetableService!.getByClass(_selectedClass!.id!);

      if (!mounted) return;

      setState(() {
        _timetable = data;
        _loadingTimetable = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTimetable = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // FILTER DAY + SECTION
  // ============================================================

  List<TimetableEntry> get _filteredTimetable {
    return _timetable.where((entry) {
      final dayMatches = entry.dayOfWeek == _selectedDay;

      if (!dayMatches) {
        return false;
      }

      // If no section selected, show all sections
      if (_selectedSection == null) {
        return true;
      }

      // Show:
      // 1. selected section entries
      // 2. class-wide entries where sectionId == null
      return entry.sectionId == null || entry.sectionId == _selectedSection!.id;
    }).toList()..sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });
  }

  // ============================================================
  // ADD TIMETABLE
  // ============================================================

  Future<void> _showAddTimetableDialog() async {
    if (_selectedClass == null) {
      _showMessage('Please select a class first.');
      return;
    }

    if (_classSubjects.isEmpty) {
      _showMessage('No subjects assigned to this class.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return _AddTimetableDialog(
          classId: _selectedClass!.id!,
          className: _selectedClass!.name ?? '',
          sections: _sections,
          subjects: _classSubjects,
          teachers: _teachers,
          initialDay: _selectedDay,
          onSave:
              ({
                required int teacherId,
                required int classId,
                int? sectionId,
                required String subject,
                required String day,
                required String startTime,
                required String endTime,
                String? room,
              }) async {
                await _createTimetable(
                  teacherId: teacherId,
                  classId: classId,
                  sectionId: sectionId,
                  subject: subject,
                  day: day,
                  startTime: startTime,
                  endTime: endTime,
                  room: room,
                );
              },
        );
      },
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _createTimetable({
    required int teacherId,
    required int classId,
    int? sectionId,
    required String subject,
    required String day,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    try {
      Navigator.of(context).pop();

      setState(() {
        _loadingTimetable = true;
      });

      await _timetableService!.createTimetable(
        teacherId: teacherId,
        classId: classId,
        sectionId: sectionId,
        subject: subject,
        dayOfWeek: day,
        startTime: startTime,
        endTime: endTime,
        roomNumber: room,
      );

      await _refreshTimetable();

      if (!mounted) return;

      _showMessage('Timetable period added successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTimetable = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteTimetable(TimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Period'),
          content: Text('Delete ${entry.subject} ${entry.timeRange}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        _loadingTimetable = true;
      });

      await _timetableService!.deleteTimetable(entry.id);

      await _refreshTimetable();

      if (!mounted) return;

      _showMessage('Timetable period deleted.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTimetable = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
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
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingTimetable ? null : _refreshTimetable,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAddTimetableDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Period'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });

                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTimetable,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildClassSelector(),
          const SizedBox(height: 16),
          _buildSectionSelector(),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 20),
          _buildDaySelector(),
          const SizedBox(height: 16),
          _buildTimetable(),
        ],
      ),
    );
  }

  // ============================================================
  // CLASS SELECTOR
  // ============================================================

  Widget _buildClassSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<SchoolClass>(
          value: _selectedClass,
          decoration: const InputDecoration(
            labelText: 'Class',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(),
          ),
          items: _classes.map((schoolClass) {
            return DropdownMenuItem<SchoolClass>(
              value: schoolClass,
              child: Text(schoolClass.name ?? 'Class'),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;

            setState(() {
              _selectedClass = value;
              _selectedSection = null;
            });

            await _loadClassData(value.id!);
          },
        ),
      ),
    );
  }

  // ============================================================
  // SECTION SELECTOR
  // ============================================================

  Widget _buildSectionSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<Section?>(
          value: _selectedSection,
          decoration: const InputDecoration(
            labelText: 'Section',
            prefixIcon: Icon(Icons.groups_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<Section?>(
              value: null,
              child: Text('All Sections'),
            ),
            ..._sections.map((section) {
              return DropdownMenuItem<Section?>(
                value: section,
                child: Text(section.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSection = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    final todayCount = _filteredTimetable.length;

    final subjects = _timetable
        .map((e) => e.subject)
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _statCard('Periods', todayCount.toString(), Icons.schedule),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Subjects',
            subjects.toString(),
            Icons.menu_book_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Sections',
            _sections.length.toString(),
            Icons.groups_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAYS
  // ============================================================

  Widget _buildDaySelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final day = _days[index];

          final selected = _selectedDay == day['value'];

          return ChoiceChip(
            label: Text(day['label']!),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedDay = day['value']!;
              });
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // TIMETABLE
  // ============================================================

  Widget _buildTimetable() {
    if (_loadingTimetable) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final entries = _filteredTimetable;

    if (entries.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 52,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No timetable periods',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No periods found for the selected day and section.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        return _buildTimetableCard(entry);
      }).toList(),
    );
  }

  Widget _buildTimetableCard(TimetableEntry entry) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTimetableDetails(entry);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      TimetableEntry.formatTime(entry.startTime),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'to',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      TimetableEntry.formatTime(entry.endTime),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subject,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (entry.teacherName != null)
                      _infoRow(Icons.person_outline, entry.teacherName!),
                    if (entry.sectionName != null)
                      _infoRow(
                        Icons.groups_outlined,
                        'Section ${entry.sectionName}',
                      ),
                    if (entry.roomNumber != null &&
                        entry.roomNumber!.isNotEmpty)
                      _infoRow(Icons.meeting_room_outlined, entry.roomNumber!),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteTimetable(entry);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showTimetableDetails(TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(entry.subject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Day', _dayLabel(entry.dayOfWeek)),
              _detailRow('Time', entry.timeRange),
              _detailRow('Teacher', entry.teacherName ?? '-'),
              _detailRow('Class', entry.className ?? '-'),
              _detailRow('Section', entry.sectionName ?? 'All Sections'),
              _detailRow('Room', entry.roomNumber ?? '-'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _dayLabel(String day) {
    final match = _days.where((item) => item['value'] == day);

    if (match.isNotEmpty) {
      return match.first['label']!;
    }

    return day;
  }
}

// ===================================================================
// ADD TIMETABLE DIALOG
// ===================================================================

class _AddTimetableDialog extends StatefulWidget {
  final int classId;
  final String className;
  final List<Section> sections;
  final List<ClassSubjectModel> subjects;
  final List<Teacher> teachers;
  final String initialDay;

  final Future<void> Function({
    required int teacherId,
    required int classId,
    int? sectionId,
    required String subject,
    required String day,
    required String startTime,
    required String endTime,
    String? room,
  })
  onSave;

  const _AddTimetableDialog({
    required this.classId,
    required this.className,
    required this.sections,
    required this.subjects,
    required this.teachers,
    required this.initialDay,
    required this.onSave,
  });

  @override
  State<_AddTimetableDialog> createState() => _AddTimetableDialogState();
}

class _AddTimetableDialogState extends State<_AddTimetableDialog> {
  final _formKey = GlobalKey<FormState>();

  Section? _selectedSection;

  ClassSubjectModel? _selectedSubject;

  Teacher? _selectedTeacher;

  late String _selectedDay;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _roomController = TextEditingController();

  bool _saving = false;

  final List<Map<String, String>> _days = const [
    {'label': 'Monday', 'value': 'MONDAY'},
    {'label': 'Tuesday', 'value': 'TUESDAY'},
    {'label': 'Wednesday', 'value': 'WEDNESDAY'},
    {'label': 'Thursday', 'value': 'THURSDAY'},
    {'label': 'Friday', 'value': 'FRIDAY'},
    {'label': 'Saturday', 'value': 'SATURDAY'},
  ];

  @override
  void initState() {
    super.initState();

    _selectedDay = widget.initialDay;

    if (widget.sections.isNotEmpty) {
      _selectedSection = widget.sections.first;
    }

    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 40),
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null) {
      _showError('Please select a subject.');
      return;
    }

    if (_selectedTeacher == null) {
      _showError('Please select a teacher.');
      return;
    }

    if (_startTime == null) {
      _showError('Please select start time.');
      return;
    }

    if (_endTime == null) {
      _showError('Please select end time.');
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;

    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      _showError('End time must be after start time.');
      return;
    }

    try {
      setState(() {
        _saving = true;
      });

      await widget.onSave(
        teacherId: _teacherId,
        classId: widget.classId,
        sectionId: _selectedSection?.id,
        subject: _subjectName,
        day: _selectedDay,
        startTime: _formatBackendTime(_startTime!),
        endTime: _formatBackendTime(_endTime!),
        room: _roomController.text.trim().isEmpty
            ? null
            : _roomController.text.trim(),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  int get _teacherId {
    final dynamic teacher = _selectedTeacher;

    try {
      return teacher.id as int;
    } catch (_) {
      return 0;
    }
  }

  String get _subjectName {
    final dynamic subject = _selectedSubject;

    // Your ClassSubjectModel should expose name.
    try {
      return subject.name.toString();
    } catch (_) {
      return subject.toString();
    }
  }

  String _formatBackendTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatDisplayTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Timetable Period'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: widget.className,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<Section?>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    prefixIcon: Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<Section?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...widget.sections.map((section) {
                      return DropdownMenuItem<Section?>(
                        value: section,
                        child: Text(section.name),
                      );
                    }),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSection = value;
                          });
                        },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<ClassSubjectModel>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.subjects.map((subject) {
                    return DropdownMenuItem<ClassSubjectModel>(
                      value: subject,
                      child: Text(_getSubjectName(subject)),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSubject = value;
                          });
                        },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<Teacher>(
                  value: _selectedTeacher,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.teachers.map((teacher) {
                    return DropdownMenuItem<Teacher>(
                      value: teacher,
                      child: Text(_getTeacherName(teacher)),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedTeacher = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select teacher';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _days.map((day) {
                    return DropdownMenuItem<String>(
                      value: day['value'],
                      child: Text(day['label']!),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedDay = value;
                          });
                        },
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickStartTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_formatDisplayTime(_startTime)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickEndTime,
                        icon: const Icon(Icons.access_time_filled),
                        label: Text(_formatDisplayTime(_endTime)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _roomController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Room Number',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  String _getSubjectName(ClassSubjectModel subject) {
    try {
      return subject.subjectName;
    } catch (_) {
      return subject.toString();
    }
  }

  String _getTeacherName(Teacher teacher) {
    try {
      return teacher.name ?? 'Teacher ${teacher.id}';
    } catch (_) {
      return 'Teacher ${teacher.id}';
    }
  }
}
