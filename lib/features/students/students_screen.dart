import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';
import 'package:smartkids_admin/features/students/student_details_screen.dart';
import 'widgets/student_header.dart';
import 'widgets/student_table.dart';
import 'widgets/student_toolbar.dart';
import 'widgets/student_empty_state.dart';
import 'package:smartkids_admin/features/students/student_import_screen.dart';

import 'dialogs/add_student_dialog.dart';
import 'dialogs/edit_student_dialog.dart';
import 'dialogs/delete_student_dialog.dart';
import 'dialogs/student_filter_dialog.dart';
import 'widgets/student_overview_panel.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late StudentService studentService;
  late ClassService classService;

  List<SchoolClass> classes = [];
  int? selectedClassId;

  bool isClassLoading = false;

  static const int _schoolId = 1;

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
      classService = ClassService(token);

      _serviceInitialized = true;

      await _loadClasses();
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
  // LOAD CLASSES
  // ============================================================
  Future<void> _loadClasses() async {
    if (!_serviceInitialized) return;

    setState(() {
      isClassLoading = true;
    });

    try {
      final result = await classService.getClassesBySchool(_schoolId);

      if (!mounted) return;

      setState(() {
        classes = result;
        isClassLoading = false;
      });

      debugPrint('========== CLASSES LOADED ==========');
      debugPrint('CLASS COUNT: ${classes.length}');
    } catch (e) {
      debugPrint('Load classes error: $e');

      if (!mounted) return;

      setState(() {
        isClassLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load classes: $e'),
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
      // ========================================================
      // SPECIFIC CLASS SELECTED
      // ========================================================

      if (selectedClassId != null) {
        final result = await studentService.getStudentsByClassId(
          selectedClassId!,
        );

        if (!mounted) return;

        setState(() {
          students = result;

          // Class API currently returns List<Student>,
          // so pagination is not required here.
          totalElements = result.length;
          totalPages = result.isEmpty ? 0 : 1;
          currentPage = 0;

          isLoading = false;
        });

        debugPrint('========== CLASS STUDENTS LOADED ==========');
        debugPrint('CLASS ID: $selectedClassId');
        debugPrint('STUDENT COUNT: ${students.length}');

        return;
      }

      // ========================================================
      // ALL CLASSES
      // ========================================================

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

  Future<void> _onClassChanged(int? classId) async {
    setState(() {
      selectedClassId = classId;
      currentPage = 0;
    });

    await _loadStudents();
  }

  // ============================================================
  // CLASS FILTER
  // ============================================================

  Widget _buildClassFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedClassId,
          isExpanded: true,
          hint: const Text('All Classes'),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'All Classes',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            ...classes
                .where((schoolClass) => schoolClass.id != null)
                .map(
                  (schoolClass) => DropdownMenuItem<int?>(
                    value: schoolClass.id,
                    child: Text(
                      schoolClass.name ??
                          schoolClass.code ??
                          'Class ${schoolClass.id}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
          ],
          onChanged: isClassLoading ? null : _onClassChanged,
        ),
      ),
    );
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

  Future<void> _showImportExcel() async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentImportScreen(studentService: studentService),
      ),
    );

    if (imported == true && mounted) {
      await _loadStudents();
    }
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentDetailsScreen(student: student)),
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
            // ======================================================
            // HEADER
            // ======================================================
            StudentHeader(
              onImportExcel: _showImportExcel,
              onAddStudent: _showAddStudentDialog,
            ),
            // ======================================================
            // MAIN CONTENT
            // 20% OVERVIEW | 80% STUDENT LIST
            // ======================================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================================================
                    // LEFT - 20%
                    // ==================================================
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            StudentOverviewPanel(
                              totalStudents: totalElements,
                              activeStudents: activeStudents,
                              inactiveStudents: inactiveStudents,
                              newStudentsThisMonth: newStudentsThisMonth,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ==================================================
                    // RIGHT - 80%
                    // ==================================================
                    Expanded(
                      flex: 8,
                      child: Column(
                        children: [
                          _buildStudentToolbar(),

                          const SizedBox(height: 12),

                          Expanded(child: _buildContent(displayedStudents)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // PAGINATION
            // ======================================================
            if (!isLoading && totalPages > 1) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: Colors.indigo.shade300),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ======================================================
          // CLASS FILTER
          // ======================================================
          SizedBox(width: 155, height: 42, child: _buildClassFilter()),

          const SizedBox(width: 10),

          // ======================================================
          // STATUS FILTER
          // ======================================================
          OutlinedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_alt_outlined, size: 17),
            label: Text(
              _selectedStatus == 'All' ? 'Filter' : _selectedStatus,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(90, 42),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ======================================================
          // REFRESH
          // ======================================================
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadStudents,
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),

          const SizedBox(width: 4),
          // ======================================================
          // IMPORT EXCEL
          // ======================================================
          // OutlinedButton.icon(
          //   onPressed: _showImportExcel,
          //   icon: const Icon(Icons.upload_file_outlined, size: 18),
          //   label: const Text(
          //     'Import Excel',
          //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          //   ),
          //   style: OutlinedButton.styleFrom(
          //     minimumSize: const Size(120, 42),
          //     foregroundColor: Colors.indigo,
          //     side: BorderSide(color: Colors.indigo.shade200),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(9),
          //     ),
          //   ),
          // ),

          // const SizedBox(width: 8),
          // // ======================================================
          // // ADD STUDENT
          // // ======================================================
          // ElevatedButton.icon(
          //   onPressed: _showAddStudentDialog,
          //   icon: const Icon(Icons.add, size: 18),
          //   label: const Text(
          //     'Add Student',
          //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          //   ),
          //   style: ElevatedButton.styleFrom(
          //     minimumSize: const Size(125, 42),
          //     backgroundColor: Theme.of(context).primaryColor,
          //     foregroundColor: Colors.white,
          //     elevation: 0,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(9),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

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
