import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/classes/models/class_form_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/class_subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  static const int _schoolId = 1;
  final Map<int, List<ClassSubjectModel>> _classSubjectsMap = {};
  ClassService? _classService;
  ClassSubjectService? _classSubjectService;
  SubjectService? _subjectService;

  List<SubjectModel> _allSubjects = [];
  List<ClassSubjectModel> _classSubjects = [];
  List<SchoolClass> _classes = [];
  List<SchoolClass> _filteredClasses = [];

  bool _subjectsLoading = false;
  bool _isLoading = true;
  String _searchQuery = '';

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
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });

        _showMessage('JWT token not found. Please login again.', isError: true);

        return;
      }

      _classService = ClassService(token);
      _classSubjectService = ClassSubjectService(token);
      _subjectService = SubjectService(token);
      await _loadClasses();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showMessage('Initialization failed: $e', isError: true);
    }
  }

  // ============================================================
  Future<void> _loadClasses() async {
    if (_classService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _classService!.getClassesBySchool(_schoolId);

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }

      final classSubjectService = ClassSubjectService(token);

      final Map<int, List<ClassSubjectModel>> subjectMap = {};

      // Load subjects for each class
      for (final classItem in data) {
        if (classItem.id == null) {
          continue;
        }

        try {
          final subjects = await classSubjectService.getClassSubjects(
            classItem.id!,
          );

          subjectMap[classItem.id!] = subjects;
        } catch (e) {
          // Keep class visible even if subject loading fails
          subjectMap[classItem.id!] = [];
        }
      }

      if (!mounted) return;

      setState(() {
        _classes = data;
        _filteredClasses = List<SchoolClass>.from(data);

        _classSubjectsMap
          ..clear()
          ..addAll(subjectMap);

        _isLoading = false;
      });

      _applySearch();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Failed to load classes: $e', isError: true);
    }
  }

  Future<void> _loadClassSubjects(int classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }

      setState(() {
        _subjectsLoading = true;
      });

      final classSubjectService = ClassSubjectService(token);
      final subjectService = SubjectService(token);

      final results = await Future.wait([
        classSubjectService.getClassSubjects(classId),
        subjectService.getActiveSubjectsBySchool(_schoolId),
      ]);

      setState(() {
        _classSubjects = results[0] as List<ClassSubjectModel>;
        _allSubjects = results[1] as List<SubjectModel>;
        _subjectsLoading = false;
      });
    } catch (e) {
      setState(() {
        _subjectsLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showManageSubjectsDialog(SchoolClass classModel) async {
    if (classModel.id == null) {
      _showMessage('Class ID is missing', isError: true);
      return;
    }

    final classId = classModel.id!;

    await _loadClassSubjects(classId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${classModel.name ?? '-'} - Subjects'),
              content: SizedBox(
                width: 500,
                child: _subjectsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allSubjects.isEmpty
                    ? const Text('No active subjects available.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _allSubjects[index];

                          final isAssigned = _classSubjects.any(
                            (item) => item.subjectId == subject.id,
                          );

                          return CheckboxListTile(
                            value: isAssigned,
                            title: Text(subject.name),
                            subtitle: Text(
                              '${subject.code}'
                              '${subject.description != null ? ' • ${subject.description}' : ''}',
                            ),
                            onChanged: (value) async {
                              try {
                                final prefs =
                                    await SharedPreferences.getInstance();

                                final token = prefs.getString('jwt_token');

                                if (token == null || token.isEmpty) {
                                  throw Exception(
                                    'JWT token not found. Please login again.',
                                  );
                                }

                                final service = ClassSubjectService(token);

                                if (value == true) {
                                  await service.assignSubjectToClass(
                                    classId,
                                    subject.id,
                                  );
                                } else {
                                  await service.removeSubjectFromClass(
                                    classId,
                                    subject.id,
                                  );
                                }

                                final updatedSubjects = await service
                                    .getClassSubjects(classId);

                                setDialogState(() {
                                  _classSubjects = updatedSubjects;
                                });

                                if (mounted) {
                                  setState(() {
                                    _classSubjectsMap[classId] =
                                        updatedSubjects;
                                  });
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value == true
                                            ? '${subject.name} assigned successfully'
                                            : '${subject.name} removed successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  } // ============================================================
  // SEARCH
  // ============================================================

  void _applySearch() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredClasses = List.from(_classes);
        return;
      }

      _filteredClasses = _classes.where((classItem) {
        return (classItem.name ?? '').toLowerCase().contains(query) ||
            (classItem.code ?? '').toLowerCase().contains(query) ||
            (classItem.grade ?? '').toLowerCase().contains(query) ||
            (classItem.description ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  // ============================================================
  // CREATE CLASS
  // ============================================================

  Future<void> _createClass() async {
    if (_classService == null) return;

    final result = await _showClassDialog();

    if (result == null) return;

    try {
      await _classService!.createClass(
        schoolId: _schoolId,
        name: result.name,
        code: result.code,
        grade: result.grade,
        year: result.year,
        description: result.description,
      );

      if (!mounted) return;

      _showMessage('Class created successfully');

      await _loadClasses();
    } catch (e) {
      _showMessage('Failed to create class: $e', isError: true);
    }
  }

  //edit

  Future<void> _editClass(SchoolClass classItem) async {
    if (_classService == null) return;

    if (classItem.id == null) {
      _showMessage('Class ID is missing', isError: true);
      return;
    }

    final result = await _showClassDialog(existingClass: classItem);

    if (result == null) return;

    try {
      await _classService!.updateClass(
        id: classItem.id!,
        schoolId: _schoolId,
        name: result.name,
        code: result.code,
        grade: result.grade,
        year: result.year,
        description: result.description,
      );

      if (!mounted) return;

      _showMessage('Class updated successfully');

      await _loadClasses();
    } catch (e) {
      _showMessage('Failed to update class: $e', isError: true);
    }
  }
  // ============================================================
  // DELETE CLASS
  // ============================================================

  Future<ClassFormModel?> _showClassDialog({SchoolClass? existingClass}) async {
    return showDialog<ClassFormModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _ClassFormDialog(
          existingClass: existingClass,
          schoolId: _schoolId,
        );
      },
    );
  }
  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          'Classes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadClasses,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 20),

            _buildSummaryCards(),

            const SizedBox(height: 20),

            _buildSearchBar(),

            const SizedBox(height: 20),

            Expanded(child: _buildClassesTable()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                'Manage school classes and academic details',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: _createClass,
          icon: const Icon(Icons.add),
          label: const Text('Add Class'),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    final totalClasses = _classes.length;

    final currentYear = _classes.where((item) => item.year == 2026).length;

    final grades = _classes
        .map((item) => item.grade)
        .whereType<String>()
        .where((grade) => grade.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Total Classes',
            value: totalClasses.toString(),
            icon: Icons.school,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: _summaryCard(
            title: 'Academic Year 2026',
            value: currentYear.toString(),
            icon: Icons.calendar_today,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: _summaryCard(
            title: 'Grades',
            value: grades.toString(),
            icon: Icons.grade,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: _summaryCard(
            title: 'School ID',
            value: _schoolId.toString(),
            icon: Icons.business,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue),
            ),

            const SizedBox(width: 14),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        _searchQuery = value;
        _applySearch();
      },
      decoration: InputDecoration(
        hintText: 'Search by class name, code, grade or description...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _applySearch();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================
  Widget _buildClassesTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredClasses.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),

            // ============================================================
            // TABLE HEADERS - 7 COLUMNS
            // ============================================================
            columns: const [
              DataColumn(
                label: Text(
                  'Class',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Code',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Grade',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Year',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Subjects',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],

            // ============================================================
            // TABLE ROWS
            // ============================================================
            rows: _filteredClasses.map((classItem) {
              final classId = classItem.id;

              // Get subjects assigned to this class
              final subjects = classId != null
                  ? (_classSubjectsMap[classId] ?? [])
                  : <ClassSubjectModel>[];
              return DataRow(
                cells: [
                  // ======================================================
                  // 1. CLASS
                  // ======================================================
                  DataCell(
                    Text(
                      classItem.name ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  // ======================================================
                  // 2. CODE
                  // ======================================================
                  DataCell(Text(classItem.code ?? '-')),

                  // ======================================================
                  // 3. GRADE
                  // ======================================================
                  DataCell(Text(classItem.grade ?? '-')),

                  // ======================================================
                  // 4. YEAR
                  // ======================================================
                  DataCell(Text(classItem.year?.toString() ?? '-')),

                  // ======================================================
                  // 5. SUBJECTS
                  // ======================================================
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: subjects.isEmpty
                          ? const Text(
                              'No subjects assigned',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              subjects
                                  .map((subject) => subject.subjectName)
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),

                  // ======================================================
                  // 6. DESCRIPTION
                  // ======================================================
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        classItem.description ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // ======================================================
                  // 7. ACTION
                  // ======================================================
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Manage Subjects
                        IconButton(
                          tooltip: 'Manage Subjects',
                          onPressed: () {
                            _showManageSubjectsDialog(classItem);
                          },
                          icon: const Icon(
                            Icons.menu_book_outlined,
                            color: Colors.blue,
                          ),
                        ),

                        // View
                        IconButton(
                          tooltip: 'View',
                          onPressed: () {
                            _viewClass(classItem);
                          },
                          icon: const Icon(Icons.visibility_outlined),
                        ),

                        // Edit
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () {
                            _editClass(classItem);
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),

                        // Delete
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () {
                            _deleteClass(classItem);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _viewClass(SchoolClass classItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(classItem.name ?? '-'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Class ID', classItem.id?.toString() ?? '-'),
                _detailRow('School ID', classItem.schoolId?.toString() ?? '-'),
                _detailRow('School', classItem.schoolName ?? '-'),
                _detailRow('Class Name', classItem.name ?? '-'),
                _detailRow('Code', classItem.code ?? '-'),
                _detailRow('Grade', classItem.grade ?? '-'),
                _detailRow('Academic Year', classItem.year?.toString() ?? '-'),
                _detailRow('Description', classItem.description ?? '-'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _deleteClass(SchoolClass classItem) async {
    if (_classService == null) {
      return;
    }

    if (classItem.id == null) {
      _showMessage('Class ID is missing', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Class'),
          content: Text(
            'Are you sure you want to delete '
            '"${classItem.name ?? '-'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _classService!.deleteClass(classItem.id!);

      if (!mounted) {
        return;
      }

      _showMessage('Class deleted successfully');

      await _loadClasses();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to delete class: $e', isError: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Classes Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No classes match your search.'
                  : 'No classes have been added yet.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _createClass,
                icon: const Icon(Icons.add),
                label: const Text('Add Class'),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ==========================================================
  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _ClassFormDialog extends StatefulWidget {
  final SchoolClass? existingClass;
  final int schoolId;

  const _ClassFormDialog({required this.existingClass, required this.schoolId});

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _gradeController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.existingClass?.name ?? '',
    );

    _codeController = TextEditingController(
      text: widget.existingClass?.code ?? '',
    );

    _gradeController = TextEditingController(
      text: widget.existingClass?.grade ?? '',
    );

    _yearController = TextEditingController(
      text: widget.existingClass?.year?.toString() ?? '2026',
    );

    _descriptionController = TextEditingController(
      text: widget.existingClass?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _gradeController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final year = int.tryParse(_yearController.text.trim());

    if (year == null) {
      return;
    }

    final result = ClassFormModel(
      id: widget.existingClass?.id ?? 0,
      schoolId: widget.schoolId,
      schoolName: widget.existingClass?.schoolName,
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      grade: _gradeController.text.trim(),
      year: year,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: widget.existingClass?.createdAt,
      updatedAt: widget.existingClass?.updatedAt,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingClass != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Class' : 'Add Class'),

      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ========================================================
                // CLASS NAME
                // ========================================================
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'Example: Class 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter class name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================================
                // CLASS CODE
                // ========================================================
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Class Code',
                    hintText: 'Example: CLS-01',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter class code';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================================
                // GRADE
                // ========================================================
                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    hintText: 'Example: 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter grade';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================================
                // ACADEMIC YEAR
                // ========================================================
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    hintText: 'Example: 2026',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter academic year';
                    }

                    final year = int.tryParse(value.trim());

                    if (year == null) {
                      return 'Please enter a valid year';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================================
                // DESCRIPTION
                // ========================================================
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter class description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
