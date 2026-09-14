import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Dashboard
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                ),

                // Management
                _buildMenuItem(
                  index: 1,
                  icon: Icons.school_outlined,
                  title: 'Students',
                ),

                _buildMenuItem(
                  index: 2,
                  icon: Icons.person_outline,
                  title: 'Teachers',
                ),

                _buildMenuItem(
                  index: 3,
                  icon: Icons.class_outlined,
                  title: 'Classes',
                ),

                // Subjects
                _buildMenuItem(
                  index: 4,
                  icon: Icons.menu_book_outlined,
                  title: 'Subjects',
                ),

                // Parents
                _buildMenuItem(
                  index: 5,
                  icon: Icons.family_restroom_outlined,
                  title: 'Parents',
                ),

                const SizedBox(height: 8),

                _buildSectionTitle('ACADEMICS'),

                _buildMenuItem(
                  index: 6,
                  icon: Icons.calendar_month_outlined,
                  title: 'Attendance',
                ),

                _buildMenuItem(
                  index: 7,
                  icon: Icons.menu_book_outlined,
                  title: 'Homework',
                ),

                _buildMenuItem(
                  index: 8,
                  icon: Icons.schedule_outlined,
                  title: 'Timetable',
                ),

                _buildMenuItem(
                  index: 9,
                  icon: Icons.currency_rupee,
                  title: 'Fees',
                ),

                _buildMenuItem(
                  index: 10,
                  icon: Icons.assignment_outlined,
                  title: 'Exams',
                ),

                _buildMenuItem(
                  index: 11,
                  icon: Icons.psychology_outlined,
                  title: 'MCQ Tests',
                ),

                _buildMenuItem(
                  index: 12,
                  icon: Icons.bar_chart_outlined,
                  title: 'Results',
                ),

                const SizedBox(height: 8),

                _buildSectionTitle('COMMUNICATION'),

                _buildMenuItem(
                  index: 13,
                  icon: Icons.campaign_outlined,
                  title: 'Notices',
                ),

                _buildMenuItem(
                  index: 14,
                  icon: Icons.celebration_outlined,
                  title: 'Events',
                ),

                _buildMenuItem(
                  index: 15,
                  icon: Icons.how_to_reg_outlined,
                  title: 'Admissions',
                ),
              ],
            ),
          ),

          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MySchool',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Global',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 14,
        top: 8,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onItemSelected(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEFF6FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),

                if (title == 'MCQ Tests')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          const Divider(
            color: Color(0xFFE5E7EB),
          ),

          _buildMenuItem(
            index: 16,
            icon: Icons.settings_outlined,
            title: 'Settings',
          ),

          _buildMenuItem(
            index: 17,
            icon: Icons.logout_outlined,
            title: 'Logout',
          ),
        ],
      ),
    );
  }
}