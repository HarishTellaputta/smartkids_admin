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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.10),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),

          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                // Dashboard
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                ),

                // Management
                _buildMenuItem(
                  index: 1,
                  icon: Icons.school_rounded,
                  title: 'Students',
                ),

                _buildMenuItem(
                  index: 2,
                  icon: Icons.person_rounded,
                  title: 'Teachers',
                ),

                _buildMenuItem(
                  index: 3,
                  icon: Icons.class_rounded,
                  title: 'Classes',
                ),

                _buildMenuItem(
                  index: 4,
                  icon: Icons.menu_book_rounded,
                  title: 'Subjects',
                ),

                _buildMenuItem(
                  index: 5,
                  icon: Icons.family_restroom_rounded,
                  title: 'Parents',
                ),

                const SizedBox(height: 12),

                _buildSectionTitle('ACADEMICS'),

                _buildMenuItem(
                  index: 6,
                  icon: Icons.calendar_month_rounded,
                  title: 'Attendance',
                ),

                _buildMenuItem(
                  index: 7,
                  icon: Icons.auto_stories_rounded,
                  title: 'Homework',
                ),

                _buildMenuItem(
                  index: 8,
                  icon: Icons.schedule_rounded,
                  title: 'Timetable',
                ),

                _buildMenuItem(
                  index: 9,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Fees',
                ),

                _buildMenuItem(
                  index: 10,
                  icon: Icons.assignment_rounded,
                  title: 'Exams',
                ),

                _buildMenuItem(
                  index: 11,
                  icon: Icons.psychology_rounded,
                  title: 'MCQ Tests',
                  isNew: true,
                ),

                _buildMenuItem(
                  index: 12,
                  icon: Icons.bar_chart_rounded,
                  title: 'Results',
                ),

                const SizedBox(height: 12),

                _buildSectionTitle('COMMUNICATION'),

                _buildMenuItem(
                  index: 13,
                  icon: Icons.campaign_rounded,
                  title: 'Notices',
                ),

                _buildMenuItem(
                  index: 14,
                  icon: Icons.celebration_rounded,
                  title: 'Events',
                ),

                _buildMenuItem(
                  index: 15,
                  icon: Icons.how_to_reg_rounded,
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

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade600,
                  Colors.blue.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 27,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Color(0xFF111827),
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'GLOBAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 14,
        top: 6,
        bottom: 9,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 7),

          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    bool isNew = false,
  }) {
    final bool isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onItemSelected(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.indigo.shade50,
                        Colors.blue.shade50.withOpacity(0.65),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Colors.indigo.withOpacity(0.07),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Active indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 3,
                  height: isSelected ? 27 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.indigo.shade600,
                        Colors.blue.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                SizedBox(
                  width: isSelected ? 9 : 12,
                ),

                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.75)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF4338CA)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),

                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade500,
                          Colors.blue.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (isSelected && !isNew)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.25),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SECTION
  // ============================================================

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildBottomMenuItem(
            index: 16,
            icon: Icons.settings_rounded,
            title: 'Settings',
          ),

          _buildBottomMenuItem(
            index: 17,
            icon: Icons.logout_rounded,
            title: 'Logout',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM MENU ITEM
  // ============================================================

  Widget _buildBottomMenuItem({
    required int index,
    required IconData icon,
    required String title,
    bool isLogout = false,
  }) {
    final bool isSelected = selectedIndex == index;

    final Color iconColor = isLogout
        ? Colors.red.shade400
        : isSelected
            ? Colors.indigo.shade600
            : const Color(0xFF6B7280);

    final Color textColor = isLogout
        ? Colors.red.shade500
        : isSelected
            ? Colors.indigo.shade700
            : const Color(0xFF374151);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () {
            onItemSelected(index);
          },
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigo.shade50
                  : isLogout
                      ? Colors.red.shade50.withOpacity(0.45)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : isLogout
                            ? Colors.red.shade50
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),

                if (isLogout)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.red.shade300,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}