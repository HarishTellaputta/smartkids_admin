import 'package:flutter/material.dart';

class StudentSummaryCards extends StatelessWidget {
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int newStudentsThisMonth;

  const StudentSummaryCards({
    super.key,
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.newStudentsThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return Column(
            children: [
              _buildCard(
                context,
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'Active Students',
                value: activeStudents.toString(),
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'Inactive Students',
                value: inactiveStudents.toString(),
                icon: Icons.pause_circle_rounded,
              ),
              const SizedBox(height: 12),
              _buildCard(
                context,
                title: 'New This Month',
                value: newStudentsThisMonth.toString(),
                icon: Icons.person_add_alt_1_rounded,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildCard(
                context,
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                context,
                title: 'Active Students',
                value: activeStudents.toString(),
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                context,
                title: 'Inactive Students',
                value: inactiveStudents.toString(),
                icon: Icons.pause_circle_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                context,
                title: 'New This Month',
                value: newStudentsThisMonth.toString(),
                icon: Icons.person_add_alt_1_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}