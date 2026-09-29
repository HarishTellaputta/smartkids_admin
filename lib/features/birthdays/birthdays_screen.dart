import 'package:flutter/material.dart';

class BirthdaysScreen extends StatelessWidget {
  const BirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayBirthdays = [
      {
        'name': 'Aditya Sharma',
        'class': '1st Class - A',
        'age': '7 Years',
      },
      {
        'name': 'Ananya Sharma',
        'class': '3rd Class - B',
        'age': '9 Years',
      },
    ];

    final upcomingBirthdays = [
      {
        'name': 'Kabir Khan',
        'class': '1st Class - A',
        'date': 'Tomorrow',
      },
      {
        'name': 'Sara Khan',
        'class': '2nd Class - C',
        'date': '30 Sep',
      },
      {
        'name': 'Vihaan Sharma',
        'class': '1st Class - A',
        'date': '2 Oct',
      },
    ];

    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.cake_rounded,
                    title: 'Today',
                    value: '2',
                    subtitle: 'Birthdays today',
                    iconColor: const Color(0xFFEC4899),
                    background: const Color(0xFFFDF2F8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'This Week',
                    value: '5',
                    subtitle: 'Upcoming birthdays',
                    iconColor: const Color(0xFF8B5CF6),
                    background: const Color(0xFFF5F3FF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.celebration_rounded,
                    title: 'This Month',
                    value: '14',
                    subtitle: 'Total birthdays',
                    iconColor: const Color(0xFFF59E0B),
                    background: const Color(0xFFFFFBEB),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTodaySection(todayBirthdays),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildUpcomingSection(
                          upcomingBirthdays,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildTodaySection(todayBirthdays),
                    const SizedBox(height: 20),
                    _buildUpcomingSection(upcomingBirthdays),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: const Row(
              children: [
                Icon(
                  Icons.today_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                SizedBox(width: 6),
                Text(
                  '28 Sep 2026',
                  style: TextStyle(
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

  Widget _buildTodaySection(List<Map<String, String>> students) {
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
          Row(
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
            ],
          ),

          const SizedBox(height: 18),

          ...students.map(
            (student) => _buildBirthdayStudentCard(
              name: student['name']!,
              className: student['class']!,
              age: student['age']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayStudentCard({
    required String name,
    required String className,
    required String age,
  }) {
    return Container(
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
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                age,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBE185D),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(8),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(
    List<Map<String, String>> birthdays,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.upcoming_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Next birthdays',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 16),

          ...birthdays.map(
            (student) => _buildUpcomingItem(
              name: student['name']!,
              className: student['class']!,
              date: student['date']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem({
    required String name,
    required String className,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cake_rounded,
              color: Color(0xFF8B5CF6),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}