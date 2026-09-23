import 'package:flutter/material.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_dashboard_summary_model.dart';
import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';
import 'package:smartkids_admin/features/fees/models/fee_dashboard_summary_model.dart';
import 'package:smartkids_admin/features/fees/services/fee_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_last_six_days_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartkids_admin/services/parent_service.dart';

import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_topbar.dart';
import '../../widgets/stat_card.dart';
import '../students/students_screen.dart';
import '../classes/classes_screen.dart';
import '../teachers/teachers_screen.dart';
import '../parents/parents_screen.dart';
import '../attendance/attendance_screen.dart';
import '../homework/homework_screen.dart';
import '../timetable/timetable_screen.dart';
import '../fees/fees_screen.dart';
import '../exams/exams_screen.dart';
import '../mcq/mcq_screen.dart';
import '../results/results_screen.dart';
import '../notices/notices_screen.dart';
import '../events/events_screen.dart';
import '../admissions/admissions_screen.dart';
import '../settings/settings_screen.dart';

import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../services/admin_dashboard_service.dart';
import '../subjects/subjects_screen.dart';
import 'package:smartkids_admin/models/student_gender_summary.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiClient _apiClient = ApiClient();

  late final AdminDashboardService _dashboardService;

  final FeeService _feeService = FeeService();

  FeeDashboardSummaryModel? _feeDashboardSummary;

  AttendanceDashboardSummaryModel? _attendanceDashboardSummary;

  bool _isLoadingAttendanceDashboard = true;
  String? _attendanceDashboardError;
  bool _isLoadingFeeDashboard = true;
  String? _feeDashboardError;

  List<AttendanceLastSixDaysModel> _lastSixDaysAttendance = [];

  bool _isLoadingLastSixDaysAttendance = true;
  String? _lastSixDaysAttendanceError;

  bool _isLoadingDashboard = true;
  String? _dashboardError;

  int _studentCount = 0;
  StudentGenderSummary? _studentGenderSummary;
  int _teacherCount = 0;

  int selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onMenuSelected(int index) {
    setState(() {
      selectedIndex = index;
    });

    // Close drawer on mobile after selecting an item.
    if (MediaQuery.of(context).size.width < 900) {
      Navigator.of(context).pop();
    }

    // Dashboard is currently the only functional page.
    // Other modules will be connected one by one.
  }

  @override
  void initState() {
    super.initState();

    _dashboardService = AdminDashboardService(_apiClient);

    _loadDashboardData();
    _loadFeeDashboardSummary();
    _loadAttendanceDashboardSummary();
    _loadLastSixDaysAttendance();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final data = await _dashboardService.getDashboardCounts();
      final genderSummary = await _dashboardService.getStudentGenderSummary();

      if (!mounted) return;

      setState(() {
        _studentCount = data['students'] ?? 0;
        _teacherCount = data['teachers'] ?? 0;

        _studentGenderSummary = genderSummary;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingDashboard = false;
        _dashboardError = e.toString();
      });
    }
  }

  Future<void> _loadFeeDashboardSummary() async {
    setState(() {
      _isLoadingFeeDashboard = true;
      _feeDashboardError = null;
    });

    try {
      final data = await _feeService.getDashboardSummary();

      if (!mounted) return;

      setState(() {
        _feeDashboardSummary = data;
        _isLoadingFeeDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFeeDashboard = false;
        _feeDashboardError = e.toString();
      });
    }
  }

  Future<void> _loadAttendanceDashboardSummary() async {
    setState(() {
      _isLoadingAttendanceDashboard = true;
      _attendanceDashboardError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.trim().isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }

      final attendanceService = AttendanceService(token.trim());

      final data = await attendanceService.getDashboardSummary();

      if (!mounted) return;

      setState(() {
        _attendanceDashboardSummary = data;
        _isLoadingAttendanceDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAttendanceDashboard = false;
        _attendanceDashboardError = e.toString();
      });
    }
  }

  Future<void> _loadLastSixDaysAttendance() async {
    setState(() {
      _isLoadingLastSixDaysAttendance = true;
      _lastSixDaysAttendanceError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token not found');
      }

      final attendanceService = AttendanceService(token.trim());

      final data = await attendanceService.getLastSixDaysAttendance();

      if (!mounted) return;

      setState(() {
        _lastSixDaysAttendance = data;
        _isLoadingLastSixDaysAttendance = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lastSixDaysAttendanceError = e.toString();
        _isLoadingLastSixDaysAttendance = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final apiClient = ApiClient();
      final authService = AuthService(apiClient);

      await authService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _menuName(int index) {
    const names = [
      'Dashboard',
      'Students',
      'Teachers',
      'Classes',
      'Subjects',
      'Parents',
      'Attendance',
      'Homework',
      'Timetable',
      'Fees',
      'Exams',
      'MCQ Tests',
      'Results',
      'Notices',
      'Events',
      'Admissions',
      'Settings',
      'Logout',
    ];

    if (index >= 0 && index < names.length) {
      return names[index];
    }

    return 'Selected';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),

      // Mobile drawer
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(
              width: 270,
              child: AdminSidebar(
                selectedIndex: selectedIndex,
                onItemSelected: _onMenuSelected,
              ),
            )
          : null,

      body: Row(
        children: [
          // Desktop sidebar
          if (MediaQuery.of(context).size.width >= 900)
            AdminSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: _onMenuSelected,
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                AdminTopbar(
                  onMenuPressed: MediaQuery.of(context).size.width < 900
                      ? () {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      : null,
                ),

                Expanded(child: _buildSelectedScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(),

        const SizedBox(height: 24),

        _buildStatsGrid(),

        const SizedBox(height: 24),

        _buildOverviewSection(),

        const SizedBox(height: 24),

        _buildBottomSection(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed:
                        (_isLoadingDashboard ||
                            _isLoadingFeeDashboard ||
                            _isLoadingAttendanceDashboard ||
                            _isLoadingLastSixDaysAttendance)
                        ? null
                        : () {
                            _loadDashboardData();
                            _loadFeeDashboardSummary();
                            _loadAttendanceDashboardSummary();
                            _loadLastSixDaysAttendance();
                          },
                    tooltip: 'Refresh dashboard',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Here is what is happening at SmartKids Patashala today.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        _buildDateCard(),
      ],
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
          SizedBox(width: 10),
          Text(
            'Today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildStudentsCard()),

              const SizedBox(width: 16),

              Expanded(flex: 2, child: _buildLastSixDaysAttendanceCard()),
            ],
          );
        }

        return Column(
          children: [
            _buildStudentsCard(),

            const SizedBox(height: 16),

            _buildLastSixDaysAttendanceCard(),
          ],
        );
      },
    );
  }

  Widget _buildStudentsCard() {
    final summary = _studentGenderSummary;

    final totalStudents = summary?.totalStudents ?? _studentCount;

    final boys = summary?.boys ?? 0;
    final girls = summary?.girls ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        border: Border.all(color: Colors.blue.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────── HEADER ─────────────────
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.indigo.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Student overview',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ───────────────── TOTAL ─────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.blue.shade600,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _isLoadingDashboard ? '...' : totalStudents.toString(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ───────────────── GENDER ─────────────────
          Row(
            children: [
              Expanded(
                child: _buildPremiumGenderCard(
                  icon: Icons.boy_rounded,
                  title: 'Boys',
                  value: _isLoadingDashboard ? '...' : boys.toString(),
                  iconColor: Colors.blue.shade600,
                  backgroundColor: Colors.blue.shade50,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildPremiumGenderCard(
                  icon: Icons.girl_rounded,
                  title: 'Girls',
                  value: _isLoadingDashboard ? '...' : girls.toString(),
                  iconColor: Colors.pink.shade500,
                  backgroundColor: Colors.pink.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGenderCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCount({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),

            const SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAttendanceCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildFeeCard()),
            ],
          );
        }

        return Column(
          children: [
            _buildAttendanceCard(),
            const SizedBox(height: 20),
            _buildFeeCard(),
          ],
        );
      },
    );
  }

  // Widget _buildAttendanceCard() {
  //   if (_isLoadingAttendanceDashboard) {
  //     return _buildDashboardCard(
  //       title: 'Today\'s Attendance',
  //       icon: Icons.calendar_month_outlined,
  //       child: const SizedBox(
  //         height: 180,
  //         child: Center(child: CircularProgressIndicator()),
  //       ),
  //     );
  //   }

  //   if (_attendanceDashboardError != null ||
  //       _attendanceDashboardSummary == null) {
  //     return _buildDashboardCard(
  //       title: 'Today\'s Attendance',
  //       icon: Icons.calendar_month_outlined,
  //       child: SizedBox(
  //         height: 180,
  //         child: Center(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Icon(
  //                 Icons.error_outline,
  //                 size: 32,
  //                 color: Color(0xFFEF4444),
  //               ),
  //               const SizedBox(height: 10),
  //               const Text(
  //                 'Unable to load attendance',
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w600,
  //                   color: Color(0xFF374151),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               TextButton(
  //                 onPressed: _loadAttendanceDashboardSummary,
  //                 child: const Text('Retry'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   final summary = _attendanceDashboardSummary!;

  //   final double percentage = summary.attendancePercentage
  //       .clamp(0.0, 100.0)
  //       .toDouble();

  //   return _buildDashboardCard(
  //     title: 'Today\'s Attendance',
  //     icon: Icons.calendar_month_outlined,
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 10),

  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             SizedBox(
  //               height: 120,
  //               width: 120,
  //               child: Stack(
  //                 alignment: Alignment.center,
  //                 children: [
  //                   SizedBox(
  //                     height: 120,
  //                     width: 120,
  //                     child: CircularProgressIndicator(
  //                       value: percentage / 100,
  //                       strokeWidth: 12,
  //                       backgroundColor: const Color(0xFFE5E7EB),
  //                       valueColor: const AlwaysStoppedAnimation<Color>(
  //                         Color(0xFF2563EB),
  //                       ),
  //                     ),
  //                   ),

  //                   Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
  //                         style: const TextStyle(
  //                           fontSize: 25,
  //                           fontWeight: FontWeight.bold,
  //                           color: Color(0xFF111827),
  //                         ),
  //                       ),
  //                       const Text(
  //                         'Present',
  //                         style: TextStyle(
  //                           fontSize: 11,
  //                           color: Color(0xFF6B7280),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             const SizedBox(width: 30),

  //             Expanded(
  //               child: Column(
  //                 children: [
  //                   _buildAttendanceRow(
  //                     'Present',
  //                     summary.present.toString(),
  //                     const Color(0xFF2563EB),
  //                   ),

  //                   const SizedBox(height: 14),

  //                   _buildAttendanceRow(
  //                     'Absent',
  //                     summary.absent.toString(),
  //                     const Color(0xFFEF4444),
  //                   ),

  //                   const SizedBox(height: 14),

  //                   _buildAttendanceRow(
  //                     'Leave',
  //                     summary.leave.toString(),
  //                     const Color(0xFFF59E0B),
  //                   ),

  //                   const SizedBox(height: 14),

  //                   _buildAttendanceRow(
  //                     'Total Students',
  //                     summary.totalStudents.toString(),
  //                     const Color(0xFF6B7280),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 18),

  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Marked: ${summary.marked}/${summary.totalStudents}',
  //               style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  //             ),

  //             Text(
  //               'Not Marked: ${summary.totalStudents - summary.marked}',
  //               style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildAttendanceRow(String title, String value, Color color) {
  //   return Row(
  //     children: [
  //       Container(
  //         height: 9,
  //         width: 9,
  //         decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  //       ),
  //       const SizedBox(width: 9),
  //       Expanded(
  //         child: Text(
  //           title,
  //           style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Color(0xFF111827),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildFeeCard() {
  //   if (_isLoadingFeeDashboard) {
  //     return _buildDashboardCard(
  //       title: 'Fee Collection',
  //       icon: Icons.currency_rupee,
  //       child: const SizedBox(
  //         height: 220,
  //         child: Center(child: CircularProgressIndicator()),
  //       ),
  //     );
  //   }

  //   if (_feeDashboardError != null || _feeDashboardSummary == null) {
  //     return _buildDashboardCard(
  //       title: 'Fee Collection',
  //       icon: Icons.currency_rupee,
  //       child: SizedBox(
  //         height: 220,
  //         child: Center(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Icon(
  //                 Icons.error_outline,
  //                 size: 32,
  //                 color: Color(0xFFEF4444),
  //               ),
  //               const SizedBox(height: 10),
  //               const Text(
  //                 'Unable to load fee summary',
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w600,
  //                   color: Color(0xFF374151),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               TextButton(
  //                 onPressed: _loadFeeDashboardSummary,
  //                 child: const Text('Retry'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   final summary = _feeDashboardSummary!;

  //   final double percentage = summary.collectionPercentage
  //       .clamp(0.0, 100.0)
  //       .toDouble();

  //   return _buildDashboardCard(
  //     title: 'Fee Collection',
  //     icon: Icons.currency_rupee,
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 10),

  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             // Circular Fee Collection Percentage
  //             SizedBox(
  //               height: 130,
  //               width: 130,
  //               child: Stack(
  //                 alignment: Alignment.center,
  //                 children: [
  //                   SizedBox(
  //                     height: 130,
  //                     width: 130,
  //                     child: CircularProgressIndicator(
  //                       value: percentage / 100,
  //                       strokeWidth: 12,
  //                       backgroundColor: const Color(0xFFE5E7EB),
  //                       valueColor: const AlwaysStoppedAnimation<Color>(
  //                         Color(0xFF2563EB),
  //                       ),
  //                     ),
  //                   ),

  //                   Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
  //                         style: const TextStyle(
  //                           fontSize: 25,
  //                           fontWeight: FontWeight.bold,
  //                           color: Color(0xFF111827),
  //                         ),
  //                       ),
  //                       const Text(
  //                         'Collected',
  //                         style: TextStyle(
  //                           fontSize: 11,
  //                           color: Color(0xFF6B7280),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             const SizedBox(width: 30),

  //             // Fee Details
  //             Expanded(
  //               child: Column(
  //                 children: [
  //                   _buildFeeDashboardRow(
  //                     'Collected',
  //                     _formatIndianCurrency(summary.collected),
  //                     const Color(0xFF2563EB),
  //                   ),

  //                   const SizedBox(height: 16),

  //                   _buildFeeDashboardRow(
  //                     'Pending',
  //                     _formatIndianCurrency(summary.pending),
  //                     const Color(0xFFEF4444),
  //                   ),

  //                   const SizedBox(height: 16),

  //                   _buildFeeDashboardRow(
  //                     'Total Fees',
  //                     _formatIndianCurrency(summary.totalFee),
  //                     const Color(0xFF6B7280),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 20),

  //         // Bottom Summary
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Collected: ${_formatIndianCurrency(summary.collected)}',
  //               style: const TextStyle(
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w600,
  //                 color: Color(0xFF2563EB),
  //               ),
  //             ),

  //             Text(
  //               'Pending: ${_formatIndianCurrency(summary.pending)}',
  //               style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFeeDashboardRow(String title, String value, Color color) {
  //   return Row(
  //     children: [
  //       Container(
  //         height: 9,
  //         width: 9,
  //         decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  //       ),

  //       const SizedBox(width: 9),

  //       Expanded(
  //         child: Text(
  //           title,
  //           style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
  //         ),
  //       ),

  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Color(0xFF111827),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildAttendanceCard() {
    if (_isLoadingAttendanceDashboard) {
      return _buildPremiumOverviewCard(
        icon: Icons.calendar_month_rounded,
        title: "Today's Attendance",
        subtitle: 'Daily attendance overview',
        iconColors: [Colors.indigo.shade600, Colors.blue.shade500],
        child: const SizedBox(
          height: 230,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    if (_attendanceDashboardError != null ||
        _attendanceDashboardSummary == null) {
      return _buildPremiumOverviewCard(
        icon: Icons.calendar_month_rounded,
        title: "Today's Attendance",
        subtitle: 'Daily attendance overview',
        iconColors: [Colors.indigo.shade600, Colors.blue.shade500],
        child: SizedBox(
          height: 230,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load attendance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _loadAttendanceDashboardSummary,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _attendanceDashboardSummary!;

    final double percentage = summary.attendancePercentage
        .clamp(0.0, 100.0)
        .toDouble();

    final int notMarked = (summary.totalStudents - summary.marked).clamp(
      0,
      summary.totalStudents,
    );

    return _buildPremiumOverviewCard(
      icon: Icons.calendar_month_rounded,
      title: "Today's Attendance",
      subtitle: 'Daily attendance overview',
      iconColors: [Colors.indigo.shade600, Colors.blue.shade500],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              '${summary.marked} Marked',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ───────────── MAIN ATTENDANCE ─────────────
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.indigo.shade50, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.indigo.withOpacity(0.08)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.indigo.shade600,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Attendance',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ───────────── DETAILS ─────────────
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildPremiumAttendanceStat(
                      icon: Icons.check_circle_rounded,
                      title: 'Present',
                      value: summary.present.toString(),
                      color: Colors.green,
                      background: Colors.green.shade50,
                    ),

                    const SizedBox(height: 9),

                    _buildPremiumAttendanceStat(
                      icon: Icons.cancel_rounded,
                      title: 'Absent',
                      value: summary.absent.toString(),
                      color: Colors.red,
                      background: Colors.red.shade50,
                    ),

                    const SizedBox(height: 9),

                    _buildPremiumAttendanceStat(
                      icon: Icons.event_busy_rounded,
                      title: 'Leave',
                      value: summary.leave.toString(),
                      color: Colors.orange.shade700,
                      background: Colors.orange.shade50,
                    ),

                    const SizedBox(height: 9),

                    _buildPremiumAttendanceStat(
                      icon: Icons.groups_rounded,
                      title: 'Total Students',
                      value: summary.totalStudents.toString(),
                      color: Colors.indigo,
                      background: Colors.indigo.shade50,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ───────────── MARKING STATUS ─────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.80),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.done_all_rounded,
                          size: 17,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marked',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${summary.marked} Students',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey.withOpacity(0.12),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 17,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Not Marked',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$notMarked Students',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
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
        ],
      ),
    );
  }

  Widget _buildPremiumAttendanceStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard() {
    if (_isLoadingFeeDashboard) {
      return _buildPremiumOverviewCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Fee Collection',
        subtitle: 'Fee collection overview',
        iconColors: [Colors.teal.shade600, Colors.green.shade500],
        child: const SizedBox(
          height: 230,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      );
    }

    if (_feeDashboardError != null || _feeDashboardSummary == null) {
      return _buildPremiumOverviewCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Fee Collection',
        subtitle: 'Fee collection overview',
        iconColors: [Colors.teal.shade600, Colors.green.shade500],
        child: SizedBox(
          height: 230,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load fee summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _loadFeeDashboardSummary,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _feeDashboardSummary!;

    final double percentage = summary.collectionPercentage
        .clamp(0.0, 100.0)
        .toDouble();

    return _buildPremiumOverviewCard(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Fee Collection',
      subtitle: 'Fee collection overview',
      iconColors: [Colors.teal.shade600, Colors.green.shade500],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ───────────── MAIN FEE SECTION ─────────────
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.teal.shade50, Colors.green.shade50],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.teal.withOpacity(0.08)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.teal.shade600,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Collected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ───────────── FEE DETAILS ─────────────
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildPremiumFeeStat(
                      icon: Icons.check_circle_rounded,
                      title: 'Collected',
                      value: _formatIndianCurrency(summary.collected),
                      color: Colors.green,
                      background: Colors.green.shade50,
                    ),

                    const SizedBox(height: 11),

                    _buildPremiumFeeStat(
                      icon: Icons.pending_actions_rounded,
                      title: 'Pending',
                      value: _formatIndianCurrency(summary.pending),
                      color: Colors.orange.shade700,
                      background: Colors.orange.shade50,
                    ),

                    const SizedBox(height: 11),

                    _buildPremiumFeeStat(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Total Fees',
                      value: _formatIndianCurrency(summary.totalFee),
                      color: Colors.teal,
                      background: Colors.teal.shade50,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ───────────── FEE SUMMARY ─────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.80),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          size: 17,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collected',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatIndianCurrency(summary.collected),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey.withOpacity(0.12),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.pending_rounded,
                          size: 17,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatIndianCurrency(summary.pending),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
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
        ],
      ),
    );
  }

  Widget _buildPremiumFeeStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOverviewCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> iconColors,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, iconColors.first.withOpacity(0.035)],
        ),
        border: Border.all(color: iconColors.first.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: iconColors.first.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────── HEADER ─────────────
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconColors,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconColors.first.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              if (trailing != null) trailing,
            ],
          ),

          child,
        ],
      ),
    );
  }

  Widget _buildFeeInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTeacherSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSmallCountItem(
          icon: Icons.people_alt_rounded,
          label: 'Students',
          value: _isLoadingDashboard ? '...' : _studentCount.toString(),
        ),
        const SizedBox(width: 20),
        _buildSmallCountItem(
          icon: Icons.person_rounded,
          label: 'Teachers',
          value: _isLoadingDashboard ? '...' : _teacherCount.toString(),
        ),
      ],
    );
  }

  Widget _buildSmallCountItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  String _formatIndianCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }

    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }

    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)} K';
    }

    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRecentActivity()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildQuickActions()),
            ],
          );
        }

        return Column(
          children: [
            _buildRecentActivity(),
            const SizedBox(height: 20),
            _buildQuickActions(),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade600, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Latest updates from your school',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.person_add_rounded,
                  title: 'New student registered',
                  subtitle: 'Rahul Kumar joined Class 5',
                  time: '10 min ago',
                  iconColor: Colors.blue,
                  iconBackground: Colors.blue.shade50,
                  showLine: true,
                ),

                _buildActivityItem(
                  icon: Icons.payments_rounded,
                  title: 'Fee payment received',
                  subtitle: '₹12,500 received from Anitha',
                  time: '35 min ago',
                  iconColor: Colors.green,
                  iconBackground: Colors.green.shade50,
                  showLine: true,
                ),

                _buildActivityItem(
                  icon: Icons.quiz_rounded,
                  title: 'Daily MCQ published',
                  subtitle: 'Class 5 Mathematics test published',
                  time: '1 hour ago',
                  iconColor: Colors.purple,
                  iconBackground: Colors.purple.shade50,
                  showLine: true,
                ),

                _buildActivityItem(
                  icon: Icons.campaign_rounded,
                  title: 'Notice published',
                  subtitle: 'Independence Day holiday notice',
                  time: '2 hours ago',
                  iconColor: Colors.orange.shade700,
                  iconBackground: Colors.orange.shade50,
                  showLine: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
    required Color iconBackground,
    required bool showLine,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),

                if (showLine)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.grey.withOpacity(0.14),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange.shade50.withOpacity(0.35)],
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade600, Colors.amber.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Frequently used actions',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildQuickAction(
            icon: Icons.person_add_rounded,
            title: 'Add Student',
            onTap: () => _onMenuSelected(1),
            color: Colors.blue,
            background: Colors.blue.shade50,
          ),

          _buildQuickAction(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Add Teacher',
            onTap: () => _onMenuSelected(2),
            color: Colors.indigo,
            background: Colors.indigo.shade50,
          ),

          _buildQuickAction(
            icon: Icons.quiz_rounded,
            title: 'Create MCQ Test',
            onTap: () => _onMenuSelected(11),
            color: Colors.purple,
            background: Colors.purple.shade50,
          ),

          _buildQuickAction(
            icon: Icons.campaign_rounded,
            title: 'Create Notice',
            onTap: () => _onMenuSelected(13),
            color: Colors.orange.shade700,
            background: Colors.orange.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    required Color background,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: background.withOpacity(0.65),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.07)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: color.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 19, color: const Color(0xFF2563EB)),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              if (actionText != null)
                TextButton(
                  onPressed: onActionPressed,
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _buildDashboardContent(),
        );

      case 1:
        return const StudentsScreen();

      case 2:
        return const TeachersScreen();

      case 3:
        return const ClassesScreen();

      case 4:
        return const SubjectsScreen(schoolId: 1);

      case 5:
        return const ParentsScreen();

      case 6:
        return const AttendanceScreen();

      case 7:
        return const HomeworkScreen();

      case 8:
        return const TimetableScreen();

      case 9:
        return const FeesScreen();

      case 10:
        return const ExamsScreen();

      case 11:
        return const McqScreen();

      case 12:
        return const ResultsScreen();

      case 13:
        return const NoticesScreen();

      case 14:
        return const EventsScreen();

      case 15:
        return const AdmissionsScreen();

      case 16:
        return const SettingsScreen();

      case 17:
        return _buildLogoutScreen();

      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _buildDashboardContent(),
        );
    }
  }

  Widget _buildLogoutScreen() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.logout_outlined,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedIndex = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSixDaysAttendanceCard() {
    // Existing data
    final attendanceData = _lastSixDaysAttendance;

    double averageAttendance = 0;

    if (attendanceData.isNotEmpty) {
      final totalPercentage = attendanceData.fold<double>(
        0,
        (sum, item) => sum + item.attendancePercentage,
      );

      averageAttendance = totalPercentage / attendanceData.length;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.indigo.shade50],
        ),
        border: Border.all(color: Colors.indigo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────── HEADER ─────────────────
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade600, Colors.purple.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Last 6 days overview',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Average percentage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${averageAttendance.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'Average',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ───────────────── CHART CONTAINER ─────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: SizedBox(height: 210, child: _buildAttendanceChart()),
          ),

          const SizedBox(height: 16),

          // ───────────────── BOTTOM INFO ─────────────────
          Row(
            children: [
              Expanded(
                child: _buildAttendanceLegendItem(
                  icon: Icons.check_circle_rounded,
                  title: 'Present',
                  subtitle: 'Daily attendance',
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildAttendanceLegendItem(
                  icon: Icons.calendar_today_rounded,
                  title: '6 Days',
                  subtitle: 'Recent records',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLegendItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,

        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 18,

        // ───────────── GRID ─────────────
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.10), strokeWidth: 1);
          },
        ),

        // ───────────── BORDER ─────────────
        borderData: FlBorderData(show: false),

        // ───────────── TITLES ─────────────
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // LEFT: 0%, 20%, 40%...
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),

          // BOTTOM: dates
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= _lastSixDaysAttendance.length) {
                  return const SizedBox.shrink();
                }

                final item = _lastSixDaysAttendance[index];

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${item.date.day}/${item.date.month}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ───────────── BARS ─────────────
        barGroups: List.generate(_lastSixDaysAttendance.length, (index) {
          final item = _lastSixDaysAttendance[index];

          final percentage = item.attendancePercentage
              .clamp(0.0, 100.0)
              .toDouble();

          return BarChartGroupData(
            x: index,

            barRods: [
              BarChartRodData(
                toY: percentage,
                width: 24,

                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),

                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.indigo.shade500, Colors.purple.shade400],
                ),

                // Light background behind each bar
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: Colors.grey.withOpacity(0.05),
                ),
              ),
            ],
          );
        }),

        // ───────────── TOOLTIP ─────────────
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();

              if (index < 0 || index >= _lastSixDaysAttendance.length) {
                return null;
              }

              final item = _lastSixDaysAttendance[index];

              return BarTooltipItem(
                '${item.date.day}/${item.date.month}\n',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${item.attendancePercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
