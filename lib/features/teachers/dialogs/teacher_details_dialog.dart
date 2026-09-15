import 'package:flutter/material.dart';

import '../models/class_model.dart';
import '../models/teacher_assignment_model.dart';
import '../models/teacher_model.dart';
import '../services/teacher_assignment_service.dart';



class TeacherDetailsDialog extends StatefulWidget {
  final Teacher teacher;
  final TeacherAssignmentService assignmentService;
  final List<SchoolClass> classes;
  final Future<bool> Function() onAssignClass;

  const TeacherDetailsDialog({
    super.key,
    required this.teacher,
    required this.assignmentService,
    required this.classes,
    required this.onAssignClass,
  });

  @override
  State<TeacherDetailsDialog> createState() => _TeacherDetailsDialogState();
}

class _TeacherDetailsDialogState extends State<TeacherDetailsDialog> {
  List<TeacherAssignment> _assignments = [];

  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  // ============================================================
  // LOAD ASSIGNMENTS
  // ============================================================

  Future<void> _loadAssignments() async {
    if (widget.teacher.id == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assignments = await widget.assignmentService
          .getAssignmentsByTeacher(widget.teacher.id!);

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ============================================================
  // DELETE ASSIGNMENT
  // ============================================================

  Future<void> _deleteAssignment(TeacherAssignment assignment) async {
    if (assignment.id == null) {
      _showMessage('Assignment ID is missing.', isError: true);
      return;
    }

    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Assignment',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Are you sure you want to remove this '
            'class assignment from the teacher?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
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
      await widget.assignmentService.deleteAssignment(assignment.id!);

      if (!mounted) return;

      _showMessage('Class assignment removed successfully.');

      await _loadAssignments();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // ASSIGN CLASS
  // ============================================================

  Future<void> _assignClass() async {
    final assigned = await widget.onAssignClass();

    if (!mounted) return;

    if (assigned) {
      await _loadAssignments();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: _buildHeader(),
      content: SizedBox(
        width: 650,
        height: screenHeight * 0.70,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfessionalInfo(),
              const SizedBox(height: 16),
              _buildContactInfo(),
              const SizedBox(height: 16),
              _buildPersonalInfo(),
              const SizedBox(height: 16),
              _buildAssignmentsSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: _isDeleting ? null : _assignClass,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Assign Class'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final name = _displayValue(widget.teacher.name, fallback: 'Teacher');

    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFEFF4FF),
          child: Text(
            _getInitial(name),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _displayValue(widget.teacher.designation, fallback: 'Teacher'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFESSIONAL INFORMATION
  // ============================================================

  Widget _buildProfessionalInfo() {
    return _sectionCard(
      title: 'Professional Information',
      icon: Icons.work_outline,
      children: [
        _infoGrid([
          _infoItem(
            'Employee ID',
            widget.teacher.employeeId,
            Icons.badge_outlined,
          ),
          _infoItem(
            'Designation',
            widget.teacher.designation,
            Icons.work_outline,
          ),
          _infoItem(
            'Qualification',
            widget.teacher.qualification,
            Icons.school_outlined,
          ),
          _infoItem(
            'Status',
            widget.teacher.status,
            Icons.toggle_on_outlined,
            valueWidget: _statusBadge(widget.teacher.status),
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // CONTACT INFORMATION
  // ============================================================

  Widget _buildContactInfo() {
    return _sectionCard(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _infoGrid([
          _infoItem('Phone', widget.teacher.phone, Icons.phone_outlined),
          _infoItem('Email', widget.teacher.email, Icons.email_outlined),
          _infoItem(
            'Address',
            widget.teacher.address,
            Icons.location_on_outlined,
            fullWidth: true,
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInfo() {
    return _sectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _infoGrid([
          _infoItem('Gender', widget.teacher.gender, Icons.wc_outlined),
          _infoItem(
            'Date of Birth',
            widget.teacher.dateOfBirth,
            Icons.cake_outlined,
          ),
          _infoItem(
            'Joining Date',
            widget.teacher.joiningDate,
            Icons.event_outlined,
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // ASSIGNMENTS
  // ============================================================

  Widget _buildAssignmentsSection() {
    return _sectionCard(
      title: 'Assigned Classes',
      icon: Icons.class_outlined,
      trailing: _assignmentCountBadge(),
      children: [
        const SizedBox(height: 4),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_assignments.isEmpty)
          _emptyAssignments()
        else
          Column(
            children: _assignments
                .map((assignment) => _assignmentCard(assignment))
                .toList(),
          ),
      ],
    );
  }

  Widget _assignmentCard(TeacherAssignment assignment) {
    final className = _getAssignmentClassName(assignment);

    final subject = _displayValue(
      assignment.subject,
      fallback: 'Subject not specified',
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 14,
                      color: Color(0xFF667085),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove assignment',
            onPressed: _isDeleting
                ? null
                : () {
                    _deleteAssignment(assignment);
                  },
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _emptyAssignments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.class_outlined,
              color: Color(0xFF667085),
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No classes assigned',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use "Assign Class" to assign a class '
            'and subject to this teacher.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_assignments.length}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF475467)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFO GRID
  // ============================================================

  Widget _infoGrid(List<_TeacherInfoItem> items) {
    final rows = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _infoBox(item),
          ),
        );
        continue;
      }

      if (i + 1 < items.length && !items[i + 1].fullWidth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _infoBox(item)),
                const SizedBox(width: 12),
                Expanded(child: _infoBox(items[i + 1])),
              ],
            ),
          ),
        );

        i++;
      } else {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _infoBox(item),
          ),
        );
      }
    }

    return Column(children: rows);
  }

  Widget _infoBox(_TeacherInfoItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 17, color: const Color(0xFF667085)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                item.valueWidget ??
                    Text(
                      _displayValue(item.value, fallback: '-'),
                      maxLines: item.fullWidth ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF344054),
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
  // STATUS
  // ============================================================

  Widget _statusBadge(String? status) {
    final normalized = (status ?? '').toUpperCase();

    final isActive = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF3) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF027A48) : const Color(0xFFB42318),
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNMENT CLASS NAME
  // ============================================================

  String _getAssignmentClassName(TeacherAssignment assignment) {
    /*
     * First try className from assignment response.
     * If your backend does not return className,
     * find the class from the loaded classes list.
     */

    final assignmentClassName = assignment.className;

    if (assignmentClassName != null && assignmentClassName.trim().isNotEmpty) {
      return assignmentClassName.trim();
    }

    if (assignment.classId != null) {
      for (final schoolClass in widget.classes) {
        if (schoolClass.id == assignment.classId) {
          final name = schoolClass.name;

          if (name != null && name.trim().isNotEmpty) {
            return name.trim();
          }
        }
      }
    }

    if (assignment.classId != null) {
      return 'Class ${assignment.classId}';
    }

    return 'Class';
  }

  // ============================================================
  // HELPERS
  // ============================================================

 _TeacherInfoItem _infoItem(
  String label,
  String? value,
  IconData icon, {
  Widget? valueWidget,
  bool fullWidth = false,
}) {
  return _TeacherInfoItem(
    label: label,
    value: value,
    icon: icon,
    valueWidget: valueWidget,
    fullWidth: fullWidth,
  );
}

  String _displayValue(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  String _getInitial(String name) {
    final value = name.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value.substring(0, 1).toUpperCase();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

// ================================================================
// INFO MODEL
// ================================================================

class _TeacherInfoItem {
  final String label;
  final String? value;
  final IconData icon;
  final Widget? valueWidget;
  final bool fullWidth;

  const _TeacherInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueWidget,
    this.fullWidth = false,
  });
}
