import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/class_subject_model.dart';
import '../models/teacher_model.dart';
import '../services/class_service.dart';
import '../services/teacher_assignment_service.dart';

class AssignClassDialog extends StatefulWidget {
  final Teacher teacher;
  final List<SchoolClass> classes;
  final TeacherAssignmentService assignmentService;
  final ClassService classService;
  final bool isLoadingClasses;

  const AssignClassDialog({
    super.key,
    required this.teacher,
    required this.classes,
    required this.assignmentService,
    required this.classService,
    required this.isLoadingClasses,
  });

  @override
  State<AssignClassDialog> createState() => _AssignClassDialogState();
}

class _AssignClassDialogState extends State<AssignClassDialog> {
  SchoolClass? selectedClass;
  ClassSubjectModel? selectedSubject;

  List<ClassSubjectModel> _subjects = [];

  bool _isLoadingSubjects = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.classes.isNotEmpty) {
      selectedClass = widget.classes.first;
      _loadSubjectsForClass(selectedClass!);
    }
  }

  Future<void> _loadSubjectsForClass(SchoolClass schoolClass) async {
    if (schoolClass.id == null) {
      return;
    }

    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      selectedSubject = null;
    });

    try {
      final subjects = await widget.classService.getSubjectsByClass(
        schoolClass.id!,
      );

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _subjects = [];
        selectedSubject = null;
        _isLoadingSubjects = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _assignClass() async {
    if (selectedClass == null) {
      _showMessage('Please select a class.');
      return;
    }

    if (selectedSubject == null) {
      _showMessage('Please select a subject.');
      return;
    }

    if (selectedClass!.id == null) {
      _showMessage('Selected class ID is missing.');
      return;
    }

    if (widget.teacher.id == null) {
      _showMessage('Teacher ID is missing.');
      return;
    }

    if (selectedSubject!.subjectId <= 0) {
      _showMessage('Selected subject ID is invalid.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.assignmentService.createAssignment(
        teacherId: widget.teacher.id!,
        classId: selectedClass!.id!,
        subjectId: selectedSubject!.subjectId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(_cleanError(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  String _className(SchoolClass schoolClass) {
    final name = schoolClass.name?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Class ${schoolClass.id ?? ''}';
  }

  String _subjectName(ClassSubjectModel subject) {
    final name = subject.subjectName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Subject ${subject.subjectId}';
  }

  String _subjectDisplayName(ClassSubjectModel subject) {
    final name = _subjectName(subject);
    final code = subject.subjectCode.trim();

    if (code.isNotEmpty) {
      return '$name ($code)';
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Assign Class & Subject',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _teacherInfo(),
              const SizedBox(height: 20),

              _classDropdown(),

              const SizedBox(height: 16),

              _subjectDropdown(),

              const SizedBox(height: 16),

              _backendNote(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isLoadingSubjects ? null : _assignClass,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Widget _teacherInfo() {
    final teacherName = widget.teacher.name?.trim().isNotEmpty == true
        ? widget.teacher.name!.trim()
        : 'Teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            child: Text(
              teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedClass?.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class',
        hintText: 'Select Class',
        prefixIcon: Icon(Icons.class_rounded),
        border: OutlineInputBorder(),
      ),
      items: widget.classes.where((schoolClass) => schoolClass.id != null).map((
        schoolClass,
      ) {
        return DropdownMenuItem<int>(
          value: schoolClass.id!,
          child: Text(_className(schoolClass), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: widget.isLoadingClasses || _isSaving
          ? null
          : (classId) {
              if (classId == null) return;

              SchoolClass? selected;

              for (final schoolClass in widget.classes) {
                if (schoolClass.id == classId) {
                  selected = schoolClass;
                  break;
                }
              }

              if (selected == null) return;

              setState(() {
                selectedClass = selected;
                selectedSubject = null;
                _subjects = [];
              });

              _loadSubjectsForClass(selected);
            },
    );
  }

  Widget _subjectDropdown() {
    if (_isLoadingSubjects) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(Icons.menu_book_rounded),
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Loading subjects...')),
          ],
        ),
      );
    }

    if (selectedClass == null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(Icons.menu_book_rounded),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'Select a class first',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(Icons.menu_book_rounded),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'No subjects assigned to this class',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: selectedSubject?.subjectId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subject',
        hintText: 'Select Subject',
        prefixIcon: Icon(Icons.menu_book_rounded),
        border: OutlineInputBorder(),
      ),
      items: _subjects.map((subject) {
        return DropdownMenuItem<int>(
          value: subject.subjectId,
          child: Text(
            _subjectDisplayName(subject),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (subjectId) {
              if (subjectId == null) return;

              ClassSubjectModel? selected;

              for (final subject in _subjects) {
                if (subject.subjectId == subjectId) {
                  selected = subject;
                  break;
                }
              }

              if (selected == null) return;

              setState(() {
                selectedSubject = selected;
              });
            },
    );
  }

  Widget _backendNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only subjects already assigned to the selected class '
              'will appear here. The teacher will be assigned to the '
              'selected class and subject.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
