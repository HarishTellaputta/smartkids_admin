import 'package:flutter/material.dart';

import 'models/student_birthday_model.dart';
import 'screens/birthday_chat_screen.dart';
import 'services/birthday_chat_service.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  final BirthdayChatService _service = BirthdayChatService();

  List<StudentBirthdayModel> _todayBirthdays = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  // ============================================================
  // LOAD BIRTHDAYS
  // ============================================================

  Future<void> _loadBirthdays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final birthdays = await _service.getBirthdayStudents();

      if (!mounted) return;

      setState(() {
        _todayBirthdays = birthdays;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  void _openBirthdayChat(
    StudentBirthdayModel student,
  ) {
    if (student.studentId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BirthdayChatScreen(
          student: student,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: RefreshIndicator(
        onRefresh: _loadBirthdays,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildSummary(),

              const SizedBox(height: 24),

              _buildTodaySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final now = DateTime.now();

    final dateText =
        '${now.day.toString().padLeft(2, '0')} '
        '${_monthName(now.month)} '
        '${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEC4899),
                  Color(0xFFF43F5E),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.cake_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Birthdays',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Celebrate special moments with your students',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE185D),
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
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.cake_rounded,
            title: 'Today',
            value: _todayBirthdays.length.toString(),
            subtitle: 'Birthdays today',
            iconColor: const Color(0xFFEC4899),
            background: const Color(0xFFFDF2F8),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.groups_rounded,
            title: 'Students',
            value: _todayBirthdays.length.toString(),
            subtitle: 'Ready to wish',
            iconColor: const Color(0xFF8B5CF6),
            background: const Color(0xFFF5F3FF),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.chat_bubble_rounded,
            title: 'Birthday Chat',
            value: _todayBirthdays.isEmpty
                ? '0'
                : 'Open',
            subtitle: 'Send birthday wishes',
            iconColor: const Color(0xFF10B981),
            background: const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF9CA3AF),
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
  // TODAY SECTION
  // ============================================================

  Widget _buildTodaySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),

          const SizedBox(height: 18),

          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_todayBirthdays.isEmpty)
            _buildEmptyState()
          else
            ..._todayBirthdays.map(
              (student) => _buildBirthdayStudentCard(
                student,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.celebration_rounded,
            color: Color(0xFFEC4899),
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Birthdays",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Students celebrating today',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading
              ? null
              : _loadBirthdays,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFFEC4899),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BIRTHDAY STUDENT CARD
  // ============================================================

  Widget _buildBirthdayStudentCard(
    StudentBirthdayModel student,
  ) {
    final name = student.studentName ?? 'Student';

    final age = _calculateAge(
      student.dateOfBirth,
    );

    return InkWell(
      onTap: () {
        _openBirthdayChat(student);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFCE7F3),
          ),
        ),
        child: Row(
          children: [
            _buildStudentAvatar(student),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (student.admissionNo != null &&
                      student.admissionNo!.isNotEmpty)
                    Text(
                      'Admission No: ${student.admissionNo}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                  if (age != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$age Years',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Happy Birthday 🎉',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBE185D),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Wish',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT AVATAR
  // ============================================================

  Widget _buildStudentAvatar(
    StudentBirthdayModel student,
  ) {
    final photoUrl = student.photoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: NetworkImage(photoUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF9A8D4),
            Color(0xFFF472B6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFFEC4899),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Loading birthdays...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Unable to load birthdays',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _loadBirthdays,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🎂',
                style: TextStyle(
                  fontSize: 34,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No birthdays today',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'There are no students celebrating their birthday today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AGE
  // ============================================================

  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return null;
    }

    final today = DateTime.now();

    int age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month &&
            today.day < dateOfBirth.day)) {
      age--;
    }

    return age >= 0 ? age : null;
  }

  // ============================================================
  // MONTH
  // ============================================================

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}