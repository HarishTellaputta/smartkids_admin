import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/mcq/models/mcq_test_model.dart';
import 'package:smartkids_admin/features/mcq/services/mcq_test_service.dart';
import 'package:smartkids_admin/features/mcq/mcq_question_manager_screen.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';

import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';

class McqScreen extends StatefulWidget {
  const McqScreen({super.key});

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  ClassService? _classService;
  SectionService? _sectionService;
  SubjectService? _subjectService;
  McqTestService? _testService;

  // ============================================================
  // DATA
  // ============================================================

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<SubjectModel> _subjects = [];
  List<McqTestModel> _tests = [];

  // ============================================================
  // FILTERS
  // ============================================================

  SchoolClass? _selectedClass;
  Section? _selectedSection;
  SubjectModel? _selectedSubject;

  DateTime? _selectedDate;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _loadingTests = false;
  bool _creatingTest = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      _classService = ClassService(token);
      _sectionService = SectionService(token);
      _subjectService = SubjectService(token);
      _testService = McqTestService(token);

      await Future.wait([_loadClasses(), _loadSubjects()]);

      await _loadTests();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingTests = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> _loadClasses() async {
    final service = _classService;

    if (service == null) return;

    final classes = await service.getClasses();

    if (!mounted) return;

    setState(() {
      _classes = classes;
    });
  }

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> _loadSubjects() async {
    final service = _subjectService;

    if (service == null) return;

    final subjects = await service.getAllSubjects();

    if (!mounted) return;

    setState(() {
      _subjects = subjects;
    });
  }

  // ============================================================
  // LOAD SECTIONS
  // ============================================================

  Future<void> _loadSections(int classId) async {
    final service = _sectionService;

    if (service == null) return;

    try {
      final sections = await service.getSectionsByClassId(classId);

      if (!mounted) return;

      setState(() {
        _sections = sections;
        _selectedSection = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sections = [];
        _selectedSection = null;
      });

      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // LOAD TESTS
  // ============================================================

  Future<void> _loadTests() async {
    final service = _testService;

    if (service == null) return;

    if (mounted) {
      setState(() {
        _loadingTests = true;
        _errorMessage = null;
      });
    }

    try {
      final tests = await service.getTests();

      if (!mounted) return;

      setState(() {
        _tests = tests;
        _loadingTests = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTests = false;
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadTests();
  }

  // ============================================================
  // CLASS CHANGE
  // ============================================================

  Future<void> _onClassChanged(SchoolClass? value) async {
    setState(() {
      _selectedClass = value;
      _selectedSection = null;
      _sections = [];
    });

    final classId = value?.id;

    if (classId != null) {
      await _loadSections(classId);
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  Future<void> _clearFilters() async {
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
      _selectedSubject = null;
      _selectedDate = null;
      _sections = [];
    });
  }

  // ============================================================
  // FILTERED TESTS
  // ============================================================

  List<McqTestModel> get _filteredTests {
    final result = _tests.where((test) {
      // ----------------------------------------------------------
      // CLASS
      // ----------------------------------------------------------

      if (_selectedClass?.id != null && test.classId != _selectedClass!.id) {
        return false;
      }

      // ----------------------------------------------------------
      // SECTION
      // ----------------------------------------------------------

      if (_selectedSection?.id != null &&
          test.sectionId != _selectedSection!.id) {
        return false;
      }

      // ----------------------------------------------------------
      // SUBJECT
      // ----------------------------------------------------------

      if (_selectedSubject != null) {
        final selectedSubjectName = _selectedSubject!.name.trim().toLowerCase();

        final testSubject = test.subject.trim().toLowerCase();

        if (selectedSubjectName != testSubject) {
          return false;
        }
      }

      // ----------------------------------------------------------
      // DATE
      // ----------------------------------------------------------

      if (_selectedDate != null) {
        final selectedDateString = _formatDate(_selectedDate!);

        if (test.date.trim() != selectedDateString) {
          return false;
        }
      }

      return true;
    }).toList();

    // Newest date/time first
    result.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return b.startTime.compareTo(a.startTime);
    });

    return result;
  }

  // ============================================================
  // SUMMARY COUNTS
  // ============================================================

  int get _scheduledCount {
    return _tests
        .where((test) => test.status.toUpperCase() == 'SCHEDULED')
        .length;
  }

  int get _completedCount {
    return _tests
        .where((test) => test.status.toUpperCase() == 'COMPLETED')
        .length;
  }

  int get _cancelledCount {
    return _tests
        .where((test) => test.status.toUpperCase() == 'CANCELLED')
        .length;
  }

  // ============================================================
  // CREATE TEST
  // ============================================================

  Future<void> _showCreateTestDialog() async {
    if (_classes.isEmpty) {
      _showError('No classes available.');
      return;
    }

    if (_subjects.isEmpty) {
      _showError('No subjects available.');
      return;
    }

    SchoolClass? dialogClass = _selectedClass;
    Section? dialogSection = _selectedSection;
    SubjectModel? dialogSubject = _selectedSubject;

    DateTime testDate = _selectedDate ?? DateTime.now();

    TimeOfDay startTime = TimeOfDay.now();

    final durationController = TextEditingController(text: '30');

    final numberOfQuestionsController = TextEditingController(text: '10');

    final formKey = GlobalKey<FormState>();

    List<Section> dialogSections = [];

    // ----------------------------------------------------------
    // Load initial sections
    // ----------------------------------------------------------

    if (dialogClass?.id != null) {
      try {
        dialogSections = await _sectionService!.getSectionsByClassId(
          dialogClass!.id!,
        );
      } catch (_) {
        dialogSections = [];
      }
    }

    if (!mounted) {
      durationController.dispose();
      numberOfQuestionsController.dispose();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ==================================================
            // CHOOSE CLASS
            // ==================================================

            Future<void> chooseClass(SchoolClass? value) async {
              setDialogState(() {
                dialogClass = value;
                dialogSection = null;
                dialogSections = [];
              });

              final classId = value?.id;

              if (classId == null) return;

              try {
                final sections = await _sectionService!.getSectionsByClassId(
                  classId,
                );

                if (!context.mounted) return;

                setDialogState(() {
                  dialogSections = sections;
                });
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
              }
            }

            // ==================================================
            // CHOOSE DATE
            // ==================================================

            Future<void> chooseDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: testDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );

              if (picked == null) return;

              setDialogState(() {
                testDate = picked;
              });
            }

            // ==================================================
            // CHOOSE TIME
            // ==================================================

            Future<void> chooseTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
              );

              if (picked == null) return;

              setDialogState(() {
                startTime = picked;
              });
            }

            // ==================================================
            // CREATE
            // ==================================================

            Future<void> createTest() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              if (dialogClass?.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a class.')),
                );
                return;
              }

