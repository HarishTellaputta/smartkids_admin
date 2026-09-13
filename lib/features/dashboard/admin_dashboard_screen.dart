import 'package:flutter/material.dart';

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
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../services/admin_dashboard_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiClient _apiClient = ApiClient();

  late final AdminDashboardService _dashboardService;

  bool _isLoadingDashboard = true;
  String? _dashboardError;

  int _studentCount = 0;
  int _teacherCount = 0;
  int _classCount = 0;

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
        _classCount = data['classes'] ?? 0;

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
                    onPressed: _isLoadingDashboard ? null : _loadDashboardData,
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
        int crossAxisCount;

        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _getStatCardAspectRatio(crossAxisCount),
          children: [
            StatCard(
              title: 'Students',
              value: _isLoadingDashboard ? '...' : _studentCount.toString(),
              icon: Icons.people,
              subtitle: 'Total students',
            ),

            StatCard(
              title: 'Teachers',
              value: _isLoadingDashboard ? '...' : _teacherCount.toString(),
              icon: Icons.person,
              subtitle: 'Total teachers',
            ),
            StatCard(
              title: 'Classes',
              value: _isLoadingDashboard ? '...' : _classCount.toString(),
              icon: Icons.class_,
              subtitle: 'Total classes',
            ),
            StatCard(
              title: 'Parents',
              value: '310',
              subtitle: 'Registered Parents',
              icon: Icons.family_restroom_outlined,
              onTap: () => _onMenuSelected(4),
            ),
          ],
        );
      },
    );
  }

  double _getStatCardAspectRatio(int crossAxisCount) {
    if (crossAxisCount == 4) {
      return 2.0;
    }

    if (crossAxisCount == 2) {
      return 2.3;
    }

    return 3.2;
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
                        value: 0.92,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '92%',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
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
                      '322',
                      const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 14),
                    _buildAttendanceRow(
                      'Absent',
                      '18',
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 14),
                    _buildAttendanceRow(
                      'Total',
                      '350',
                      const Color(0xFF6B7280),
                    ),
                  ],
                ),
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
    return _buildDashboardCard(
      title: 'Fee Collection',
      icon: Icons.currency_rupee,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const Text(
            '₹35.20 L',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Total fees collected this academic year',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.78,
              minHeight: 10,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Collected: 78%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              Text(
                'Target: ₹45.00 L',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _buildFeeInfo('Collected', '₹35.20 L'),
              const SizedBox(width: 35),
              _buildFeeInfo('Pending', '₹9.80 L'),
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
            onTap: () => _onMenuSelected(10),
          ),
          _buildQuickAction(
            icon: Icons.campaign_outlined,
            title: 'Create Notice',
            onTap: () => _onMenuSelected(12),
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
        return const ParentsScreen();

      case 5:
        return const AttendanceScreen();

      case 6:
        return const HomeworkScreen();

      case 7:
        return const TimetableScreen();

      case 8:
        return const FeesScreen();

      case 9:
        return const ExamsScreen();

      case 10:
        return const McqScreen();

      case 11:
        return const ResultsScreen();

      case 12:
        return const NoticesScreen();

      case 13:
        return const EventsScreen();

      case 14:
        return const AdmissionsScreen();

      case 15:
        return const SettingsScreen();

      case 16:
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
}
