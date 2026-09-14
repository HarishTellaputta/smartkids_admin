import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/homework/models/homework_model.dart';
import 'package:smartkids_admin/features/homework/services/homework_service.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final HomeworkService _service = HomeworkService();

  final TextEditingController searchController = TextEditingController();

  List<HomeworkModel> homeworkList = [];

  bool isLoading = true;
  bool isSaving = false;

  String selectedClass = 'All Classes';
  String selectedSubject = 'All Subjects';
  String selectedStatus = 'All';

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD HOMEWORK
  // ============================================================

  Future<void> _loadHomework() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found.');
      }

      _service.setToken(token);

      final data = await _service.getAllHomework();

      if (!mounted) return;

      setState(() {
        homeworkList = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showError(e.toString());
    }
  }

  // ============================================================
  // FILTERED DATA
  // ============================================================

  List<HomeworkModel> get filteredHomework {
    final query = searchQuery.toLowerCase().trim();

    return homeworkList.where((homework) {
      final matchesSearch =
          query.isEmpty ||
          (homework.title ?? '').toLowerCase().contains(query) ||
          (homework.subject ?? '').toLowerCase().contains(query) ||
          (homework.className ?? '').toLowerCase().contains(query) ||
          (homework.sectionName ?? '').toLowerCase().contains(query) ||
          (homework.assignedByTeacherName ?? '').toLowerCase().contains(query);

      final classDisplay = _classDisplay(homework);

      final matchesClass =
          selectedClass == 'All Classes' || classDisplay == selectedClass;

      final matchesSubject =
          selectedSubject == 'All Subjects' ||
          (homework.subject ?? '') == selectedSubject;

      final matchesStatus =
          selectedStatus == 'All' ||
          _displayStatus(homework.status) == selectedStatus;

      return matchesSearch && matchesClass && matchesSubject && matchesStatus;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get totalHomework => homeworkList.length;

  int get publishedCount {
    return homeworkList
        .where((item) => _displayStatus(item.status) == 'Published')
        .length;
  }

  int get draftCount {
    return homeworkList
        .where((item) => _displayStatus(item.status) == 'Draft')
        .length;
  }

  double get submissionPercentage {
    // HomeworkResponseDto does not contain submission count.
    // Therefore we cannot calculate real submission rate
    // from the current Homework APIs.
    return 0;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _createHomework({
    required int classId,
    int? sectionId,
    required int teacherId,
    required String subject,
    required String title,
    required String description,
    required String dueDate,
    required String status,
    required String priority,
  }) async {
    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found.');
      }

      _service.setToken(token);

      final homework = await _service.createHomework(
        classId: classId,
        sectionId: sectionId,
        teacherId: teacherId,
        subject: subject,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        priority: priority,
      );

      if (!mounted) return;

      setState(() {
        homeworkList.insert(0, homework);
        isSaving = false;
      });

      _showSuccess('Homework created successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showError(e.toString());
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> _updateHomework({
    required int id,
    required int classId,
    int? sectionId,
    required int teacherId,
    required String subject,
    required String title,
    required String description,
    required String dueDate,
    required String status,
    required String priority,
  }) async {
    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found.');
      }

      _service.setToken(token);

      final updated = await _service.updateHomework(
        id: id,
        classId: classId,
        sectionId: sectionId,
        teacherId: teacherId,
        subject: subject,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        priority: priority,
      );

      if (!mounted) return;

      final index = homeworkList.indexWhere((item) => item.id == id);

      if (index != -1) {
        setState(() {
          homeworkList[index] = updated;
        });
      }

      setState(() {
        isSaving = false;
      });

      _showSuccess('Homework updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showError(e.toString());
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteHomework(HomeworkModel homework) async {
    final id = homework.id;

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Homework?'),
          content: Text(
            'Are you sure you want to delete '
            '"${homework.title ?? ''}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found.');
      }

      _service.setToken(token);

      await _service.deleteHomework(id);

      if (!mounted) return;

      setState(() {
        homeworkList.removeWhere((item) => item.id == id);
      });

      _showSuccess('Homework deleted successfully.');
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ============================================================
  // PUBLISH
  // ============================================================

  Future<void> _publishHomework(HomeworkModel homework) async {
    if (homework.id == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('JWT token not found.');
      }

      _service.setToken(token);

      final updated = await _service.updateHomework(
        id: homework.id!,
        classId: homework.classId!,
        sectionId: homework.sectionId,
        teacherId: homework.assignedByTeacherId!,
        subject: homework.subject ?? '',
        title: homework.title ?? '',
        description: homework.description ?? '',
        dueDate: homework.dueDate!,
        status: 'ACTIVE',
        priority: homework.priority ?? 'MEDIUM',
      );

      if (!mounted) return;

      final index = homeworkList.indexWhere((item) => item.id == homework.id);

      if (index != -1) {
        setState(() {
          homeworkList[index] = updated;
        });
      }

      _showSuccess('Homework published successfully.');
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ============================================================
  // CREATE DIALOG
  // ============================================================

  void _showAddHomeworkDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    int? classId;
    int? sectionId;
    int? teacherId;

    String subject = 'Mathematics';
    String dueDate = _todayPlusOne();
    String status = 'ACTIVE';
    String priority = 'MEDIUM';

    // Temporary dropdown data until your actual Class,
    // Section and Teacher API response is connected.
    final classOptions = <Map<String, dynamic>>[
      {'id': 1, 'name': 'Class 1'},
      {'id': 2, 'name': 'Class 2'},
      {'id': 3, 'name': 'Class 3'},
      {'id': 4, 'name': 'Class 4'},
      {'id': 5, 'name': 'Class 5'},
    ];

    final teacherOptions = <Map<String, dynamic>>[
      {'id': 10, 'name': 'Teacher 10'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create Homework',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogTextField(
                        controller: titleController,
                        label: 'Homework Title',
                        hint: 'Enter homework title',
                      ),

                      const SizedBox(height: 14),

                      _dialogTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Enter homework instructions',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        value: classId,
                        decoration: _dialogDecoration('Class'),
                        items: classOptions.map((item) {
                          return DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            classId = value;
                            sectionId = null;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        value: sectionId,
                        decoration: _dialogDecoration('Section (Optional)'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('A')),
                          DropdownMenuItem(value: 2, child: Text('B')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            sectionId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        value: teacherId,
                        decoration: _dialogDecoration('Teacher'),
                        items: teacherOptions.map((item) {
                          return DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            teacherId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: subject,
                        decoration: _dialogDecoration('Subject'),
                        items:
                            const [
                              'Mathematics',
                              'English',
                              'Science',
                              'Telugu',
                              'Social Studies',
                            ].map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              subject = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: dueDate),
                        decoration: _dialogDecoration('Due Date').copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              dueDate =
                                  '${picked.year}-'
                                  '${picked.month.toString().padLeft(2, '0')}-'
                                  '${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: _dialogDecoration('Priority'),
                        items: const ['LOW', 'MEDIUM', 'HIGH'].map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              priority = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: _dialogDecoration('Status'),
                        items: const ['ACTIVE', 'DRAFT', 'CLOSED'].map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              status = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            _showError('Homework title is required.');
                            return;
                          }

                          if (classId == null) {
                            _showError('Please select a class.');
                            return;
                          }

                          if (teacherId == null) {
                            _showError('Please select a teacher.');
                            return;
                          }

                          Navigator.pop(dialogContext);

                          await _createHomework(
                            classId: classId!,
                            sectionId: sectionId,
                            teacherId: teacherId!,
                            subject: subject,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            dueDate: dueDate,
                            status: status,
                            priority: priority,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Homework'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Future<void> _showHomeworkDetails(HomeworkModel homework) async {
    HomeworkModel details = homework;

    if (homework.id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();

        final token = prefs.getString('jwt_token');

        if (token != null && token.isNotEmpty) {
          _service.setToken(token);

          details = await _service.getHomeworkById(homework.id!);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            details.title ?? 'Homework',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Class', _classDisplay(details)),
                  _detailRow('Subject', details.subject ?? '-'),
                  _detailRow('Teacher', details.assignedByTeacherName ?? '-'),
                  _detailRow('Employee ID', details.teacherEmployeeId ?? '-'),
                  _detailRow('Assigned Date', _formatDate(details.createdAt)),
                  _detailRow('Due Date', _formatDate(details.dueDate)),
                  _detailRow('Priority', details.priority ?? '-'),
                  _detailRow('Status', _displayStatus(details.status)),
                  if ((details.description ?? '').isNotEmpty)
                    _detailRow('Description', details.description!),
                  if ((details.attachmentUrl ?? '').isNotEmpty)
                    _detailRow('Attachment', details.attachmentUrl!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadHomework,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildHomeworkTable(),
            ],
          ),
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
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_headerText(), const SizedBox(height: 16), _addButton()],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _addButton(),
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Homework',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Create, publish and manage student homework.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _addButton() {
    return ElevatedButton.icon(
      onPressed: _showAddHomeworkDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Create Homework'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 750) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _classDropdown(),
                const SizedBox(height: 12),
                _subjectDropdown(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: _searchBox()),
              const SizedBox(width: 12),
              Expanded(child: _classDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _subjectDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _statusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search homework...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 19),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _classDropdown() {
    final classes = <String>{'All Classes'};

    for (final item in homeworkList) {
      final value = _classDisplay(item);

      if (value != '-') {
        classes.add(value);
      }
    }

    if (!classes.contains(selectedClass)) {
      selectedClass = 'All Classes';
    }

    return _dropdownContainer(
      value: selectedClass,
      items: classes.toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value ?? 'All Classes';
        });
      },
    );
  }

  Widget _subjectDropdown() {
    final subjects = <String>{'All Subjects'};

    for (final item in homeworkList) {
      if ((item.subject ?? '').trim().isNotEmpty) {
        subjects.add(item.subject!.trim());
      }
    }

    if (!subjects.contains(selectedSubject)) {
      selectedSubject = 'All Subjects';
    }

    return _dropdownContainer(
      value: selectedSubject,
      items: subjects.toList(),
      onChanged: (value) {
        setState(() {
          selectedSubject = value ?? 'All Subjects';
        });
      },
    );
  }

  Widget _statusDropdown() {
    return _dropdownContainer(
      value: selectedStatus,
      items: const ['All', 'Published', 'Draft', 'Closed'],
      onChanged: (value) {
        setState(() {
          selectedStatus = value ?? 'All';
        });
      },
    );
  }

  Widget _dropdownContainer({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 19),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 1000) {
          columns = 2;
        }

        if (constraints.maxWidth < 600) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4 : 2.4,
          children: [
            _summaryCard(
              'Total Homework',
              '$totalHomework',
              Icons.menu_book_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Published',
              '$publishedCount',
              Icons.publish_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Drafts',
              '$draftCount',
              Icons.edit_note_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Submission Rate',
              'N/A',
              Icons.bar_chart_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildHomeworkTable() {
    final data = filteredHomework;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Homework List',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} records',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data.isEmpty)
            _emptyState()
          else
            _table(data),
        ],
      ),
    );
  }

  Widget _table(List<HomeworkModel> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 10,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Homework')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Due Date')),
          DataColumn(label: Text('Teacher')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((homework) {
          return DataRow(
            cells: [
              DataCell(_homeworkCell(homework)),
              DataCell(
                Text(
                  _classDisplay(homework),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(_subjectBadge(homework.subject ?? '-')),
              DataCell(
                Text(
                  _formatDate(homework.dueDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  homework.assignedByTeacherName ?? '-',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(_priorityBadge(homework.priority)),
              DataCell(_statusBadge(homework.status)),
              DataCell(_actionButtons(homework)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _homeworkCell(HomeworkModel homework) {
    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework.title ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  homework.assignedByTeacherName ?? '-',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectBadge(String subject) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _priorityBadge(String? priority) {
    final value = priority ?? '-';

    Color color;
    Color background;

    switch (value.toUpperCase()) {
      case 'HIGH':
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE2E2);
        break;

      case 'MEDIUM':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'LOW':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      default:
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final display = _displayStatus(status);

    Color color;
    Color background;

    switch (display) {
      case 'Published':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      case 'Draft':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'Closed':
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
        break;

      default:
        color = const Color(0xFF2563EB);
        background = const Color(0xFFEFF6FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButtons(HomeworkModel homework) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showHomeworkDetails(homework);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),

        if ((homework.status ?? '').toUpperCase() == 'DRAFT')
          IconButton(
            tooltip: 'Publish',
            onPressed: () {
              _publishHomework(homework);
            },
            icon: const Icon(
              Icons.publish_outlined,
              size: 18,
              color: Color(0xFF15803D),
            ),
          ),

        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteHomework(homework);
          },
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _classDisplay(HomeworkModel item) {
    final className = item.className?.trim() ?? '';

    final section = item.sectionName?.trim() ?? '';

    if (className.isEmpty && section.isEmpty) {
      return '-';
    }

    if (section.isEmpty) {
      return className;
    }

    return '$className - $section';
  }

  String _displayStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ACTIVE':
        return 'Published';

      case 'DRAFT':
        return 'Draft';

      case 'CLOSED':
        return 'Closed';

      default:
        return status ?? '-';
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _todayPlusOne() {
    final date = DateTime.now().add(const Duration(days: 1));

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 50, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No homework found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your filters or create new homework.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SNACKBARS
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }
}
