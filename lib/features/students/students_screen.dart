import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';

import 'widgets/student_header.dart';
import 'widgets/student_summary_cards.dart';
import 'widgets/student_table.dart';
import 'widgets/student_toolbar.dart';
import 'widgets/student_empty_state.dart';

import 'dialogs/add_student_dialog.dart';
import 'dialogs/edit_student_dialog.dart';
import 'dialogs/student_details_dialog.dart';
import 'dialogs/delete_student_dialog.dart';
import 'dialogs/student_filter_dialog.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late StudentService studentService;

  List<Student> students = [];

  bool isLoading = false;

  int currentPage = 0;
  int totalPages = 0;
  int totalElements = 0;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  bool _serviceInitialized = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _initializeStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      debugPrint('========== INITIALIZE STUDENTS ==========');
      debugPrint('TOKEN FROM PREFS: $token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication token not found. Please login again.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      studentService = StudentService(token);

      _serviceInitialized = true;

      await _loadStudents();
    } catch (e) {
      debugPrint('Student initialization error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> _loadStudents() async {
    if (!_serviceInitialized) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await studentService.getStudents(
        page: currentPage,
        size: 10,
        sortBy: 'id',
        sortDirection: 'asc',
      );

      if (!mounted) return;

      setState(() {
        students = response.content;
        totalPages = response.totalPages;
        totalElements = response.totalElements;
        isLoading = false;
      });

      debugPrint('========== STUDENTS LOADED ==========');
      debugPrint('COUNT: ${students.length}');
      debugPrint('TOTAL: $totalElements');
      debugPrint('TOTAL PAGES: $totalPages');
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');
      debugPrint('Response: ${e.response?.data}');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?['message']?.toString() ??
                'Failed to load students',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Load students error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FILTERED STUDENTS
  // ============================================================

  List<Student> get filteredStudents {
    return students.where((student) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (student.name ?? '').toLowerCase().contains(_searchQuery) ||
          (student.admissionNo ?? '').toLowerCase().contains(_searchQuery) ||
          (student.sectionName ?? '').toLowerCase().contains(_searchQuery) ||
          (student.parentName ?? '').toLowerCase().contains(_searchQuery) ||
          (student.phone ?? '').toLowerCase().contains(_searchQuery) ||
          (student.email ?? '').toLowerCase().contains(_searchQuery);

      final matchesStatus =
          _selectedStatus == 'All' ||
          (student.status ?? '').toUpperCase() == _selectedStatus.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get activeStudents {
    return students
        .where((student) => (student.status ?? '').toUpperCase() == 'ACTIVE')
        .length;
  }

  int get inactiveStudents {
    return students
        .where((student) => (student.status ?? '').toUpperCase() == 'INACTIVE')
        .length;
  }

  int get newStudentsThisMonth {
    final now = DateTime.now();

    return students.where((student) {
      final dateString = student.admissionDate;

      if (dateString == null || dateString.isEmpty) {
        return false;
      }

      final date = DateTime.tryParse(dateString);

      if (date == null) {
        return false;
      }

      return date.year == now.year && date.month == now.month;
    }).length;
  }
  // ============================================================
  // ADD STUDENT
  // ============================================================

  void _showAddStudentDialog() {
    if (!_serviceInitialized) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddStudentDialog(
          studentService: studentService,
          onSaved: () async {
            await _loadStudents();
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT STUDENT
  // ============================================================

  void _showEditStudentDialog(Student student) {
    if (!_serviceInitialized) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EditStudentDialog(
          student: student,
          studentService: studentService,
          onSaved: () async {
            await _loadStudents();
          },
        );
      },
    );
  }

  // ============================================================
  // VIEW STUDENT
  // ============================================================

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) {
        return StudentDetailsDialog(student: student);
      },
    );
  }

  // ============================================================
  // DELETE STUDENT
  // ============================================================

  void _showDeleteStudentDialog(Student student) {
    if (!_serviceInitialized) return;

    showDialog(
      context: context,
      builder: (context) {
        return DeleteStudentDialog(
          student: student,
          studentService: studentService,
          onDeleted: () async {
            if (students.length == 1 && currentPage > 0) {
              currentPage--;
            }

            await _loadStudents();
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StudentFilterDialog(
          selectedStatus: _selectedStatus,
          onApply: (status) {
            setState(() {
              _selectedStatus = status;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // PAGE CHANGE
  // ============================================================

  void _goToPage(int page) {
    if (page < 0 || page >= totalPages) return;

    setState(() {
      currentPage = page;
    });

    _loadStudents();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final displayedStudents = filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------
            StudentHeader(onAddStudent: _showAddStudentDialog),

            // ----------------------------------------------------
            // SUMMARY CARDS
            // ----------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: StudentSummaryCards(
                totalStudents: totalElements,
                activeStudents: activeStudents,
                inactiveStudents: inactiveStudents,
                newStudentsThisMonth: newStudentsThisMonth,
              ),
            ),

            // ----------------------------------------------------
            // TOOLBAR
            // ----------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: StudentToolbar(
                searchController: _searchController,
                selectedStatus: _selectedStatus,
                onFilterPressed: _showFilterDialog,
                onRefresh: _loadStudents,
                onAddStudent: _showAddStudentDialog,
              ),
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // TABLE / EMPTY / LOADING
            // ----------------------------------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(displayedStudents),
              ),
            ),

            // ----------------------------------------------------
            // PAGINATION
            // ----------------------------------------------------
            if (!isLoading && totalPages > 1) _buildPagination(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(List<Student> displayedStudents) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (displayedStudents.isEmpty) {
      return StudentEmptyState(
        searchQuery: _searchQuery,
        onAddStudent: _showAddStudentDialog,
        onClearSearch: () {
          _searchController.clear();

          setState(() {
            _selectedStatus = 'All';
          });
        },
      );
    }

    return StudentTable(
      students: displayedStudents,
      onView: _showStudentDetails,
      onEdit: _showEditStudentDialog,
      onDelete: _showDeleteStudentDialog,
    );
  }

  // ============================================================
  // PAGINATION UI
  // ============================================================

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const SizedBox(width: 16),

          IconButton(
            tooltip: 'Previous',
            onPressed: currentPage > 0
                ? () => _goToPage(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          ..._buildPageButtons(),

          IconButton(
            tooltip: 'Next',
            onPressed: currentPage < totalPages - 1
                ? () => _goToPage(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final List<Widget> buttons = [];

    int start = currentPage - 2;
    int end = currentPage + 2;

    if (start < 0) {
      start = 0;
    }

    if (end >= totalPages) {
      end = totalPages - 1;
    }

    for (int i = start; i <= end; i++) {
      final isSelected = i == currentPage;

      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 36,
            height: 36,
            child: TextButton(
              onPressed: () => _goToPage(i),
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('${i + 1}'),
            ),
          ),
        ),
      );
    }

    return buttons;
  }
}
