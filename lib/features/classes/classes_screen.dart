import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/classes/models/class_form_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/class_subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';
import 'class_details_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final int _schoolId = 1;

  final Map<int, List<ClassSubjectModel>> _classSubjectsMap = {};

  ClassService? _classService;
  ClassSubjectService? _classSubjectService;
  SubjectService? _subjectService;

  List<SchoolClass> _classes = [];
  List<SchoolClass> _filteredClasses = [];
  List<SubjectModel> _allSubjects = [];

  bool _isLoading = true;
  bool _subjectsLoading = false;

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

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );

      return;
    }

    _classService = ClassService(token);
    _classSubjectService = ClassSubjectService(token);
    _subjectService = SubjectService(token);

    await _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (_classService == null || _classSubjectService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final classes = await _classService!.getClassesBySchool(_schoolId);

      _classSubjectsMap.clear();

      for (final schoolClass in classes) {
        if (schoolClass.id == null) continue;

        try {
          final subjects = await _classSubjectService!.getClassSubjects(
            schoolClass.id!,
          );

          _classSubjectsMap[schoolClass.id!] = subjects;
        } catch (_) {
          _classSubjectsMap[schoolClass.id!] = [];
        }
      }

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _filteredClasses = List.from(classes);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  void _applySearch(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredClasses = List.from(_classes);
        return;
      }

      _filteredClasses = _classes.where((schoolClass) {
        final name = schoolClass.name?.toLowerCase() ?? '';
        final code = schoolClass.code?.toLowerCase() ?? '';
        final grade = schoolClass.grade?.toLowerCase() ?? '';
        final description = schoolClass.description?.toLowerCase() ?? '';

        return name.contains(query) ||
            code.contains(query) ||
            grade.contains(query) ||
            description.contains(query);
      }).toList();
    });
  }

  Future<void> _loadClassSubjects() async {
    if (_subjectService == null) return;

    setState(() {
      _subjectsLoading = true;
    });

    try {
      final subjects = await _subjectService!.getActiveSubjectsBySchool(
        _schoolId,
      );

      if (!mounted) return;

      setState(() {
        _allSubjects = subjects;
        _subjectsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _subjectsLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load subjects: $e')));
    }
  }

  Future<void> _showManageSubjectsDialog(SchoolClass schoolClass) async {
    if (schoolClass.id == null || _classSubjectService == null) return;

    await _loadClassSubjects();

    if (!mounted) return;

    final assignedSubjects = List<ClassSubjectModel>.from(
      _classSubjectsMap[schoolClass.id!] ?? [],
    );

    final selectedIds = <int>{
      ...assignedSubjects.map((item) => item.subjectId),
    };

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                  maxHeight: 680,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 35,
                        spreadRadius: 2,
                        offset: const Offset(0, 14),
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.06),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.library_books_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Manage Subjects',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${schoolClass.name ?? 'Class'} • Select subjects assigned to this class',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.60),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),

                      // COUNT
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                        child: Row(
                          children: [
                            Text(
                              '${selectedIds.length} subjects selected',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_allSubjects.length} available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // SUBJECT LIST
                      Expanded(
                        child: _subjectsLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _allSubjects.isEmpty
                            ? _emptyDialogState(
                                icon: Icons.menu_book_outlined,
                                title: 'No subjects available',
                                subtitle: 'Create active subjects first.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: _allSubjects.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final subject = _allSubjects[index];

                                  final isSelected = selectedIds.contains(
                                    subject.id,
                                  );

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        setDialogState(() {
                                          if (isSelected) {
                                            selectedIds.remove(subject.id);
                                          } else {
                                            selectedIds.add(subject.id);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.35)
                                                : Theme.of(context).dividerColor
                                                      .withOpacity(0.5),
                                          ),
                                          color: isSelected
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.06)
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (_) {
                                                setDialogState(() {
                                                  if (isSelected) {
                                                    selectedIds.remove(
                                                      subject.id,
                                                    );
                                                  } else {
                                                    selectedIds.add(subject.id);
                                                  }
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.10),
                                              ),
                                              child: Icon(
                                                Icons.menu_book_rounded,
                                                size: 20,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    subject.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    subject.code,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.55),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // ACTIONS
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () async {
                                try {
                                  final oldIds = assignedSubjects
                                      .map((e) => e.subjectId)
                                      .toSet();

                                  final newIds = selectedIds;

                                  final toAdd = newIds.difference(oldIds);
                                  final toRemove = oldIds.difference(newIds);

                                  for (final subjectId in toAdd) {
                                    await _classSubjectService!
                                        .assignSubjectToClass(
                                          schoolClass.id!,
                                          subjectId,
                                        );
                                  }

                                  for (final subjectId in toRemove) {
                                    await _classSubjectService!
                                        .removeSubjectFromClass(
                                          schoolClass.id!,
                                          subjectId,
                                        );
                                  }

                                  final updatedSubjects =
                                      await _classSubjectService!
                                          .getClassSubjects(schoolClass.id!);

                                  if (!mounted) return;

                                  setState(() {
                                    _classSubjectsMap[schoolClass.id!] =
                                        updatedSubjects;
                                  });

                                  Navigator.pop(dialogContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Subjects updated successfully.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update subjects: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyDialogState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClass() async {
    final result = await _showClassDialog();

    if (result == null || _classService == null) return;

    try {
      final createdClass = await _classService!.createClass(
        schoolId: result.classForm.schoolId,
        name: result.classForm.name,
        code: result.classForm.code,
        grade: result.classForm.grade,
        year: result.classForm.year,
        description: result.classForm.description,
      );

      // Assign selected subjects after class creation
      if (result.subjectIds.isNotEmpty &&
          createdClass.id != null &&
          _classSubjectService != null) {
        for (final subjectId in result.subjectIds) {
          await _classSubjectService!.assignSubjectToClass(
            createdClass.id!,
            subjectId,
          );
        }
      }

      await _loadClasses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create class: $e')));
    }
  }

  Future<void> _editClass(SchoolClass schoolClass) async {
    final result = await _showClassDialog(schoolClass: schoolClass);

    if (result == null || _classService == null || schoolClass.id == null) {
      return;
    }

    try {
      // ----------------------------------------------------------
      // UPDATE CLASS DETAILS
      // ----------------------------------------------------------
      await _classService!.updateClass(
        id: schoolClass.id!,
        schoolId: result.classForm.schoolId,
        name: result.classForm.name,
        code: result.classForm.code,
        grade: result.classForm.grade,
        year: result.classForm.year,
        description: result.classForm.description,
      );

      // ----------------------------------------------------------
      // UPDATE CLASS SUBJECTS
      // ----------------------------------------------------------
      if (_classSubjectService != null) {
        final oldSubjects = _classSubjectsMap[schoolClass.id!] ?? [];

        final oldIds = oldSubjects
            .map((e) => e.subjectId)
            .whereType<int>()
            .toSet();

        final newIds = result.subjectIds.toSet();

        final toAdd = newIds.difference(oldIds);
        final toRemove = oldIds.difference(newIds);

        // Add newly selected subjects
        for (final subjectId in toAdd) {
          await _classSubjectService!.assignSubjectToClass(
            schoolClass.id!,
            subjectId,
          );
        }

        // Remove unselected subjects
        for (final subjectId in toRemove) {
          await _classSubjectService!.removeSubjectFromClass(
            schoolClass.id!,
            subjectId,
          );
        }
      }

      // ----------------------------------------------------------
      // REFRESH CLASS LIST
      // ----------------------------------------------------------
      await _loadClasses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update class: $e')));
    }
  }

  Future<_ClassDialogResult?> _showClassDialog({SchoolClass? schoolClass}) {
    return showDialog<_ClassDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _ClassFormDialog(
          schoolId: _schoolId,
          schoolClass: schoolClass,
          subjectService: _subjectService!,
          classSubjects: schoolClass?.id == null
              ? []
              : (_classSubjectsMap[schoolClass!.id!] ?? []),
        );
      },
    );
  }

  void _viewClass(SchoolClass schoolClass) {
    if (schoolClass.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Class ID is missing.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassDetailsScreen(schoolClass: schoolClass),
      ),
    );
  }

  Future<void> _deleteClass(SchoolClass schoolClass) async {
    if (schoolClass.id == null || _classService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Class?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "${schoolClass.name ?? 'this class'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _classService!.deleteClass(schoolClass.id!);

      await _loadClasses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete class: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    final gradeCount = _classes
        .map((e) => e.grade)
        .where((e) => e != null && e!.trim().isNotEmpty)
        .toSet()
        .length;

    final assignedSubjectCount = _classSubjectsMap.values
        .expand((items) => items)
        .map((item) => item.subjectId)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadClasses,
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
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                        child: _buildSummaryCards(
                          currentYear: currentYear,
                          gradeCount: gradeCount,
                          assignedSubjectCount: assignedSubjectCount,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                        child: _buildSearchSection(),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                        child: _buildClassesTable(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 650;

        final titleSection = Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.16),
                    Theme.of(context).colorScheme.primary.withOpacity(0.07),
                  ],
                ),
              ),
              child: Icon(
                Icons.class_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage classes, subjects and academic structure',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final addButton = FilledButton.icon(
          onPressed: _createClass,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Add Class',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleSection, const SizedBox(height: 16), addButton],
          );
        }

        return Row(
          children: [
            Expanded(child: titleSection),
            addButton,
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required int currentYear,
    required int gradeCount,
    required int assignedSubjectCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double cardWidth;

        if (width >= 1200) {
          cardWidth = (width - 48) / 4;
        } else if (width >= 800) {
          cardWidth = (width - 16) / 2;
        } else {
          cardWidth = width;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Total Classes',
                value: '${_classes.length}',
                subtitle: 'Active academic classes',
                icon: Icons.school_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Current Year',
                value: '$currentYear',
                subtitle: 'Academic year',
                icon: Icons.calendar_month_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Grades',
                value: '$gradeCount',
                subtitle: 'Unique grade levels',
                icon: Icons.layers_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Assigned Subjects',
                value: '$assignedSubjectCount',
                subtitle: 'Across all classes',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.045)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.09),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.58),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.black.withOpacity(0.045)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _applySearch,
        decoration: InputDecoration(
          hintText: 'Search by class name, code, grade or description...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchController.clear();
                    _applySearch('');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildClassesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.045)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Directory',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Click a class row to view complete details',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filteredClasses.length} classes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_filteredClasses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(50),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 55,
                    color: Colors.grey.withOpacity(0.45),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No classes found',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Add your first class to get started.'
                        : 'Try a different search term.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 54,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 82,
                columnSpacing: 24,
                horizontalMargin: 20,
                headingTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.60),
                ),
                columns: const [
                  DataColumn(label: Text('CLASS')),
                  DataColumn(label: Text('GRADE')),
                  DataColumn(label: Text('YEAR')),
                  DataColumn(label: Text('SUBJECTS')),
                  DataColumn(label: Text('DESCRIPTION')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: _filteredClasses.map((schoolClass) {
                  final classSubjects = _classSubjectsMap[schoolClass.id] ?? [];

                  return DataRow(
                    onSelectChanged: (_) {
                      _viewClass(schoolClass);
                    },
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.09),
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                size: 21,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolClass.name ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((schoolClass.code ?? '').isNotEmpty)
                                  Text(
                                    schoolClass.code!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.48),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey.withOpacity(0.55),
                            ),
                          ],
                        ),
                      ),
                      DataCell(_infoChip(schoolClass.grade ?? '-')),
                      DataCell(
                        Text(
                          '${schoolClass.year ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        classSubjects.isEmpty
                            ? _mutedChip('No subjects')
                            : Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: [
                                  ...classSubjects
                                      .take(3)
                                      .map(
                                        (subject) =>
                                            _subjectChip(subject.subjectName),
                                      ),
                                  if (classSubjects.length > 3)
                                    _mutedChip('+${classSubjects.length - 3}'),
                                ],
                              ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            schoolClass.description?.isNotEmpty == true
                                ? schoolClass.description!
                                : '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.58),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionButton(
                              tooltip: 'Manage Subjects',
                              icon: Icons.menu_book_rounded,
                              onPressed: () =>
                                  _showManageSubjectsDialog(schoolClass),
                            ),
                            const SizedBox(width: 6),
                            _actionButton(
                              tooltip: 'Edit Class',
                              icon: Icons.edit_rounded,
                              onPressed: () => _editClass(schoolClass),
                            ),
                            const SizedBox(width: 6),
                            _actionButton(
                              tooltip: 'Delete Class',
                              icon: Icons.delete_outline_rounded,
                              isDestructive: true,
                              onPressed: () => _deleteClass(schoolClass),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDestructive
            ? Colors.red.withOpacity(0.07)
            : Theme.of(context).colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              icon,
              size: 18,
              color: isDestructive
                  ? Colors.red.shade600
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _subjectChip(String? text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text ?? '-',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _mutedChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _ClassDialogResult {
  final ClassFormModel classForm;
  final List<int> subjectIds;

  _ClassDialogResult({required this.classForm, required this.subjectIds});
}

class _ClassFormDialog extends StatefulWidget {
  final int schoolId;
  final SchoolClass? schoolClass;
  final SubjectService subjectService;
  final List<ClassSubjectModel> classSubjects;

  const _ClassFormDialog({
    required this.schoolId,
    required this.schoolClass,
    required this.subjectService,
    required this.classSubjects,
  });

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

  List<SubjectModel> _subjects = [];
  final Set<int> _selectedSubjectIds = {};

  bool _subjectsLoading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final schoolClass = widget.schoolClass;

    _nameController = TextEditingController(text: schoolClass?.name ?? '');

    _codeController = TextEditingController(text: schoolClass?.code ?? '');

    _gradeController = TextEditingController(text: schoolClass?.grade ?? '');

    _yearController = TextEditingController(
      text: '${schoolClass?.year ?? DateTime.now().year}',
    );

    _descriptionController = TextEditingController(
      text: schoolClass?.description ?? '',
    );

    _selectedSubjectIds.addAll(
      widget.classSubjects.map((subject) => subject.subjectId),
    );

    _loadSubjects();
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

  Future<void> _loadSubjects() async {
    try {
      final subjects = await widget.subjectService.getActiveSubjectsBySchool(
        widget.schoolId,
      );

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _subjectsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _subjectsLoading = false;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final year = int.tryParse(_yearController.text.trim());

    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid year.')),
      );
      return;
    }

    final classForm = ClassFormModel(
      id: widget.schoolClass?.id ?? 0,
      schoolId: widget.schoolId,
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      grade: _gradeController.text.trim(),
      year: year,
      description: _descriptionController.text.trim(),
      subjectIds: _selectedSubjectIds.toList(),
    );

    Navigator.pop(
      context,
      _ClassDialogResult(
        classForm: classForm,
        subjectIds: _selectedSubjectIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.schoolClass != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 35,
                spreadRadius: 2,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.15),
              ),
            ],
          ),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.06),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.add_business_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Class' : 'Create New Class',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit
                                ? 'Update class information and subjects'
                                : 'Add a new class and assign subjects',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.58),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // FORM
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 560;

                            final nameField = _textField(
                              controller: _nameController,
                              label: 'Class Name',
                              hint: 'Example: 10th Standard',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Class name is required';
                                }
                                return null;
                              },
                            );

                            final codeField = _textField(
                              controller: _codeController,
                              label: 'Class Code',
                              hint: 'Example: CLASS-10-A',
                              icon: Icons.qr_code_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Class code is required';
                                }
                                return null;
                              },
                            );

                            final gradeField = _textField(
                              controller: _gradeController,
                              label: 'Grade',
                              hint: 'Example: 10',
                              icon: Icons.layers_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Grade is required';
                                }
                                return null;
                              },
                            );

                            final yearField = _textField(
                              controller: _yearController,
                              label: 'Academic Year',
                              hint: 'Example: 2026',
                              icon: Icons.calendar_month_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Year is required';
                                }

                                if (int.tryParse(value.trim()) == null) {
                                  return 'Enter a valid year';
                                }

                                return null;
                              },
                            );

                            if (twoColumns) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: nameField),
                                      const SizedBox(width: 14),
                                      Expanded(child: codeField),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(child: gradeField),
                                      const SizedBox(width: 14),
                                      Expanded(child: yearField),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                nameField,
                                const SizedBox(height: 14),
                                codeField,
                                const SizedBox(height: 14),
                                gradeField,
                                const SizedBox(height: 14),
                                yearField,
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        _textField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Optional description about this class',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 26),

                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assign Subjects',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Select subjects taught in this class',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_subjectsLoading)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  '${_selectedSubjectIds.length} selected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (_subjectsLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_subjects.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'No active subjects available.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.55),
                              ),
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < _subjects.length; i++) ...[
                                  _subjectSelectionTile(_subjects[i]),
                                  if (i != _subjects.length - 1)
                                    Divider(
                                      height: 1,
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withOpacity(0.4),
                                    ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ACTIONS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isEdit ? Icons.save_rounded : Icons.add_rounded,
                              size: 18,
                            ),
                      label: Text(isEdit ? 'Save Changes' : 'Create Class'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectSelectionTile(SubjectModel subject) {
    final selected = _selectedSubjectIds.contains(subject.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedSubjectIds.remove(subject.id);
          } else {
            _selectedSubjectIds.add(subject.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) {
                setState(() {
                  if (selected) {
                    _selectedSubjectIds.remove(subject.id);
                  } else {
                    _selectedSubjectIds.add(subject.id);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 19,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subject.code,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.50),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 21,
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      ),
    );
  }
}
