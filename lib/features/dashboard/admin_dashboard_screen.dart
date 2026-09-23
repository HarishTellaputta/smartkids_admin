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

      if (!mounted) return;

      setState(() {
        _studentCount = data['students'] ?? 0;
        _teacherCount = data['teachers'] ?? 0;

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
                            _isLoadingAttendanceDashboard||
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
              Expanded(
                flex: 1,
                child: StatCard(
                  title: 'Students',
                  value: _isLoadingDashboard ? '...' : _studentCount.toString(),
                  icon: Icons.people,
                  subtitle: 'Total students',
                ),
              ),

              const SizedBox(width: 16),

              Expanded(flex: 2, child: _buildLastSixDaysAttendanceCard()),
            ],
          );
        }

        return Column(
          children: [
            StatCard(
              title: 'Students',
              value: _isLoadingDashboard ? '...' : _studentCount.toString(),
              icon: Icons.people,
              subtitle: 'Total students',
            ),

            const SizedBox(height: 16),

            _buildLastSixDaysAttendanceCard(),
          ],
        );
      },
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

  Widget _buildAttendanceCard() {
    if (_isLoadingAttendanceDashboard) {
      return _buildDashboardCard(
        title: 'Today\'s Attendance',
        icon: Icons.calendar_month_outlined,
        child: const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_attendanceDashboardError != null ||
        _attendanceDashboardSummary == null) {
      return _buildDashboardCard(
        title: 'Today\'s Attendance',
        icon: Icons.calendar_month_outlined,
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to load attendance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
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

    return _buildDashboardCard(
      title: 'Today\'s Attendance',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Text(
                          'Present',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 30),

              Expanded(
                child: Column(
                  children: [
                    _buildAttendanceRow(
                      'Present',
                      summary.present.toString(),
                      const Color(0xFF2563EB),
                    ),

                    const SizedBox(height: 14),

                    _buildAttendanceRow(
                      'Absent',
                      summary.absent.toString(),
                      const Color(0xFFEF4444),
                    ),

                    const SizedBox(height: 14),

                    _buildAttendanceRow(
                      'Leave',
                      summary.leave.toString(),
                      const Color(0xFFF59E0B),
                    ),

                    const SizedBox(height: 14),

                    _buildAttendanceRow(
                      'Total Students',
                      summary.totalStudents.toString(),
                      const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marked: ${summary.marked}/${summary.totalStudents}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),

              Text(
                'Not Marked: ${summary.totalStudents - summary.marked}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
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

  Widget _buildFeeCard() {
    if (_isLoadingFeeDashboard) {
      return _buildDashboardCard(
        title: 'Fee Collection',
        icon: Icons.currency_rupee,
        child: const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_feeDashboardError != null || _feeDashboardSummary == null) {
      return _buildDashboardCard(
        title: 'Fee Collection',
        icon: Icons.currency_rupee,
        child: SizedBox(
          height: 220,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to load fee summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
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

    return _buildDashboardCard(
      title: 'Fee Collection',
      icon: Icons.currency_rupee,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Text(
            _formatIndianCurrency(summary.collected),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Total fees collected',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collected: ${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),

              Text(
                'Total: ${_formatIndianCurrency(summary.totalFee)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _buildFeeInfo(
                'Collected',
                _formatIndianCurrency(summary.collected),
              ),

              const SizedBox(width: 35),

              _buildFeeInfo('Pending', _formatIndianCurrency(summary.pending)),
            ],
          ),
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
    return _buildDashboardCard(
      title: 'Recent Activity',
      icon: Icons.history,
      actionText: 'View All',
      onActionPressed: () {},
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.person_add_outlined,
            title: 'New student registered',
            subtitle: 'Rahul Kumar joined Class 5',
            time: '10 min ago',
          ),
          _buildActivityItem(
            icon: Icons.currency_rupee,
            title: 'Fee payment received',
            subtitle: '₹12,500 received from Anitha',
            time: '35 min ago',
          ),
          _buildActivityItem(
            icon: Icons.psychology_outlined,
            title: 'Daily MCQ published',
            subtitle: 'Class 5 Mathematics test published',
            time: '1 hour ago',
          ),
          _buildActivityItem(
            icon: Icons.campaign_outlined,
            title: 'Notice published',
            subtitle: 'Independence Day holiday notice',
            time: '2 hours ago',
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.circle, size: 8, color: Color(0xFF2563EB)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            time,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _buildDashboardCard(
      title: 'Quick Actions',
      icon: Icons.flash_on_outlined,
      child: Column(
        children: [
          _buildQuickAction(
            icon: Icons.person_add_outlined,
            title: 'Add Student',
            onTap: () => _onMenuSelected(1),
          ),
          _buildQuickAction(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Add Teacher',
            onTap: () => _onMenuSelected(2),
          ),
          _buildQuickAction(
            icon: Icons.psychology_outlined,
            title: 'Create MCQ Test',
            onTap: () => _onMenuSelected(11),
          ),
          _buildQuickAction(
            icon: Icons.campaign_outlined,
            title: 'Create Notice',
            onTap: () => _onMenuSelected(13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 19, color: const Color(0xFF2563EB)),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFF9CA3AF),
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
    if (_isLoadingLastSixDaysAttendance) {
      return _buildDashboardCard(
        title: 'Last 6 Days Attendance',
        icon: Icons.bar_chart_rounded,
        child: const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_lastSixDaysAttendanceError != null) {
      return _buildDashboardCard(
        title: 'Last 6 Days Attendance',
        icon: Icons.bar_chart_rounded,
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to load attendance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadLastSixDaysAttendance,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_lastSixDaysAttendance.isEmpty) {
      return _buildDashboardCard(
        title: 'Last 6 Days Attendance',
        icon: Icons.bar_chart_rounded,
        child: const SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'No attendance data available',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    }

    final attendance = _lastSixDaysAttendance;

    return _buildDashboardCard(
      title: 'Last 6 Days Attendance',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 320,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: 100,
            alignment: BarChartAlignment.spaceAround,

            // Grid
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
            ),

            // Remove chart border
            borderData: FlBorderData(show: false),

            // Touch / Tooltip
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, groupRod, rodIndex) {
                  final item = attendance[groupIndex];

                  return BarTooltipItem(
                    '${item.day}\n'
                    '${item.attendancePercentage.toStringAsFixed(1)}% Attendance\n'
                    'Present: ${item.present}\n'
                    'Absent: ${item.absent}\n'
                    'Leave: ${item.leave}',
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  );
                },
              ),
            ),

            // Axis Titles
            titlesData: FlTitlesData(
              // Top
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              // Right
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              // Left percentage
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: 20,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),

              // Bottom days
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (value, meta) {
                    final int index = value.toInt();

                    if (index < 0 || index >= attendance.length) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        attendance[index].day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Six attendance bars
            barGroups: List.generate(attendance.length, (index) {
              final double percentage = attendance[index].attendancePercentage
                  .clamp(0.0, 100.0)
                  .toDouble();

              return BarChartGroupData(
                x: index,
                barsSpace: 0,
                barRods: [
                  BarChartRodData(
                    toY: percentage,
                    width: 28,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    color: const Color(0xFF2563EB),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
