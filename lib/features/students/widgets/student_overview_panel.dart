import 'package:flutter/material.dart';

class StudentOverviewPanel extends StatelessWidget {
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int newStudentsThisMonth;

  const StudentOverviewPanel({
    super.key,
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.newStudentsThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: Colors.blue.shade700,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Student Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =====================================================
            // TOTAL
            // =====================================================

            _mainCount(
              icon: Icons.people_alt_outlined,
              label: 'Total Students',
              value: totalStudents,
              iconColor: Colors.blue.shade700,
              backgroundColor: Colors.blue.shade50,
            ),

            const SizedBox(height: 16),

            // =====================================================
            // ACTIVE / INACTIVE
            // =====================================================

            Row(
              children: [
                Expanded(
                  child: _smallCount(
                    icon: Icons.check_circle_outline,
                    label: 'Active',
                    value: activeStudents,
                    iconColor: Colors.green.shade600,
                    backgroundColor: Colors.green.shade50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallCount(
                    icon: Icons.cancel_outlined,
                    label: 'Inactive',
                    value: inactiveStudents,
                    iconColor: Colors.red.shade600,
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =====================================================
            // NEW THIS MONTH
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'New This Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Text(
                    '$newStudentsThisMonth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // =====================================================
            // DIVIDER
            // =====================================================

            Divider(
              color: Colors.grey.shade200,
              height: 1,
            ),

            const SizedBox(height: 18),

            // =====================================================
            // STATUS DISTRIBUTION
            // =====================================================

            const Text(
              'Status Distribution',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 12),

            _statusBar(
              label: 'Active',
              value: activeStudents,
              total: totalStudents,
              color: Colors.green.shade500,
            ),

            const SizedBox(height: 12),

            _statusBar(
              label: 'Inactive',
              value: inactiveStudents,
              total: totalStudents,
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // MAIN COUNT
  // =============================================================

  Widget _mainCount({
    required IconData icon,
    required String label,
    required int value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SMALL COUNT
  // =============================================================

  Widget _smallCount({
    required IconData icon,
    required String label,
    required int value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: iconColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // STATUS BAR
  // =============================================================

  Widget _statusBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total == 0
        ? 0.0
        : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}