
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';
import '../subjects/subject_details_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final int schoolId;

  const SubjectsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  SubjectService? _subjectService;

  List<SubjectModel> _subjects = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token not found';
      });

      return;
    }

    _subjectService = SubjectService(token);

    await _loadSubjects();
  }

  Future<void> _openSubjectDetails(SubjectModel subject) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectDetailsScreen(
          subject: subject,
        ),
      ),
    );
  }

  Future<void> _loadSubjects() async {
    if (_subjectService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _subjectService!.getSubjectsBySchool(
        widget.schoolId,
      );

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _showSubjectDialog({
    SubjectModel? subject,
  }) async {
    final nameController = TextEditingController(
      text: subject?.name ?? '',
    );

    final codeController = TextEditingController(
      text: subject?.code ?? '',
    );

    final descriptionController = TextEditingController(
      text: subject?.description ?? '',
    );

    String selectedStatus = subject?.status ?? 'ACTIVE';

    final formKey = GlobalKey<FormState>();
    final isEditing = subject != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                8,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_outlined
                          : Icons.menu_book_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Subject' : 'Add Subject',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Subject Name',
                            hintText: 'Example: Mathematics',
                            prefixIcon: const Icon(
                              Icons.menu_book_outlined,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Subject name is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: codeController,
                          decoration: InputDecoration(
                            labelText: 'Subject Code',
                            hintText: 'Example: MATH',
                            prefixIcon: const Icon(
                              Icons.code_outlined,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Subject code is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Optional description',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 42),
                              child: Icon(
                                Icons.description_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(
                              Icons.toggle_on_outlined,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ACTIVE',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'INACTIVE',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              selectedStatus = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                20,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (_subjectService == null) {
                      return;
                    }

                    try {
                      final subjectData = SubjectModel(
                        id: subject?.id ?? 0,
                        schoolId: widget.schoolId,
                        name: nameController.text.trim(),
                        code: codeController.text.trim(),
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                        status: selectedStatus,
                      );

                      if (isEditing) {
                        await _subjectService!.updateSubject(
                          subject!.id,
                          subjectData,
                        );
                      } else {
                        await _subjectService!.createSubject(
                          subjectData,
                        );
                      }

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(
                            isEditing
                                ? 'Subject updated successfully'
                                : 'Subject created successfully',
                          ),
                        ),
                      );

                      await _loadSubjects();
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Text(e.toString()),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isEditing
                        ? Icons.save_outlined
                        : Icons.add,
                  ),
                  label: Text(
                    isEditing ? 'Update Subject' : 'Create Subject',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteSubject(
    SubjectModel subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Subject',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${subject.name}"?',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
              ),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _subjectService!.deleteSubject(subject.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Subject deleted successfully',
          ),
        ),
      );

      await _loadSubjects();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: Colors.blue.shade700,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Subject Master',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _loadSubjects,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSubjectDialog();
        },
        elevation: 3,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Subject',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_subjects.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? 16 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(isMobile),

              const SizedBox(height: 22),

              _buildSummaryCards(isMobile),

              const SizedBox(height: 22),

              _buildSubjectsTable(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subjects',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage subjects, codes and academic status',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subjects',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage subjects, codes and academic status',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountBadge(),
            ],
          );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 19,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '${_subjects.length}',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Subjects',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    final activeCount = _subjects
        .where(
          (s) => (s.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE',
        )
        .length;

    final inactiveCount = _subjects.length - activeCount;

    final cards = [
      _summaryCard(
        title: 'Total Subjects',
        value: '${_subjects.length}',
        icon: Icons.menu_book_outlined,
        iconColor: Colors.blue,
        background: Colors.blue.shade50,
      ),
      _summaryCard(
        title: 'Active',
        value: '$activeCount',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        background: Colors.green.shade50,
      ),
      _summaryCard(
        title: 'Inactive',
        value: '$inactiveCount',
        icon: Icons.pause_circle_outline,
        iconColor: Colors.orange,
        background: Colors.orange.shade50,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTable(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.table_rows_outlined,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Subject List',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF172033),
                    ),
                  ),
                ),
                Text(
                  '${_subjects.length} records',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: isMobile ? 25 : 40,
              headingRowHeight: 52,
              dataRowMinHeight: 66,
              dataRowMaxHeight: 72,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF8FAFD),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'ID',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SUBJECT',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CODE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              rows: _subjects.map(
                (subject) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '#${subject.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      DataCell(
                        InkWell(
                          onTap: () =>
                              _openSubjectDetails(subject),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.menu_book_outlined,
                                    size: 19,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'View details',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        SizedBox(
                          width: isMobile ? 180 : 260,
                          child: Text(
                            subject.description ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        _statusChip(
                          subject.status ?? 'ACTIVE',
                        ),
                      ),

                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionButton(
                              icon: Icons.visibility_outlined,
                              tooltip: 'View Details',
                              color: Colors.blue,
                              onTap: () =>
                                  _openSubjectDetails(subject),
                            ),
                            const SizedBox(width: 6),
                            _actionButton(
                              icon: Icons.edit_outlined,
                              tooltip: 'Edit',
                              color: Colors.indigo,
                              onTap: () {
                                _showSubjectDialog(
                                  subject: subject,
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _actionButton(
                              icon: Icons.delete_outline,
                              tooltip: 'Delete',
                              color: Colors.red,
                              onTap: () {
                                _deleteSubject(subject);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.shade100
              : Colors.red.shade100,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 450,
        ),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 38,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No subjects found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first subject to start managing your academic subjects.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showSubjectDialog();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 450,
        ),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.red.shade100,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 36,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load subjects',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadSubjects,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

