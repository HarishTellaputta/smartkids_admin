import 'package:flutter/material.dart';
import 'package:smartkids_admin/models/student_model.dart';

class StudentTable extends StatelessWidget {
  final List<Student> students;

  final void Function(Student student) onView;
  final void Function(Student student) onEdit;
  final void Function(Student student) onDelete;

  const StudentTable({
    super.key,
    required this.students,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // TABLE HEADER
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              color: const Color(0xFFF9FAFB),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: _HeaderText('Student'),
                  ),
                  const Expanded(
                    flex: 2,
                    child: _HeaderText('Section'),
                  ),
                  const Expanded(
                    flex: 2,
                    child: _HeaderText('Parent'),
                  ),
                  const Expanded(
                    flex: 2,
                    child: _HeaderText('Phone'),
                  ),
                  const Expanded(
                    flex: 1,
                    child: _HeaderText('Status'),
                  ),
                  SizedBox(
                    width: 70,
                    child: _HeaderText(
                      'Action',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // TABLE BODY
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, index) {
                  return _StudentRow(
                    student: students[index],
                    onView: onView,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HEADER TEXT
// ============================================================

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const _HeaderText(
    this.text, {
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

// ============================================================
// STUDENT ROW
// ============================================================

class _StudentRow extends StatelessWidget {
  final Student student;

  final void Function(Student student) onView;
  final void Function(Student student) onEdit;
  final void Function(Student student) onDelete;

  const _StudentRow({
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = student.name?.trim().isNotEmpty == true
        ? student.name!.trim()
        : 'Unknown Student';

    final section = student.sectionName?.trim().isNotEmpty == true
        ? student.sectionName!.trim()
        : '-';

    final parent = student.parentName?.trim().isNotEmpty == true
        ? student.parentName!.trim()
        : 'Not Assigned';

    final phone = student.phone?.trim().isNotEmpty == true
        ? student.phone!.trim()
        : '-';

    final status = student.status?.trim().isNotEmpty == true
        ? student.status!.trim().toUpperCase()
        : 'UNKNOWN';

    return InkWell(
      onTap: () => onView(student),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        child: Row(
          children: [
            // STUDENT
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _StudentAvatar(name: name),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.admissionNo?.isNotEmpty == true
                              ? 'Admission: ${student.admissionNo}'
                              : 'No admission number',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SECTION
            Expanded(
              flex: 2,
              child: Text(
                section,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            // PARENT
            Expanded(
              flex: 2,
              child: Text(
                parent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: parent == 'Not Assigned'
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF374151),
                ),
              ),
            ),

            // PHONE
            Expanded(
              flex: 2,
              child: Text(
                phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            // STATUS
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: status),
              ),
            ),

            // ACTION
            SizedBox(
              width: 70,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      onView(student);
                      break;

                    case 'edit':
                      onEdit(student);
                      break;

                    case 'delete':
                      onDelete(student);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('View'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STUDENT AVATAR
// ============================================================

class _StudentAvatar extends StatelessWidget {
  final String name;

  const _StudentAvatar({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .primaryColor
            .withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'ACTIVE';

    final bool isInactive = status == 'INACTIVE';

    Color background;
    Color foreground;

    if (isActive) {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF15803D);
    } else if (isInactive) {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFFB91C1C);
    } else {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}