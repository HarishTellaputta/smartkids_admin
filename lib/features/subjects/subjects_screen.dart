import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';

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
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token not found';
      });
      return;
    }

    _subjectService = SubjectService(token);

    await _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (_subjectService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects =
          await _subjectService!.getSubjectsBySchool(widget.schoolId);

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
    final nameController =
        TextEditingController(text: subject?.name ?? '');

    final codeController =
        TextEditingController(text: subject?.code ?? '');

    final descriptionController =
        TextEditingController(text: subject?.description ?? '');

    String selectedStatus = subject?.status ?? 'ACTIVE';

    final formKey = GlobalKey<FormState>();

    final isEditing = subject != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Subject' : 'Add Subject',
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
                          decoration: const InputDecoration(
                            labelText: 'Subject Name',
                            hintText: 'Example: Mathematics',
                            border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Subject Code',
                            hintText: 'Example: MATH',
                            border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Optional description',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
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
                          content: Text(
                            e.toString(),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Update' : 'Create',
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

  Future<void> _deleteSubject(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: Text(
            'Are you sure you want to delete "${subject.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
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
        const SnackBar(
          content: Text('Subject deleted successfully'),
        ),
      );

      await _loadSubjects();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Subject Master'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadSubjects,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSubjectDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadSubjects,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 70,
              color: Colors.grey,
            ),

            const SizedBox(height: 16),

            const Text(
              'No subjects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create your first subject using the button below.',
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                _showSubjectDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Subjects',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_subjects.length} Subjects',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Card(
              elevation: 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text('ID'),
                      ),
                      DataColumn(
                        label: Text('Subject Name'),
                      ),
                      DataColumn(
                        label: Text('Code'),
                      ),
                      DataColumn(
                        label: Text('Description'),
                      ),
                      DataColumn(
                        label: Text('Status'),
                      ),
                      DataColumn(
                        label: Text('Actions'),
                      ),
                    ],
                    rows: _subjects.map((subject) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              subject.id.toString(),
                            ),
                          ),

                          DataCell(
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(subject.code),
                          ),

                          DataCell(
                            Text(
                              subject.description ?? '-',
                            ),
                          ),

                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: subject.status == 'ACTIVE'
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                              child: Text(
                                subject.status ?? 'ACTIVE',
                                style: TextStyle(
                                  color: subject.status == 'ACTIVE'
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _showSubjectDialog(
                                      subject: subject,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  tooltip: 'Edit',
                                ),

                                IconButton(
                                  onPressed: () {
                                    _deleteSubject(subject);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete',
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
            ),
          ),
        ],
      ),
    );
  }
}