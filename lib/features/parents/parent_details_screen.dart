
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/parent_model.dart';
import 'package:smartkids_admin/services/parent_service.dart';
import 'package:smartkids_admin/features/students/student_details_screen.dart';
import 'package:smartkids_admin/models/student_model.dart';

class ParentDetailsScreen extends StatefulWidget {
  final Parent parent;

  const ParentDetailsScreen({
    super.key,
    required this.parent,
  });

  @override
  State<ParentDetailsScreen> createState() =>
      _ParentDetailsScreenState();
}

class _ParentDetailsScreenState
    extends State<ParentDetailsScreen> {
  Parent? parent;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    parent = widget.parent;
    _loadParentDetails();
  }

  // ============================================================
  // LOAD LATEST PARENT DETAILS
  // ============================================================

  Future<void> _loadParentDetails() async {
    if (widget.parent.id == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final service = ParentService(token);

      final result =
          await service.getParent(widget.parent.id!);

      if (!mounted) return;

      setState(() {
        parent = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load latest parent details';
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentParent = parent ?? widget.parent;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Color(0xFF172033),
        ),
        title: const Text(
          'Parent Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadParentDetails,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final isMobile =
                constraints.maxWidth < 760;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1250,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(
                        currentParent,
                        isMobile,
                      ),

                      const SizedBox(height: 20),

                      if (errorMessage != null)
                        _buildErrorBanner(),

                      if (errorMessage != null)
                        const SizedBox(height: 16),

                      if (isMobile)
                        _buildMobileLayout(
                          currentParent,
                        )
                      else
                        _buildDesktopLayout(
                          currentParent,
                        ),

                      const SizedBox(height: 24),

                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    Parent currentParent,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF581C87),
            Color(0xFFA21CAF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA21CAF)
                .withOpacity(.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 66 : 80,
            height: isMobile ? 66 : 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                currentParent.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  currentParent.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 21 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _headerChip(
                      Icons.family_restroom_outlined,
                      currentParent.relationship ??
                          'Parent',
                    ),
                    _headerChip(
                      Icons.school_outlined,
                      '${currentParent.students.length} '
                      'Connected Student'
                      '${currentParent.students.length == 1 ? '' : 's'}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(.15),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Parent Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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

  Widget _headerChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadParentDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout(
    Parent currentParent,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildContactInformation(
                currentParent,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildFamilyInformation(
                currentParent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        _buildConnectedStudents(
          currentParent,
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout(
    Parent currentParent,
  ) {
    return Column(
      children: [
        _buildContactInformation(
          currentParent,
        ),

        const SizedBox(height: 16),

        _buildFamilyInformation(
          currentParent,
        ),

        const SizedBox(height: 16),

        _buildConnectedStudents(
          currentParent,
        ),
      ],
    );
  }

  // ============================================================
  // CONTACT INFORMATION
  // ============================================================

  Widget _buildContactInformation(
    Parent currentParent,
  ) {
    return _sectionCard(
      icon: Icons.contact_phone_outlined,
      iconBackground: const Color(0xFFF0F9FF),
      iconColor: const Color(0xFF0284C7),
      title: 'Contact Information',
      subtitle: 'Parent contact details',
      child: Column(
        children: [
          _detailRow(
            Icons.phone_outlined,
            'Phone',
            currentParent.contactPhone ??
                'Not provided',
          ),

          _divider(),

          _detailRow(
            Icons.email_outlined,
            'Email',
            currentParent.contactEmail ??
                'Not provided',
          ),

          _divider(),

          _detailRow(
            Icons.location_on_outlined,
            'Address',
            currentParent.address ??
                'Not provided',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FAMILY INFORMATION
  // ============================================================

  Widget _buildFamilyInformation(
    Parent currentParent,
  ) {
    return _sectionCard(
      icon: Icons.family_restroom_rounded,
      iconBackground: const Color(0xFFFDF4FF),
      iconColor: const Color(0xFFA21CAF),
      title: 'Family Information',
      subtitle: 'Parent and family details',
      child: Column(
        children: [
          _detailRow(
            Icons.badge_outlined,
            'Relationship',
            currentParent.relationship ??
                'Not provided',
          ),

          _divider(),

          _familyPersonRow(
            icon: Icons.person_outline_rounded,
            title: 'Father',
            value: currentParent.fatherName ??
                'Not provided',
          ),

          _divider(),

          _familyPersonRow(
            icon: Icons.person_outline_rounded,
            title: 'Mother',
            value: currentParent.motherName ??
                'Not provided',
          ),

          if (currentParent.guardianName != null &&
              currentParent.guardianName!
                  .trim()
                  .isNotEmpty) ...[
            _divider(),
            _familyPersonRow(
              icon: Icons.supervisor_account_outlined,
              title: 'Guardian',
              value: currentParent.guardianName!,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTED STUDENTS
  // ============================================================

  Widget _buildConnectedStudents(
    Parent currentParent,
  ) {
    return _sectionCard(
      icon: Icons.groups_rounded,
      iconBackground: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      title: 'Connected Students',
      subtitle:
          'Students linked to this parent account',
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 28,
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (currentParent.students.isEmpty)
            _emptyStudents()
          else
            ...currentParent.students.map(
              _studentButton,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT BUTTON
  // ============================================================

  Widget _studentButton(
    ParentStudent student,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (student.id == null) return;

            final studentModel =Student(
              id: student.id,
              name: student.name,
              admissionNo: student.admissionNo,
              sectionName: student.sectionName,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StudentDetailsScreen(
                  student: studentModel,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFFEFF6FF),
                        Color(0xFFDBEAFE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ??
                            'Unnamed Student',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (student.admissionNo !=
                              null)
                            _studentMeta(
                              Icons.badge_outlined,
                              student.admissionNo!,
                            ),
                          if (student.sectionName !=
                              null)
                            _studentMeta(
                              Icons.class_outlined,
                              student.sectionName!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(
                        0xFFE2E8F0,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentMeta(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STUDENTS
  // ============================================================

  Widget _emptyStudents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 28,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'No students linked',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'No students are currently connected '
            'to this parent account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF64748B),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FAMILY PERSON ROW
  // ============================================================

  Widget _familyPersonRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF4FF),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFA21CAF),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFF1F5F9),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 15,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Parent information is based on the '
            'latest available school records.',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}