              if (dialogSubject == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a subject.')),
                );
                return;
              }

              final duration = int.tryParse(durationController.text.trim());

              final numberOfQuestions = int.tryParse(
                numberOfQuestionsController.text.trim(),
              );

              if (duration == null || duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Duration must be greater than 0.'),
                  ),
                );
                return;
              }

              if (duration > 300) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Duration cannot exceed 300 minutes.'),
                  ),
                );
                return;
              }

              if (numberOfQuestions == null || numberOfQuestions <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Number of questions must be greater than 0.',
                    ),
                  ),
                );
                return;
              }

              if (numberOfQuestions > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 100 questions are allowed.'),
                  ),
                );
                return;
              }

              // ------------------------------------------------
              // Don't allow past date
              // ------------------------------------------------

              final today = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );

              final selectedDay = DateTime(
                testDate.year,
                testDate.month,
                testDate.day,
              );

              if (selectedDay.isBefore(today)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test date cannot be in the past.'),
                  ),
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final created = await _testService!.createTest(
                  classId: dialogClass!.id!,
                  sectionId: dialogSection?.id,
                  subject: dialogSubject!.name,
                  date: _formatDate(testDate),
                  startTime: _formatTime(startTime),
                  duration: duration,
                  numberOfQuestions: numberOfQuestions,
                );

                if (!context.mounted) return;

                Navigator.of(dialogContext).pop();

                _showSuccess('MCQ test created successfully.');

                _showCreatedTest(created);

                await _loadTests();
              } catch (e) {
                if (!context.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(_cleanError(e)),
                  ),
                );
              }
            }

            // ==================================================
            // DIALOG
            // ==================================================

            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Create Daily MCQ Test')),
                ],
              ),

              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================================
                        // CLASS
                        // ==================================================
                        DropdownButtonFormField<SchoolClass>(
                          value: dialogClass,
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            prefixIcon: Icon(Icons.class_),
                            border: OutlineInputBorder(),
                          ),
                          items: _classes.map((item) {
                            return DropdownMenuItem<SchoolClass>(
                              value: item,
                              child: Text(item.name ?? ''),
                            );
                          }).toList(),
                          onChanged: saving ? null : chooseClass,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select class';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // SECTION
                        // ==================================================
                        DropdownButtonFormField<Section>(
                          value: dialogSection,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            helperText:
                                'Optional — leave empty for all sections',
                            prefixIcon: Icon(Icons.groups_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<Section>(
                              value: null,
                              child: Text('All Sections'),
                            ),
                            ...dialogSections.map((item) {
                              return DropdownMenuItem<Section>(
                                value: item,
                                child: Text(item.name),
                              );
                            }),
                          ],
                          onChanged: saving || dialogClass == null
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    dialogSection = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // SUBJECT
                        // ==================================================
                        DropdownButtonFormField<SubjectModel>(
                          value: dialogSubject,
                          decoration: const InputDecoration(
                            labelText: 'Subject *',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _subjects.map((item) {
                            return DropdownMenuItem<SubjectModel>(
                              value: item,
                              child: Text(
                                item.code.trim().isEmpty
                                    ? item.name
                                    : '${item.name} (${item.code})',
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    dialogSubject = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select subject';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DATE
                        // ==================================================
                        InkWell(
                          onTap: saving ? null : chooseDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Test Date *',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(_formatDate(testDate))),
                                const Icon(Icons.edit_calendar_outlined),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // START TIME
                        // ==================================================
                        InkWell(
                          onTap: saving ? null : chooseTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time *',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(startTime.format(context)),
                                ),
                                const Icon(Icons.schedule),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DURATION + QUESTIONS
                        // ==================================================
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 500) {
                              return Column(
                                children: [
                                  _buildNumberField(
                                    controller: durationController,
                                    label: 'Duration (minutes) *',
                                    icon: Icons.timer_outlined,
                                    suffix: 'min',
                                    enabled: !saving,
                                    validator: (value) {
                                      final number = int.tryParse(
                                        value?.trim() ?? '',
                                      );

                                      if (number == null || number <= 0) {
                                        return 'Enter valid duration';
                                      }

                                      if (number > 300) {
                                        return 'Max 300 minutes';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildNumberField(
                                    controller: numberOfQuestionsController,
                                    label: 'Number of Questions *',
                                    icon: Icons.help_outline,
                                    enabled: !saving,
                                    validator: (value) {
                                      final number = int.tryParse(
                                        value?.trim() ?? '',
                                      );

                                      if (number == null || number <= 0) {
                                        return 'Enter valid number';
                                      }

                                      if (number > 100) {
                                        return 'Max 100 questions';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    controller: durationController,
                                    label: 'Duration (minutes) *',
                                    icon: Icons.timer_outlined,
                                    suffix: 'min',
                                    enabled: !saving,
                                    validator: (value) {
                                      final number = int.tryParse(
                                        value?.trim() ?? '',
                                      );

                                      if (number == null || number <= 0) {
                                        return 'Enter valid duration';
                                      }

                                      if (number > 300) {
                                        return 'Max 300 minutes';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumberField(
                                    controller: numberOfQuestionsController,
                                    label: 'Number of Questions *',
                                    icon: Icons.help_outline,
                                    enabled: !saving,
                                    validator: (value) {
                                      final number = int.tryParse(
                                        value?.trim() ?? '',
                                      );

                                      if (number == null || number <= 0) {
                                        return 'Enter valid number';
                                      }

                                      if (number > 100) {
                                        return 'Max 100 questions';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // INFO
                        // ==================================================
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Questions must already exist for the selected class, subject and date. The system will automatically select the required number of questions.',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: saving ? null : createTest,
                  icon: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(saving ? 'Creating...' : 'Create Test'),
                ),
              ],
            );
          },
        );
      },
    );

    durationController.dispose();
    numberOfQuestionsController.dispose();
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required String? Function(String?) validator,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  // ============================================================
  // CREATED TEST DETAILS
  // ============================================================

  void _showCreatedTest(McqTestModel test) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              const Expanded(child: Text('Test Created')),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Class',
                    test.className ?? _getClassName(test.classId),
                  ),
                  _detailRow('Section', test.sectionName ?? 'All Sections'),
                  _detailRow('Subject', test.subject),
                  _detailRow('Date', test.date),
                  _detailRow('Start Time', test.startTime),
                  _detailRow('Duration', '${test.duration} minutes'),
                  _detailRow('Questions', '${test.numberOfQuestions}'),
                  _detailRow('Status', test.status),

                  const SizedBox(height: 18),

                  const Text(
                    'Questions Included',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),

                  const SizedBox(height: 10),

                  if (test.questions.isEmpty)
                    const Text('No questions returned.')
                  else
                    ...test.questions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Text(
                          '${entry.key + 1}. ${entry.value.question}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TEST DETAILS
  // ============================================================

  void _showTestDetails(McqTestModel test) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.quiz_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text('${test.subject} MCQ Test')),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailHeader(test),

                  const SizedBox(height: 20),

                  const Text(
                    'Question Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),

                  const SizedBox(height: 10),

                  if (test.questions.isEmpty)
                    _buildNoQuestions()
                  else
                    ...test.questions.asMap().entries.map(
                      (entry) =>
                          _buildQuestionPreview(entry.key + 1, entry.value),
                    ),
                ],
              ),
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

  // ============================================================
  // DETAIL HEADER
  // ============================================================

  Widget _buildDetailHeader(McqTestModel test) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _detailRow('Class', test.className ?? _getClassName(test.classId)),
          _detailRow('Section', test.sectionName ?? 'All Sections'),
          _detailRow('Subject', test.subject),
          _detailRow('Date', test.date),
          _detailRow('Start Time', test.startTime),
          _detailRow('Duration', '${test.duration} minutes'),
          _detailRow('Questions', '${test.numberOfQuestions}'),
          _detailRow('Status', test.status),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION PREVIEW
  // ============================================================

  Widget _buildQuestionPreview(int number, McqTestQuestionModel question) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _optionRow('A', question.optionA),
          _optionRow('B', question.optionB),
          _optionRow('C', question.optionC),
          _optionRow('D', question.optionD),

          const SizedBox(height: 7),

          Text(
            '${question.marks} mark${question.marks == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPTION ROW
  // ============================================================

  Widget _optionRow(String letter, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$letter.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }

  // ============================================================
  // NO QUESTIONS
  // ============================================================

  Widget _buildNoQuestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.help_outline, size: 45, color: Colors.grey),
          SizedBox(height: 10),
          Text('No questions available.'),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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

  // ============================================================
  // TEST CARD
  // ============================================================

  Widget _buildTestCard(McqTestModel test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showTestDetails(test);
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // TOP
              // --------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          test.className ?? _getClassName(test.classId),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  _buildStatusChip(test.status),
                ],
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // INFO
              // --------------------------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.class_outlined,
                    test.className ?? _getClassName(test.classId),
                  ),
                  _buildInfoChip(
                    Icons.groups_outlined,
                    test.sectionName ?? 'All Sections',
                  ),
                  _buildInfoChip(Icons.calendar_today_outlined, test.date),
                  _buildInfoChip(Icons.access_time_outlined, test.startTime),
                  _buildInfoChip(Icons.timer_outlined, '${test.duration} min'),
                  _buildInfoChip(
                    Icons.help_outline,
                    '${test.numberOfQuestions} Questions',
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Divider(color: Colors.grey.shade200),

              const SizedBox(height: 2),

              // --------------------------------------------------
              // ACTION
              // --------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showTestDetails(test);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    label: const Text('View Questions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(String status) {
    final text = status.isEmpty ? 'UNKNOWN' : status.toUpperCase();

    Color color;

    switch (text) {
      case 'SCHEDULED':
        color = Colors.orange;
        break;

      case 'COMPLETED':
        color = Colors.green;
        break;

      case 'CANCELLED':
        color = Colors.red;
        break;

      default:
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _buildFilters() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.filter_alt_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Filter Tests',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear all'),
                  ),
              ],
            ),

            const SizedBox(height: 17),

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width >= 1100) {
                  return Row(
                    children: [
                      Expanded(child: _buildClassDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSectionDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSubjectDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateSelector()),
                    ],
                  );
                }

                if (width >= 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildClassDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSectionDropdown()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSubjectDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDateSelector()),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildClassDropdown(),
                    const SizedBox(height: 12),
                    _buildSectionDropdown(),
                    const SizedBox(height: 12),
                    _buildSubjectDropdown(),
                    const SizedBox(height: 12),
                    _buildDateSelector(),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            if (_hasActiveFilters)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredTests.length} test${_filteredTests.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVE FILTERS
  // ============================================================

  bool get _hasActiveFilters {
    return _selectedClass != null ||
        _selectedSection != null ||
        _selectedSubject != null ||
        _selectedDate != null;
  }

  // ============================================================
  // CLASS DROPDOWN
  // ============================================================

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<SchoolClass>(
      value: _selectedClass,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class',
        prefixIcon: Icon(Icons.class_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<SchoolClass>(
          value: null,
          child: Text('All Classes'),
        ),
        ..._classes.map((item) {
          return DropdownMenuItem<SchoolClass>(
            value: item,
            child: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: _onClassChanged,
    );
  }

  // ============================================================
  // SECTION DROPDOWN
  // ============================================================

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<Section>(
      value: _selectedSection,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Section',
        prefixIcon: const Icon(Icons.groups_outlined),
        border: const OutlineInputBorder(),
       // helperText: _selectedClass == null ? 'Select class first' : null,
      ),
      items: [
        const DropdownMenuItem<Section>(
          value: null,
          child: Text('All Sections'),
        ),
        ..._sections.map((item) {
          return DropdownMenuItem<Section>(
            value: item,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: _selectedClass == null
          ? null
          : (value) {
              setState(() {
                _selectedSection = value;
              });
            },
    );
  }

  // ============================================================
  // SUBJECT DROPDOWN
  // ============================================================

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<SubjectModel>(
      value: _selectedSubject,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subject',
        prefixIcon: Icon(Icons.menu_book_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<SubjectModel>(
          value: null,
          child: Text('All Subjects'),
        ),
        ..._subjects.map((item) {
          return DropdownMenuItem<SubjectModel>(
            value: item,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSubject = value;
        });
      },
    );
  }

  // ============================================================
  // DATE SELECTOR
  // ============================================================

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
          suffixIcon: _selectedDate != null
              ? IconButton(
                  tooltip: 'Clear date',
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
        child: Text(
          _selectedDate == null ? 'All Dates' : _formatDate(_selectedDate!),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY SECTION
  // ============================================================

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildSummaryCard(
            title: 'Total Tests',
            value: '${_tests.length}',
            icon: Icons.quiz_outlined,
          ),
          _buildSummaryCard(
            title: 'Scheduled',
            value: '$_scheduledCount',
            icon: Icons.schedule_outlined,
          ),
          _buildSummaryCard(
            title: 'Completed',
            value: '$_completedCount',
            icon: Icons.check_circle_outline,
          ),
          _buildSummaryCard(
            title: 'Cancelled',
            value: '$_cancelledCount',
            icon: Icons.cancel_outlined,
          ),
        ];

        if (constraints.maxWidth >= 1000) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        if (constraints.maxWidth >= 600) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilters = _hasActiveFilters;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 55),
        child: Column(
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.filter_alt_off : Icons.quiz_outlined,
                size: 42,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              hasFilters ? 'No matching tests' : 'No MCQ tests found',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              hasFilters
                  ? 'Try changing or clearing your filters.'
                  : 'Create a test after adding enough questions for the selected class, subject and date.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),

            const SizedBox(height: 20),

            if (hasFilters)
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: _showCreateTestDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create First Test'),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CLASS NAME
  // ============================================================

  String _getClassName(int classId) {
    for (final item in _classes) {
      if (item.id == classId) {
        return item.name ?? '';
      }
    }

    return 'Class $classId';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredTests = _filteredTests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily MCQ Tests'),
        actions: [
          IconButton(
            tooltip: 'Question Manager',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const McqQuestionManagerScreen(),
                ),
              );

              await _loadTests();
            },
            icon: const Icon(Icons.library_books_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingTests ? null : _refresh,
            icon: _loadingTests
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creatingTest ? null : _showCreateTestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Test'),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ========================================================
            // HEADER
            // ========================================================
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;

                    final title = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily MCQ Tests',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create, schedule and manage daily MCQ tests for students.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );

                    final button = OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const McqQuestionManagerScreen(),
                          ),
                        );

                        await _loadTests();
                      },
                      icon: const Icon(Icons.question_mark_outlined),
                      label: const Text('Question Manager'),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [title, const SizedBox(height: 16), button],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 20),
                        button,
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // SUMMARY
            // ========================================================
            _buildSummarySection(),

            const SizedBox(height: 18),

            // ========================================================
            // FILTERS
            // ========================================================
            _buildFilters(),

            const SizedBox(height: 18),

            // ========================================================
            // ERROR
            // ========================================================
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, height: 1.4),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

            // ========================================================
            // LIST HEADER
            // ========================================================
            if (!_loadingTests && filteredTests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Text(
                      'Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredTests.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ========================================================
            // LOADING
            // ========================================================
            if (_loadingTests)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              )
            // ========================================================
            // EMPTY
            // ========================================================
            else if (filteredTests.isEmpty)
              _buildEmptyState()
            // ========================================================
            // TESTS
            // ========================================================
            else
              ...filteredTests.map(_buildTestCard),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    super.dispose();
  }
}
