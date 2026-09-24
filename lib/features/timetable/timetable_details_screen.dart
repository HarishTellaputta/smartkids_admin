import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../timetable/models/timetable_model.dart';
import '../timetable/services/timetable_service.dart';

import '../teachers/services/class_subject_service.dart';
import '../teachers/models/class_subject_model.dart';

import '../teachers/services/teacher_service.dart';
import '../teachers/models/teacher_model.dart';

import '../../models/section_model.dart';
import '../../services/section_service.dart';

class TimetableDetailsScreen extends StatefulWidget {
  final TimetableEntry entry;

  const TimetableDetailsScreen({super.key, required this.entry});

  @override
  State<TimetableDetailsScreen> createState() => _TimetableDetailsScreenState();
}

class _TimetableDetailsScreenState extends State<TimetableDetailsScreen> {
  late TimetableEntry _entry;

  late TimetableService _timetableService;
  ClassSubjectService? _classSubjectService;
  TeacherService? _teacherService;
  SectionService? _sectionService;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isUpdating = false;

  List<ClassSubjectModel> _classSubjects = [];
  List<Teacher> _teachers = [];
  List<Section> _sections = [];

  @override
  void initState() {
    super.initState();

    _entry = widget.entry;

    _loadEditData();
  }

  Future<void> _loadEditData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        return;
      }

      _timetableService = TimetableService(token);

      // Continue loading your edit data here...
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load timetable data: $e')),
      );
    }
  }

  String _formatDay(String day) {
    if (day.isEmpty) return '-';

    final value = day.toLowerCase();

    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Period'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${_entry.subject}" from the timetable?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _timetableService.deleteTimetable(_entry.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete period: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEditDialog() async {
    if (_isLoading) return;

    final currentSubject = _classSubjects.cast<ClassSubjectModel?>().firstWhere(
      (item) =>
          item?.subjectName?.trim().toLowerCase() ==
          _entry.subject.trim().toLowerCase(),
      orElse: () => null,
    );

    final result = await showDialog<_TimetableEditResult>(
      context: context,
      builder: (_) {
        return _EditTimetableDialog(
          entry: _entry,
          subjects: _classSubjects,
          teachers: _teachers,
          sections: _sections,
          initialSubjectId: currentSubject?.subjectId,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updated = await _timetableService.updateTimetable(
        id: _entry.id,
        teacherId: result.teacherId,
        classId: result.classId,
        sectionId: result.sectionId,
        subjectId: result.subjectId,
        dayOfWeek: result.dayOfWeek,
        startTime: result.startTime,
        endTime: result.endTime,
        roomNumber: result.roomNumber,
      );

      if (!mounted) return;

      setState(() {
        _entry = updated;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update timetable: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Timetable Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: (_isDeleting || _isUpdating || _isLoading)
                ? null
                : _showEditDialog,
            icon: _isUpdating
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Delete',
            onPressed: (_isDeleting || _isUpdating) ? null : _deleteEntry,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 30,
          22,
          isMobile ? 16 : 30,
          35,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(isMobile),
                const SizedBox(height: 20),
                _buildInformationSection(isMobile),
                const SizedBox(height: 20),
                _buildScheduleSection(isMobile),
                const SizedBox(height: 20),
                _buildActions(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubjectIcon(),
                const SizedBox(height: 18),
                _buildHeroText(),
              ],
            )
          : Row(
              children: [
                _buildSubjectIcon(),
                const SizedBox(width: 20),
                Expanded(child: _buildHeroText()),
                _buildPeriodBadge(),
              ],
            ),
    );
  }

  Widget _buildSubjectIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.18)),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _entry.subject,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${_entry.className ?? 'Class'}'
          '${_entry.sectionName != null ? ' • ${_entry.sectionName}' : ''}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              color: Colors.white70,
              size: 17,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _entry.teacherName ?? 'Teacher not assigned',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'PERIOD',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _entry.timeRange,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(bool isMobile) {
    return _SectionCard(
      title: 'Class Information',
      icon: Icons.school_outlined,
      child: GridView.count(
        crossAxisCount: isMobile ? 1 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isMobile ? 5 : 2.5,
        children: [
          _InfoTile(
            icon: Icons.school_rounded,
            label: 'Class',
            value: _entry.className ?? '-',
          ),
          _InfoTile(
            icon: Icons.groups_rounded,
            label: 'Section',
            value: _entry.sectionName ?? 'All Sections',
          ),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Teacher',
            value: _entry.teacherName ?? 'Not Assigned',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(bool isMobile) {
    return _SectionCard(
      title: 'Schedule',
      icon: Icons.calendar_month_outlined,
      child: GridView.count(
        crossAxisCount: isMobile ? 1 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isMobile ? 5 : 2.5,
        children: [
          _InfoTile(
            icon: Icons.today_rounded,
            label: 'Day',
            value: _formatDay(_entry.dayOfWeek),
          ),
          _InfoTile(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _entry.timeRange,
          ),
          _InfoTile(
            icon: Icons.meeting_room_outlined,
            label: 'Room',
            value:
                (_entry.roomNumber == null || _entry.roomNumber!.trim().isEmpty)
                ? 'Not Assigned'
                : _entry.roomNumber!,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_isDeleting || _isUpdating || _isLoading)
                ? null
                : _showEditDialog,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Period'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: (_isDeleting || _isUpdating) ? null : _deleteEntry,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(_isDeleting ? 'Deleting...' : 'Delete Period'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EDIT RESULT
// ============================================================

class _TimetableEditResult {
  final int teacherId;
  final int classId;
  final int? sectionId;
  final int subjectId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomNumber;

  const _TimetableEditResult({
    required this.teacherId,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
  });
}

// ============================================================
// EDIT DIALOG
// ============================================================

class _EditTimetableDialog extends StatefulWidget {
  final TimetableEntry entry;
  final List<ClassSubjectModel> subjects;
  final List<Teacher> teachers;
  final List<Section> sections;
  final int? initialSubjectId;

  const _EditTimetableDialog({
    required this.entry,
    required this.subjects,
    required this.teachers,
    required this.sections,
    required this.initialSubjectId,
  });

  @override
  State<_EditTimetableDialog> createState() => _EditTimetableDialogState();
}

class _EditTimetableDialogState extends State<_EditTimetableDialog> {
  int? _subjectId;
  int? _teacherId;
  int? _sectionId;

  late String _day;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  late final TextEditingController _roomController;

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

    _subjectId = widget.initialSubjectId;

    _teacherId =
        widget.teachers.any((teacher) => teacher.id == widget.entry.teacherId)
        ? widget.entry.teacherId
        : null;

    _sectionId =
        widget.sections.any((section) => section.id == widget.entry.sectionId)
        ? widget.entry.sectionId
        : null;

    _day = _days.contains(widget.entry.dayOfWeek)
        ? widget.entry.dayOfWeek
        : _days.first;

    _startTime = _parseTime(widget.entry.startTime);
    _endTime = _parseTime(widget.entry.endTime);

    _roomController = TextEditingController(
      text: widget.entry.roomNumber ?? '',
    );
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    try {
      final parts = value.split(':');

      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
      initialTime: _endTime,
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  bool _isValidTime() {
    final start = _startTime.hour * 60 + _startTime.minute;

    final end = _endTime.hour * 60 + _endTime.minute;

    return end > start;
  }

  void _save() {
    if (_subjectId == null) {
      _showError('Please select a subject.');
      return;
    }

    if (_teacherId == null) {
      _showError('Please select a teacher.');
      return;
    }

    if (!_isValidTime()) {
      _showError('End time must be after start time.');
      return;
    }

    final result = _TimetableEditResult(
      teacherId: _teacherId!,
      classId: widget.entry.classId,
      sectionId: _sectionId,
      subjectId: _subjectId!,
      dayOfWeek: _day,
      startTime: _timeToString(_startTime),
      endTime: _timeToString(_endTime),
      roomNumber: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
    );

    Navigator.pop(context, result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: const Row(
        children: [
          Icon(Icons.edit_calendar_rounded, color: Color(0xFF4F46E5)),
          SizedBox(width: 10),
          Text('Edit Period', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSubjectDropdown(),
              const SizedBox(height: 14),
              _buildTeacherDropdown(),
              const SizedBox(height: 14),
              _buildSectionDropdown(),
              const SizedBox(height: 14),
              _buildDayDropdown(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start Time',
                      time: _startTime,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeButton(
                      label: 'End Time',
                      time: _endTime,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE3E6EF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save Changes'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<int>(
      value: _subjectId,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Subject',
        icon: Icons.menu_book_outlined,
      ),

      items: widget.subjects.map((subject) {
        return DropdownMenuItem<int>(
          value: subject.subjectId,
          child: Text(
            subject.subjectName ?? 'Unknown Subject',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _subjectId = value;
        });
      },
    );
  }

  Widget _buildTeacherDropdown() {
    return DropdownButtonFormField<int>(
      value: _teacherId,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Teacher',
        icon: Icons.person_outline,
      ),
      items: widget.teachers.where((teacher) => teacher.id != null).map((
        teacher,
      ) {
        return DropdownMenuItem<int>(
          value: teacher.id,
          child: Text(
            teacher.name ?? 'Unknown Teacher',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _teacherId = value;
        });
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<int?>(
      value: _sectionId,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Room Number',
        icon: Icons.meeting_room_outlined,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All Sections')),
        ...widget.sections.map(
          (section) => DropdownMenuItem<int?>(
            value: section.id,
            child: Text(section.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _sectionId = value;
        });
      },
    );
  }

  Widget _buildDayDropdown() {
    return DropdownButtonFormField<String>(
      value: _day,
      decoration: _inputDecoration(
        label: 'Description',
        icon: Icons.notes_outlined,
      ),
      items: _days.map((day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(day[0] + day.substring(1).toLowerCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _day = value;
        });
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }
}

// ============================================================
// TIME BUTTON
// ============================================================

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          border: Border.all(color: const Color(0xFFE3E6EF)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 6),
                Text(
                  time.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
                  color: const Color(0xFFF0F1FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// INFO TILE
// ============================================================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
