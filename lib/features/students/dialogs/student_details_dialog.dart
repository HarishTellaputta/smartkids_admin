
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartkids_admin/models/student_model.dart';

class StudentDetailsDialog extends StatelessWidget {
  final Student student;

  const StudentDetailsDialog({
    super.key,
    required this.student,
  });

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _value(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value.trim();
  }

  String _dateValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _dateTimeValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    return DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final name = _value(student.name);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 720,
        ),
        child: Column(
          children: [
            _buildHeader(context, name),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(
                      context,
                      name,
                    ),

                    const SizedBox(height: 24),

                    // ====================================================
                    // PERSONAL INFORMATION
                    // ====================================================

                    _sectionTitle(
                      context,
                      'Personal Information',
                      Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 14),

                    _buildInfoGrid([
                      _InfoItem(
                        'Admission Number',
                        _value(student.admissionNo),
                        Icons.badge_outlined,
                      ),
                      _InfoItem(
                        'Date of Birth',
                        _dateValue(student.dateOfBirth),
                        Icons.cake_outlined,
                      ),
                      _InfoItem(
                        'Gender',
                        _value(student.gender),
                        Icons.wc_outlined,
                      ),
                      _InfoItem(
                        'Blood Group',
                        _value(student.bloodGroup),
                        Icons.bloodtype_outlined,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ====================================================
                    // ACADEMIC INFORMATION
                    // ====================================================

                    _sectionTitle(
                      context,
                      'Academic Information',
                      Icons.school_outlined,
                    ),

                    const SizedBox(height: 14),

                    _buildInfoGrid([
                      _InfoItem(
                        'Admission Date',
                        _dateValue(student.admissionDate),
                        Icons.calendar_today_outlined,
                      ),
                      _InfoItem(
                        'Section',
                        _value(student.sectionName),
                        Icons.class_outlined,
                      ),
                      _InfoItem(
                        'Academic Year',
                        _value(student.academicYearName),
                        Icons.event_note_outlined,
                      ),
                      _InfoItem(
                        'Status',
                        _value(student.status),
                        Icons.verified_outlined,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ====================================================
                    // PARENT INFORMATION
                    // ====================================================

                    _sectionTitle(
                      context,
                      'Parent Information',
                      Icons.family_restroom_rounded,
                    ),

                    const SizedBox(height: 14),

                    _buildInfoGrid([
                      _InfoItem(
                        'Parent',
                        _value(student.parentName),
                        Icons.person_outline,
                      ),
                      _InfoItem(
                        'Parent ID',
                        student.parentId?.toString() ?? '-',
                        Icons.numbers_rounded,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ====================================================
                    // CONTACT INFORMATION
                    // ====================================================

                    _sectionTitle(
                      context,
                      'Contact Information',
                      Icons.contact_phone_outlined,
                    ),

                    const SizedBox(height: 14),

                    _buildInfoGrid([
                      _InfoItem(
                        'Phone',
                        _value(student.phone),
                        Icons.phone_outlined,
                      ),
                      _InfoItem(
                        'Email',
                        _value(student.email),
                        Icons.email_outlined,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ====================================================
                    // RECORD INFORMATION
                    // ====================================================

                    _sectionTitle(
                      context,
                      'Record Information',
                      Icons.history_rounded,
                    ),

                    const SizedBox(height: 14),

                    _buildInfoGrid([
                      _InfoItem(
                        'Student ID',
                        student.id?.toString() ?? '-',
                        Icons.numbers_outlined,
                      ),
                      _InfoItem(
                        'Created At',
                        _dateTimeValue(student.createdAt),
                        Icons.add_circle_outline,
                      ),
                      _InfoItem(
                        'Updated At',
                        _dateTimeValue(student.updatedAt),
                        Icons.update_rounded,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    String name,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        18,
        20,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .primaryColor
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.visibility_outlined,
              color:
                  Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () =>
                Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(
    BuildContext context,
    String name,
  ) {
    final status =
        _value(student.status).toUpperCase();

    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .primaryColor
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty
                  ? name
                      .substring(0, 1)
                      .toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color:
                    Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _value(student.email),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO GRID
  // ============================================================

  Widget _buildInfoGrid(
    List<_InfoItem> items,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall =
            constraints.maxWidth < 600;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: isSmall
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2,
              child: _buildInfoItem(item),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _buildInfoItem(
    _InfoItem item,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: const Color(0xFF6B7280),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
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
  // FOOTER
  // ============================================================

  Widget _buildFooter(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () =>
              Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 13,
            ),
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
          child: const Text('Close'),
        ),
      ),
    );
  }
}

// ============================================================
// INFO MODEL
// ============================================================

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem(
    this.label,
    this.value,
    this.icon,
  );
}

