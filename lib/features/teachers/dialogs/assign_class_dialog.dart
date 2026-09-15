import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/teacher_model.dart';
import '../services/teacher_assignment_service.dart';

class AssignClassDialog extends StatefulWidget {
  final Teacher teacher;
  final List<SchoolClass> classes;
  final TeacherAssignmentService assignmentService;
  final bool isLoadingClasses;

  const AssignClassDialog({
    super.key,
    required this.teacher,
    required this.classes,
    required this.assignmentService,
    required this.isLoadingClasses,
  });

  @override
  State<AssignClassDialog> createState() =>
      _AssignClassDialogState();
}

class _AssignClassDialogState
    extends State<AssignClassDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController =
      TextEditingController();

  SchoolClass? selectedClass;

  bool _isSaving = false;

  @override
  void dispose() {
    subjectController.dispose();
    super.dispose();
  }

  // ============================================================
  // ASSIGN CLASS
  // ============================================================

  Future<void> _assignClass() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedClass == null) {
      _showMessage(
        'Please select a class.',
        isError: true,
      );
      return;
    }

    if (widget.teacher.id == null) {
      _showMessage(
        'Teacher ID is missing.',
        isError: true,
      );
      return;
    }

    if (selectedClass!.id == null) {
      _showMessage(
        'Class ID is missing.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.assignmentService.createAssignment(
        teacherId: widget.teacher.id!,
        classId: selectedClass!.id!,
        subject: subjectController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Assign Class',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _teacherInfo(),
              const SizedBox(height: 20),
              _classDropdown(),
              const SizedBox(height: 16),
              _subjectField(),
              const SizedBox(height: 10),
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
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed:
              _isSaving ? null : _assignClass,
          icon: _isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.add,
                  size: 18,
                ),
          label: Text(
            _isSaving
                ? 'Assigning...'
                : 'Assign Class',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEACHER INFO
  // ============================================================

  Widget _teacherInfo() {
    final name =
        widget.teacher.name?.trim().isNotEmpty == true
            ? widget.teacher.name!.trim()
            : 'Unknown Teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xFFEFF4FF),
            child: Text(
              _initial(name),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.teacher.designation ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
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
    if (widget.isLoadingClasses) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Class',
          icon: Icons.class_outlined,
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
            SizedBox(width: 10),
            Text(
              'Loading classes...',
              style: TextStyle(
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.classes.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Class',
          icon: Icons.class_outlined,
        ),
        child: const Text(
          'No classes available',
          style: TextStyle(
            color: Color(0xFFB42318),
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: selectedClass?.id,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Class',
        icon: Icons.class_outlined,
      ),
      items: widget.classes.map((schoolClass) {
        return DropdownMenuItem<int>(
          value: schoolClass.id,
          child: Text(
            _className(schoolClass),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              if (value == null) return;

              final selected =
                  widget.classes.firstWhere(
                (item) => item.id == value,
              );

              setState(() {
                selectedClass = selected;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Please select a class';
        }

        return null;
      },
    );
  }

  // ============================================================
  // SUBJECT
  // ============================================================

  Widget _subjectField() {
    return TextFormField(
      controller: subjectController,
      textCapitalization:
          TextCapitalization.words,
      decoration: _inputDecoration(
        label: 'Subject',
        hint: 'e.g. Mathematics',
        icon: Icons.menu_book_outlined,
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Subject is required';
        }

        return null;
      },
    );
  }

  // ============================================================
  // BACKEND NOTE
  // ============================================================

  Widget _backendNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFFEC84B),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFFB54708),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This assignment will link the teacher '
              'to the selected class and subject.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7A2E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _className(SchoolClass schoolClass) {
    // Adjust this only if your SchoolClass model uses
    // a different display field.
    final name = schoolClass.name?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Class ${schoolClass.id ?? ''}';
  }

  String _initial(String name) {
    final value = name.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value.substring(0, 1).toUpperCase();
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}