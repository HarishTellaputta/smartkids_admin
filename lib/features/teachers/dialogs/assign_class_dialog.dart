import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/class_subject_model.dart';
import '/models/section_model.dart';
import '../models/teacher_model.dart';

import '../services/class_service.dart';
import '/services/section_service.dart';
import '../services/teacher_assignment_service.dart';

import 'package:smartkids_admin/features/teachers/models/teacher_assignment_model.dart';
import 'package:smartkids_admin/core/network/api_client.dart';

class AssignClassDialog extends StatefulWidget {
  final Teacher teacher;
  final List<SchoolClass> classes;
  final TeacherAssignmentService assignmentService;
  final ClassService classService;
  final bool isLoadingClasses;
  final List<TeacherAssignment> existingAssignments;

  const AssignClassDialog({
    super.key,
    required this.teacher,
    required this.classes,
    required this.assignmentService,
    required this.classService,
    required this.isLoadingClasses,
    required this.existingAssignments,
  });

  @override
  State<AssignClassDialog> createState() =>
      _AssignClassDialogState();
}

class _AssignClassDialogState
    extends State<AssignClassDialog> {
  SchoolClass? selectedClass;
  ClassSubjectModel? selectedSubject;
  Section? selectedSection;

  List<ClassSubjectModel> _subjects = [];
  List<Section> _sections = [];

  // All assignments for selected class.
  // This is important because we need to hide sections
  // assigned to OTHER teachers also.
  List<TeacherAssignment> _classAssignments = [];

  bool _isLoadingSubjects = false;
  bool _isLoadingSections = false;
  bool _isLoadingAssignments = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.classes.isNotEmpty) {
      selectedClass = widget.classes.first;
      _loadClassData(selectedClass!);
    }
  }

  // ============================================================
  // LOAD CLASS DATA
  // ============================================================

  Future<void> _loadClassData(
    SchoolClass schoolClass,
  ) async {
    if (schoolClass.id == null) {
      return;
    }

    setState(() {
      _isLoadingSubjects = true;
      _isLoadingSections = true;
      _isLoadingAssignments = true;

      _subjects = [];
      _sections = [];
      _classAssignments = [];

      selectedSubject = null;
      selectedSection = null;
    });

    try {
      final classId = schoolClass.id!;

      final results = await Future.wait([
        widget.classService.getSubjectsByClass(classId),
        _loadSections(classId),
        widget.assignmentService.getAssignmentsByClass(classId),
      ]);

      final subjects =
          results[0] as List<ClassSubjectModel>;

      final assignments =
          results[2] as List<TeacherAssignment>;

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _classAssignments = assignments;

        _isLoadingSubjects = false;
        _isLoadingSections = false;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _subjects = [];
        _sections = [];
        _classAssignments = [];

        selectedSubject = null;
        selectedSection = null;

        _isLoadingSubjects = false;
        _isLoadingSections = false;
        _isLoadingAssignments = false;
      });

      _showMessage(_cleanError(e));
    }
  }

  // ============================================================
  // LOAD SECTIONS
  // ============================================================

  Future<List<Section>> _loadSections(
    int classId,
  ) async {
    final sectionService = SectionService(
      ApiClient(),
    );

    final sections =
        await sectionService.getSectionsByClassId(classId);

    if (mounted) {
      setState(() {
        _sections = sections;
      });
    }

    return sections;
  }

  // ============================================================
  // AVAILABLE SUBJECTS
  //
  // IMPORTANT:
  //
  // Do NOT remove a subject just because this teacher
  // already teaches it.
  //
  // Example:
  //
  // Telugu:
  // A -> Suresh
  // B -> Suresh
  // C -> FREE
  //
  // Telugu must still appear because C is available.
  // ============================================================

  List<ClassSubjectModel> _availableSubjects() {
    if (selectedClass?.id == null) {
      return [];
    }

    if (_subjects.isEmpty) {
      return [];
    }

    // If at least one section is available for a subject,
    // that subject should remain selectable.
    return _subjects.where((subject) {
      return _availableSectionsForSubject(
        subject.subjectId,
      ).isNotEmpty;
    }).toList();
  }

  // ============================================================
  // AVAILABLE SECTIONS FOR SELECTED SUBJECT
  //
  // A section is available only when:
  //
  // Class + Subject + Section
  //
  // is NOT already assigned to ANY teacher.
  //
  // Example:
  //
  // A -> Suresh
  // B -> Ravi
  // C -> FREE
  //
  // Result:
  // C only
  // ============================================================

  List<Section> _availableSectionsForSubject(
    int subjectId,
  ) {
    if (selectedClass?.id == null) {
      return [];
    }

    final classId = selectedClass!.id!;

    final assignedSectionIds = _classAssignments
        .where(
          (assignment) =>
              assignment.classId == classId &&
              assignment.subjectId == subjectId &&
              assignment.sectionId != null,
        )
        .map(
          (assignment) => assignment.sectionId!,
        )
        .toSet();

    return _sections.where((section) {
      return !assignedSectionIds.contains(section.id);
    }).toList();
  }

  // ============================================================
  // ASSIGN
  // ============================================================

  Future<void> _assignClass() async {
    if (selectedClass == null) {
      _showMessage('Please select a class.');
      return;
    }

    if (selectedSubject == null) {
      _showMessage('Please select a subject.');
      return;
    }

    if (selectedSection == null) {
      _showMessage('Please select a section.');
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

    if (selectedSection!.id <= 0) {
      _showMessage('Selected section ID is invalid.');
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
        sectionId: selectedSection!.id,
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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // CLASS NAME
  // ============================================================

  String _className(SchoolClass schoolClass) {
    final name = schoolClass.name?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Class ${schoolClass.id ?? ''}';
  }

  // ============================================================
  // SUBJECT NAME
  // ============================================================

  String _subjectName(ClassSubjectModel subject) {
    final name = subject.subjectName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Subject ${subject.subjectId}';
  }

  String _subjectDisplayName(
    ClassSubjectModel subject,
  ) {
    final name = _subjectName(subject);
    final code = subject.subjectCode.trim();

    if (code.isNotEmpty) {
      return '$name ($code)';
    }

    return name;
  }

  // ============================================================
  // SECTION NAME
  // ============================================================

  String _sectionName(Section section) {
    final name = section.name.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Section ${section.id}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Assign Class, Subject & Section',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _teacherInfo(),

              const SizedBox(height: 20),

              _classDropdown(),

              const SizedBox(height: 16),

              _subjectDropdown(),

              const SizedBox(height: 16),

              _sectionDropdown(),

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
          onPressed:
              _isSaving ||
                      _isLoadingSubjects ||
                      _isLoadingSections ||
                      _isLoadingAssignments
                  ? null
                  : _assignClass,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  // ============================================================
  // TEACHER INFO
  // ============================================================

  Widget _teacherInfo() {
    final teacherName =
        widget.teacher.name?.trim().isNotEmpty == true
            ? widget.teacher.name!.trim()
            : 'Teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            child: Text(
              teacherName.isNotEmpty
                  ? teacherName[0].toUpperCase()
                  : 'T',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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

  // ============================================================
  // CLASS DROPDOWN
  // ============================================================

  Widget _classDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedClass?.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class',
        hintText: 'Select Class',
        prefixIcon: Icon(
          Icons.class_rounded,
        ),
        border: OutlineInputBorder(),
      ),
      items: widget.classes
          .where(
            (schoolClass) =>
                schoolClass.id != null,
          )
          .map(
            (schoolClass) {
              return DropdownMenuItem<int>(
                value: schoolClass.id!,
                child: Text(
                  _className(schoolClass),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              );
            },
          )
          .toList(),
      onChanged:
          widget.isLoadingClasses || _isSaving
              ? null
              : (classId) {
                  if (classId == null) return;

                  SchoolClass? selected;

                  for (final schoolClass
                      in widget.classes) {
                    if (schoolClass.id == classId) {
                      selected = schoolClass;
                      break;
                    }
                  }

                  if (selected == null) return;

                  setState(() {
                    selectedClass = selected;
                    selectedSubject = null;
                    selectedSection = null;

                    _subjects = [];
                    _sections = [];
                    _classAssignments = [];
                  });

                  _loadClassData(selected);
                },
    );
  }

  // ============================================================
  // SUBJECT DROPDOWN
  // ============================================================

  Widget _subjectDropdown() {
    if (_isLoadingSubjects ||
        _isLoadingAssignments ||
        _isLoadingSections) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(
            Icons.menu_book_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading subjects...',
              ),
            ),
          ],
        ),
      );
    }

    if (selectedClass == null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(
            Icons.menu_book_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'Select a class first',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(
            Icons.menu_book_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'No subjects assigned to this class',
          style: TextStyle(
            color: Colors.redAccent,
          ),
        ),
      );
    }

    final availableSubjects =
        _availableSubjects();

    if (availableSubjects.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Subject',
          prefixIcon: Icon(
            Icons.menu_book_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'No subjects have available sections.',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: selectedSubject?.subjectId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subject',
        hintText: 'Select Subject',
        prefixIcon: Icon(
          Icons.menu_book_rounded,
        ),
        border: OutlineInputBorder(),
      ),
      items: availableSubjects.map(
        (subject) {
          return DropdownMenuItem<int>(
            value: subject.subjectId,
            child: Text(
              _subjectDisplayName(subject),
              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _isSaving
          ? null
          : (subjectId) {
              if (subjectId == null) return;

              ClassSubjectModel? selected;

              for (final subject
                  in availableSubjects) {
                if (subject.subjectId ==
                    subjectId) {
                  selected = subject;
                  break;
                }
              }

              if (selected == null) return;

              setState(() {
                selectedSubject = selected;
                selectedSection = null;
              });
            },
    );
  }

  // ============================================================
  // SECTION DROPDOWN
  // ============================================================

  Widget _sectionDropdown() {
    if (selectedSubject == null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Section',
          prefixIcon: Icon(
            Icons.groups_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'Select a subject first',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    final availableSections =
        _availableSectionsForSubject(
      selectedSubject!.subjectId,
    );

    if (availableSections.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Section',
          prefixIcon: Icon(
            Icons.groups_rounded,
          ),
          border: OutlineInputBorder(),
        ),
        child: const Text(
          'No sections available for this subject.',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: selectedSection?.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Section',
        hintText: 'Select Section',
        prefixIcon: Icon(
          Icons.groups_rounded,
        ),
        border: OutlineInputBorder(),
      ),
      items: availableSections.map(
        (section) {
          return DropdownMenuItem<int>(
            value: section.id,
            child: Text(
              _sectionName(section),
              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _isSaving
          ? null
          : (sectionId) {
              if (sectionId == null) return;

              Section? selected;

              for (final section
                  in availableSections) {
                if (section.id == sectionId) {
                  selected = section;
                  break;
                }
              }

              if (selected == null) return;

              setState(() {
                selectedSection = selected;
              });
            },
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _backendNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.grey,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select a class, subject and an available section. '
              'Sections already assigned to another teacher '
              'for this subject will not be shown.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}