import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/teacher_model.dart';
import 'models/class_model.dart';
import 'models/available_teacher_user_model.dart';

import 'services/teacher_service.dart';
import 'services/class_service.dart';
import 'services/teacher_assignment_service.dart';

import 'dialogs/add_teacher_dialog.dart';
import 'dialogs/edit_teacher_dialog.dart';
import 'dialogs/teacher_filter_dialog.dart';
import 'dialogs/teacher_details_dialog.dart';
import 'dialogs/assign_class_dialog.dart';
import 'dialogs/assign_class_dialog.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  static const int _schoolId = 1;

  TeacherService? _teacherService;
  ClassService? _classService;
  TeacherAssignmentService? _assignmentService;

  List<Teacher> _teachers = [];
  List<Teacher> _filteredTeachers = [];
  List<SchoolClass> _classes = [];
  List<AvailableTeacherUser> _availableTeacherUsers = [];

  bool _isLoading = true;
  bool _isLoadingClasses = false;
  bool _isLoadingAvailableUsers = false;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Authentication token not found.', isError: true);

      return;
    }

    _teacherService = TeacherService(token);
    _classService = ClassService(token);
    _assignmentService = TeacherAssignmentService(token);

    await _loadTeachers();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadTeachers() async {
    if (_teacherService == null) return;

    try {
      final teachers = await _teacherService!.getTeachers();

      if (!mounted) return;

      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _loadClasses() async {
    if (_classService == null) return;

    if (mounted) {
      setState(() {
        _isLoadingClasses = true;
      });
    }

    try {
      final classes = await _classService!.getClassesBySchool(_schoolId);

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingClasses = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _loadAvailableTeacherUsers() async {
    if (_teacherService == null) return;

    if (mounted) {
      setState(() {
        _isLoadingAvailableUsers = true;
      });
    }

    try {
      final users = await _teacherService!.getAvailableTeacherUsers();

      if (!mounted) return;

      setState(() {
        _availableTeacherUsers = users;
        _isLoadingAvailableUsers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAvailableUsers = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      _filteredTeachers = _teachers.where((teacher) {
        final matchesSearch =
            query.isEmpty ||
            (teacher.name ?? '').toLowerCase().contains(query) ||
            (teacher.employeeId ?? '').toLowerCase().contains(query) ||
            (teacher.phone ?? '').toLowerCase().contains(query) ||
            (teacher.email ?? '').toLowerCase().contains(query) ||
            (teacher.designation ?? '').toLowerCase().contains(query) ||
            (teacher.qualification ?? '').toLowerCase().contains(query);

        final status = (teacher.status ?? '').toUpperCase();

        final matchesStatus =
            _selectedStatus == 'All' || status == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  // ============================================================
  // ADD TEACHER
  // ============================================================

  Future<void> _showAddTeacherDialog() async {
    await _loadAvailableTeacherUsers();

    if (!mounted || _teacherService == null) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AddTeacherDialog(
          teacherService: _teacherService!,
          schoolId: _schoolId,
          availableUsers: _availableTeacherUsers,
          isLoadingAvailableUsers: _isLoadingAvailableUsers,
        );
      },
    );

    if (created == true) {
      await _loadTeachers();
      await _loadAvailableTeacherUsers();

      if (!mounted) return;

      _showMessage('Teacher created successfully.');
    }
  }

  // ============================================================
  // EDIT TEACHER
  // ============================================================

  Future<void> _showEditTeacherDialog(Teacher teacher) async {
    if (_teacherService == null) return;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return EditTeacherDialog(
          teacherService: _teacherService!,
          teacher: teacher,
          schoolId: _schoolId,
        );
      },
    );

    if (updated == true) {
      await _loadTeachers();

      if (!mounted) return;

      _showMessage('Teacher updated successfully.');
    }
  }

  // ============================================================
  // TEACHER DETAILS
  // ============================================================

  Future<void> _showTeacherDetails(Teacher teacher) async {
    if (_assignmentService == null) return;

    if (_classes.isEmpty) {
      await _loadClasses();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return TeacherDetailsDialog(
          teacher: teacher,
          assignmentService: _assignmentService!,
          classes: _classes,
          onAssignClass: () async {
            final assigned = await _showAssignClassDialog(teacher);

            return assigned;
          },
        );
      },
    );
  }

  // ============================================================
  // ASSIGN CLASS
  // ============================================================

  Future<bool> _showAssignClassDialog(Teacher teacher) async {
    if (teacher.id == null || _assignmentService == null) {
      return false;
    }

    if (_classes.isEmpty) {
      await _loadClasses();
    }

    if (!mounted) return false;

    final assigned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AssignClassDialog(
          teacher: teacher,
          classes: _classes,
          assignmentService: _assignmentService!,
          classService: _classService!, // ADD THIS
          isLoadingClasses: _isLoadingClasses,
        );
      },
    );

    if (assigned == true && mounted) {
      _showMessage('Class assigned successfully.');
    }

    return assigned == true;
  }

  // ============================================================
  // DELETE TEACHER
  // ============================================================

  Future<void> _deleteTeacher(Teacher teacher) async {
    if (teacher.id == null || _teacherService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Teacher'),
          content: Text(
            'Are you sure you want to delete '
            '${teacher.name ?? 'this teacher'}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _teacherService!.deleteTeacher(teacher.id!);

      if (!mounted) return;

      _showMessage('Teacher deleted successfully.');

      await _loadTeachers();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ============================================================
  // FILTER DIALOG
  // ============================================================

  Future<void> _showFilterDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return TeacherFilterDialog(selectedStatus: _selectedStatus);
      },
    );

    if (result != null) {
      setState(() {
        _selectedStatus = result;
      });

      _applyFilters();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadTeachers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildSummaryCards(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildToolbar(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildTeacherTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerText(),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _addTeacherButton()),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _addTeacherButton(),
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teachers',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Manage teachers and professional information',
          style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
        ),
      ],
    );
  }

  Widget _addTeacherButton() {
    return ElevatedButton.icon(
      onPressed: _showAddTeacherDialog,
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add Teacher'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    final total = _teachers.length;

    final active = _teachers.where((teacher) {
      return (teacher.status ?? '').toUpperCase() == 'ACTIVE';
    }).length;

    final inactive = _teachers.where((teacher) {
      return (teacher.status ?? '').toUpperCase() == 'INACTIVE';
    }).length;

    final designations = _teachers
        .map((teacher) => teacher.designation?.trim())
        .where((value) => value != null && value!.isNotEmpty)
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _summaryCard(
              width: width,
              title: 'Total Teachers',
              value: '$total',
              icon: Icons.groups_rounded,
            ),
            _summaryCard(
              width: width,
              title: 'Active',
              value: '$active',
              icon: Icons.check_circle_outline,
            ),
            _summaryCard(
              width: width,
              title: 'Inactive',
              value: '$inactive',
              icon: Icons.pause_circle_outline,
            ),
            _summaryCard(
              width: width,
              title: 'Designations',
              value: '$designations',
              icon: Icons.badge_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_outline, color: Color(0xFF2563EB)),
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
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _searchField(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _filterButton()),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 12),
              _filterButton(),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, employee ID, phone, email...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
      ),
    );
  }

  Widget _filterButton() {
    return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      icon: const Icon(Icons.filter_list),
      label: Text(_selectedStatus == 'All' ? 'Filter' : _selectedStatus),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  // ============================================================
  // TEACHER TABLE
  // ============================================================

  Widget _buildTeacherTable() {
    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        decoration: _tableDecoration(),
        child: const CircularProgressIndicator(),
      );
    }

    if (_filteredTeachers.isEmpty) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        decoration: _tableDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No teachers found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term.'
                  : 'Add your first teacher to get started.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _tableDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 68,
          dataRowMaxHeight: 76,
          columnSpacing: 26,
          horizontalMargin: 20,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF344054),
          ),
          columns: const [
            DataColumn(label: Text('Teacher')),
            DataColumn(label: Text('Employee ID')),
            DataColumn(label: Text('Designation')),
            DataColumn(label: Text('Qualification')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: _filteredTeachers.map((teacher) {
            return DataRow(
              cells: [
                DataCell(_teacherCell(teacher)),
                DataCell(Text(teacher.employeeId ?? '-')),
                DataCell(Text(teacher.designation ?? '-')),
                DataCell(Text(teacher.qualification ?? '-')),
                DataCell(Text(teacher.phone ?? '-')),
                DataCell(_statusBadge(teacher.status ?? 'UNKNOWN')),
                DataCell(_actionButtons(teacher)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  BoxDecoration _tableDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7EAF0)),
    );
  }

  // ============================================================
  // TEACHER CELL
  // ============================================================

  Widget _teacherCell(Teacher teacher) {
    final name = teacher.name?.trim().isNotEmpty == true
        ? teacher.name!.trim()
        : 'Unknown Teacher';

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEFF4FF),
            child: Text(
              _initial(name),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusBadge(String status) {
    final normalized = status.toUpperCase();

    final isActive = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF3) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF027A48) : const Color(0xFFB42318),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _actionButtons(Teacher teacher) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showTeacherDetails(teacher);
          },
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () {
            _showEditTeacherDialog(teacher);
          },
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Assign Class',
          onPressed: () {
            _showAssignClassDialog(teacher);
          },
          icon: const Icon(Icons.class_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteTeacher(teacher);
          },
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _initial(String name) {
    final value = name.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value.substring(0, 1).toUpperCase();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
