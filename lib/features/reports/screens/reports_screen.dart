import 'package:flutter/material.dart';

import 'attendance_report_screen.dart';
import 'examination_report_screen.dart';
import 'fee_report_screen.dart';
import 'academic_performance_screen.dart';
import 'student_performance_screen.dart';
import 'class_performance_screen.dart';
import 'mcq_performance_screen.dart';
import '../../reports/screens/attendance_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      // _ReportItem(
      //   title: 'Attendance Report',
      //   subtitle: 'Student attendance and daily records',
      //   icon: Icons.fact_check_rounded,
      //   color: const Color(0xFF4F46E5),
      //   page: const AttendanceReportScreen(),
      // ),
      _ReportItem(
        title: 'Examination Report',
        subtitle: 'Exam schedules and examination data',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF0891B2),
        page: const ExaminationReportScreen(),
      ),
      _ReportItem(
        title: 'Fee Report',
        subtitle: 'Payment and fee collection records',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669),
        page: const FeeReportScreen(),
      ),
      // _ReportItem(
      //   title: 'Academic Performance',
      //   subtitle: 'Overall examination performance',
      //   icon: Icons.bar_chart_rounded,
      //   color: const Color(0xFF7C3AED),
      //   page: const AcademicPerformanceScreen(),
      // ),
      // _ReportItem(
      //   title: 'Student Performance',
      //   subtitle: 'Individual student performance',
      //   icon: Icons.person_search_rounded,
      //   color: const Color(0xFFEA580C),
      //   page: const StudentPerformanceScreen(),
      // ),
      // _ReportItem(
      //   title: 'Class Performance',
      //   subtitle: 'Class and examination performance',
      //   icon: Icons.groups_rounded,
      //   color: const Color(0xFF2563EB),
      //   page: const ClassPerformanceScreen(),
      // ),
      // _ReportItem(
      //   title: 'MCQ Performance',
      //   subtitle: 'Online test and MCQ analytics',
      //   icon: Icons.quiz_rounded,
      //   color: const Color(0xFFDB2777),
      //   page: const McqPerformanceScreen(),
      // ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Analyze attendance, academics, examinations, fees and student performance.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  mainAxisExtent: 175,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemBuilder: (context, index) {
                  final item = reports[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => item.page,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}