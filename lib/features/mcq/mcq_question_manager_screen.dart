import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/mcq/models/mcq_question_model.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';

import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';
import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/features/mcq/services/mcq_question_service.dart';
import 'package:smartkids_admin/services/section_service.dart';

class McqQuestionManagerScreen extends StatefulWidget {
  final int? initialClassId;
  final int? initialSectionId;
  final String? initialSubject;
  final DateTime? initialDate;

  const McqQuestionManagerScreen({
    super.key,
    this.initialClassId,
    this.initialSectionId,
    this.initialSubject,
    this.initialDate,
  });

  @override
  State<McqQuestionManagerScreen> createState() =>
      _McqQuestionManagerScreenState();
}

class _McqQuestionManagerScreenState extends State<McqQuestionManagerScreen> {
  ClassService? _classService;
  SectionService? _sectionService;
  SubjectService? _subjectService;
  McqQuestionService? _questionService;

  bool _loading = true;
  bool _loadingQuestions = false;
  bool _importing = false;

  String? _error;

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<SubjectModel> _subjects = [];
  List<McqQuestionModel> _questions = [];

  SchoolClass? _selectedClass;
  Section? _selectedSection;
  SubjectModel? _selectedSubject;

  DateTime _selectedDate = DateTime.now();

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate ?? DateTime.now();

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
        throw Exception('Login token not found. Please login again.');
      }

      _classService = ClassService(token);
      _sectionService = SectionService(token);
      _subjectService = SubjectService(token);
      _questionService = McqQuestionService(token);

      final results = await Future.wait([
        _classService!.getClasses(),
        _subjectService!.getAllSubjects(),
      ]);

      if (!mounted) return;

      _classes = results[0] as List<SchoolClass>;
      _subjects = results[1] as List<SubjectModel>;

      if (widget.initialClassId != null) {
        for (final item in _classes) {
          if (item.id == widget.initialClassId) {
            _selectedClass = item;
            break;
          }
        }

        if (_selectedClass?.id != null) {
          await _loadSections(_selectedClass!.id!);
        }
      }

      if (widget.initialSectionId != null) {
        for (final item in _sections) {
          if (item.id == widget.initialSectionId) {
            _selectedSection = item;
            break;
          }
        }
      }

      if (widget.initialSubject != null &&
          widget.initialSubject!.trim().isNotEmpty) {
        for (final item in _subjects) {
          if (item.name.toLowerCase() ==
              widget.initialSubject!.trim().toLowerCase()) {
            _selectedSubject = item;
            break;
          }
        }
      }

      setState(() {
        _loading = false;
      });

      await _loadQuestions();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD SECTIONS
  // ============================================================

  Future<void> _loadSections(int classId) async {
    try {
      final sections = await _sectionService!.getSectionsByClassId(classId);

      if (!mounted) return;

      setState(() {
        _sections = sections;

        if (_selectedSection != null &&
            !_sections.any((item) => item.id == _selectedSection!.id)) {
          _selectedSection = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sections = [];
        _selectedSection = null;
      });

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD QUESTIONS
  // ============================================================

  Future<void> _loadQuestions() async {
    if (_questionService == null) return;

    setState(() {
      _loadingQuestions = true;
    });

    try {
      List<McqQuestionModel> result;

      if (_selectedClass?.id != null && _selectedSubject != null) {
        result = await _questionService!.getQuestions(
          date: _formatApiDate(_selectedDate),
          classId: _selectedClass!.id!,
          subject: _selectedSubject!.name,
        );
      } else if (_selectedClass?.id != null) {
        result = await _questionService!.getQuestions(
          date: _formatApiDate(_selectedDate),
          classId: _selectedClass!.id!,
        );
      } else if (_selectedSubject != null) {
        result = await _questionService!.getQuestions(
          date: _formatApiDate(_selectedDate),
          subject: _selectedSubject!.name,
        );
      } else {
        result = await _questionService!.getQuestions(
          date: _formatApiDate(_selectedDate),
        );
      }

      if (!mounted) return;

      setState(() {
        _questions = result;
        _loadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _questions = [];
        _loadingQuestions = false;
      });

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ============================================================
  // FILTERED QUESTIONS
  // ============================================================

  List<McqQuestionModel> get _filteredQuestions {
    if (_searchText.trim().isEmpty) {
      return _questions;
    }

    final search = _searchText.toLowerCase().trim();

    return _questions.where((question) {
      return question.question.toLowerCase().contains(search) ||
          question.subject.toLowerCase().contains(search) ||
          question.optionA.toLowerCase().contains(search) ||
          question.optionB.toLowerCase().contains(search) ||
          question.optionC.toLowerCase().contains(search) ||
          question.optionD.toLowerCase().contains(search);
    }).toList();
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String _formatDisplayDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();

    return '$d-$m-$y';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadQuestions();
  }

  // ============================================================
  // ADD QUESTION
  // ============================================================

  Future<void> _showAddQuestionDialog() async {
    await _showQuestionDialog();
  }

  // ============================================================
  // EDIT QUESTION
  // ============================================================

  Future<void> _showEditQuestionDialog(McqQuestionModel question) async {
    await _showQuestionDialog(existingQuestion: question);
  }

  // ============================================================
  // QUESTION DIALOG
  // ============================================================

  Future<void> _showQuestionDialog({McqQuestionModel? existingQuestion}) async {
    if (_classes.isEmpty) {
      _showSnackBar('No classes available.', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();

    SchoolClass? dialogClass = _selectedClass;
    Section? dialogSection = _selectedSection;
    SubjectModel? dialogSubject = _selectedSubject;

    DateTime dialogDate = existingQuestion != null
        ? _parseQuestionDate(existingQuestion.questionDate)
        : _selectedDate;

    final questionController = TextEditingController(
      text: existingQuestion?.question ?? '',
    );

    final optionAController = TextEditingController(
      text: existingQuestion?.optionA ?? '',
    );

    final optionBController = TextEditingController(
      text: existingQuestion?.optionB ?? '',
    );

    final optionCController = TextEditingController(
      text: existingQuestion?.optionC ?? '',
    );

    final optionDController = TextEditingController(
      text: existingQuestion?.optionD ?? '',
    );

    final marksController = TextEditingController(
      text: existingQuestion?.marks.toString() ?? '1',
    );

    final explanationController = TextEditingController(
      text: existingQuestion?.explanation ?? '',
    );

    String correctAnswer = existingQuestion?.correctAnswer.toUpperCase() ?? 'A';

    List<Section> dialogSections = [];

    if (dialogClass?.id != null) {
      try {
        dialogSections = await _sectionService!.getSectionsByClassId(
          dialogClass!.id!,
        );
      } catch (_) {
        dialogSections = [];
      }
    }

    if (dialogSection != null &&
        !dialogSections.any((item) => item.id == dialogSection!.id)) {
      dialogSection = null;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Icon(
                      existingQuestion == null ? Icons.add : Icons.edit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      existingQuestion == null
                          ? 'Add MCQ Question'
                          : 'Edit MCQ Question',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --------------------------------------------------
                        // CLASS / SECTION
                        // --------------------------------------------------
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 560;

                            if (isSmall) {
                              return Column(
                                children: [
                                  _buildClassDropdown(
                                    value: dialogClass,
                                    onChanged: (value) async {
                                      setDialogState(() {
                                        dialogClass = value;
                                        dialogSection = null;
                                        dialogSections = [];
                                      });

                                      if (value?.id != null) {
                                        try {
                                          final sections =
                                              await _sectionService!
                                                  .getSectionsByClassId(
                                                    value!.id!,
                                                  );

                                          setDialogState(() {
                                            dialogSections = sections;
                                          });
                                        } catch (_) {}
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSectionDropdown(
                                    sections: dialogSections,
                                    value: dialogSection,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogSection = value;
                                      });
                                    },
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildClassDropdown(
                                    value: dialogClass,
                                    onChanged: (value) async {
                                      setDialogState(() {
                                        dialogClass = value;
                                        dialogSection = null;
                                        dialogSections = [];
                                      });

                                      if (value?.id != null) {
                                        try {
                                          final sections =
                                              await _sectionService!
                                                  .getSectionsByClassId(
                                                    value!.id!,
                                                  );

                                          setDialogState(() {
                                            dialogSections = sections;
                                          });
                                        } catch (_) {}
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSectionDropdown(
                                    sections: dialogSections,
                                    value: dialogSection,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogSection = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // --------------------------------------------------
                        // SUBJECT / DATE
                        // --------------------------------------------------
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 560;

                            if (isSmall) {
                              return Column(
                                children: [
                                  _buildSubjectDropdown(
                                    value: dialogSubject,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogSubject = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDateField(
                                    date: dialogDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: dialogDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );

                                      if (picked != null) {
                                        setDialogState(() {
                                          dialogDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildSubjectDropdown(
                                    value: dialogSubject,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogSubject = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    date: dialogDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: dialogDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );

                                      if (picked != null) {
                                        setDialogState(() {
                                          dialogDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // QUESTION
                        // --------------------------------------------------
                        _buildTextField(
                          controller: questionController,
                          label: 'Question',
                          hint: 'Enter question',
                          maxLines: 3,
                          icon: Icons.help_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Question is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // --------------------------------------------------
                        // OPTIONS
                        // --------------------------------------------------
                        Text(
                          'Options',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        _buildOptionField(
                          controller: optionAController,
                          label: 'Option A',
                          prefix: 'A',
                        ),

                        const SizedBox(height: 10),

                        _buildOptionField(
                          controller: optionBController,
                          label: 'Option B',
                          prefix: 'B',
                        ),

                        const SizedBox(height: 10),

                        _buildOptionField(
                          controller: optionCController,
                          label: 'Option C',
                          prefix: 'C',
                        ),

                        const SizedBox(height: 10),

                        _buildOptionField(
                          controller: optionDController,
                          label: 'Option D',
                          prefix: 'D',
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // CORRECT ANSWER / MARKS
                        // --------------------------------------------------
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 560;

                            final correctDropdown =
                                DropdownButtonFormField<String>(
                                  value: correctAnswer,
                                  decoration: const InputDecoration(
                                    labelText: 'Correct Answer',
                                    prefixIcon: Icon(Icons.check_circle),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'A',
                                      child: Text('A'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'B',
                                      child: Text('B'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'C',
                                      child: Text('C'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'D',
                                      child: Text('D'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;

                                    setDialogState(() {
                                      correctAnswer = value;
                                    });
                                  },
                                );

                            final marksField = _buildTextField(
                              controller: marksController,
                              label: 'Marks',
                              hint: '1',
                              icon: Icons.star_outline,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final marks = int.tryParse(value?.trim() ?? '');

                                if (marks == null || marks <= 0) {
                                  return 'Enter valid marks';
                                }

                                return null;
                              },
                            );

                            if (isSmall) {
                              return Column(
                                children: [
                                  correctDropdown,
                                  const SizedBox(height: 12),
                                  marksField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: correctDropdown),
                                const SizedBox(width: 12),
                                SizedBox(width: 180, child: marksField),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // --------------------------------------------------
                        // EXPLANATION
                        // --------------------------------------------------
                        _buildTextField(
                          controller: explanationController,
                          label: 'Explanation',
                          hint: 'Optional explanation',
                          maxLines: 4,
                          icon: Icons.lightbulb_outline,
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
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (dialogClass?.id == null) {
                            _showSnackBar(
                              'Please select a class.',
                              isError: true,
                            );
                            return;
                          }

                          if (dialogSubject == null) {
                            _showSnackBar(
                              'Please select a subject.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final model = McqQuestionModel(
                              id: existingQuestion?.id,
                              subject: dialogSubject!.name,
                              classId: dialogClass!.id!,
                              className: dialogClass!.name,
                              questionDate: _formatApiDate(dialogDate),
                              question: questionController.text.trim(),
                              optionA: optionAController.text.trim(),
                              optionB: optionBController.text.trim(),
                              optionC: optionCController.text.trim(),
                              optionD: optionDController.text.trim(),
                              correctAnswer: correctAnswer,
                              marks: int.parse(marksController.text.trim()),
                              explanation: explanationController.text.trim(),
                              questionImageUrl:
                                  existingQuestion?.questionImageUrl,
                              optionAImageUrl:
                                  existingQuestion?.optionAImageUrl,
                              optionBImageUrl:
                                  existingQuestion?.optionBImageUrl,
                              optionCImageUrl:
                                  existingQuestion?.optionCImageUrl,
                              optionDImageUrl:
                                  existingQuestion?.optionDImageUrl,
                            );

                            if (existingQuestion == null) {
                              await _questionService!.createQuestion(model);
                            } else {
                              await _questionService!.updateQuestion(
                                existingQuestion.id!,
                                model,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showSnackBar(
                              existingQuestion == null
                                  ? 'Question added successfully.'
                                  : 'Question updated successfully.',
                            );

                            await _loadQuestions();
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            _showSnackBar(
                              e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    saving
                        ? 'Saving...'
                        : existingQuestion == null
                        ? 'Add Question'
                        : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    marksController.dispose();
    explanationController.dispose();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteQuestion(McqQuestionModel question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Question?'),
          content: const Text('This MCQ question will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _questionService!.deleteQuestion(question.id!);

      _showSnackBar('Question deleted successfully.');

      await _loadQuestions();
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _importExcel() async {
    if (_importing) return;

    try {
      setState(() {
        _importing = true;
      });

      debugPrint('========================================');
      debugPrint('MCQ EXCEL IMPORT STARTED');
      debugPrint('========================================');

      debugPrint('IMPORT STEP 1: Opening browser file picker...');

      final file = await pickExcelFile();

      debugPrint('IMPORT STEP 2: Browser file picker completed.');

      if (file == null) {
        debugPrint('IMPORT: User cancelled file selection.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Excel file selected.')),
          );
        }

        return;
      }

      debugPrint('IMPORT STEP 3: File selected.');
      debugPrint('FILE NAME: ${file.name}');
      debugPrint('FILE SIZE: ${file.bytes.length} bytes');

      if (file.bytes.isEmpty) {
        throw Exception('Selected Excel file is empty.');
      }

      final fileName = file.name.toLowerCase();

      if (!fileName.endsWith('.xlsx') && !fileName.endsWith('.xls')) {
        throw Exception('Please select a valid Excel file (.xlsx or .xls).');
      }

      debugPrint('IMPORT STEP 4: Sending Excel to backend...');

      final imported = await _questionService!.importExcel(
        bytes: file.bytes,
        fileName: file.name,
      );

      debugPrint('IMPORT STEP 5: Backend response received.');
      debugPrint('IMPORTED QUESTIONS: $imported');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$imported MCQ question${imported == 1 ? '' : 's'} imported successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint('IMPORT STEP 6: Refreshing question list...');

      await _loadQuestions();

      debugPrint('========================================');
      debugPrint('MCQ EXCEL IMPORT COMPLETED');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('MCQ EXCEL IMPORT FAILED');
      debugPrint('ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  void _showExcelTemplate() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.table_chart),
              const SizedBox(width: 10),
              const Expanded(child: Text('Excel Format')),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Excel file should contain these columns:'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: const SelectableText(
                      'Subject | Class | Question | Option A | '
                      'Option B | Option C | Option D | '
                      'Correct Answer | Marks | Explanation | '
                      'Question Date',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Example:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const SelectableText(
                      'Mathematics | Class 10 | '
                      'What is 2 + 2? | 3 | 4 | 5 | 6 | '
                      'B | 1 | 2 + 2 = 4 | 11-09-2026',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Correct Answer must be A, B, C or D.\n'
                    'Question Date supports dd-MM-yyyy, '
                    'dd/MM/yyyy and yyyy-MM-dd.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
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
      appBar: AppBar(
        title: const Text('MCQ Question Bank'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingQuestions ? null : _loadQuestions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildSummaryCards(),
                          const SizedBox(height: 20),
                          _buildFilters(),
                          const SizedBox(height: 20),
                          _buildQuestionContent(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 700;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCQ Question Bank',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Create, manage and import daily MCQ questions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );

        final buttons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _showExcelTemplate,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Excel Format'),
            ),
            OutlinedButton.icon(
              onPressed: _importing ? null : _importExcel,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_importing ? 'Importing...' : 'Import Excel'),
            ),
            FilledButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ],
        );

        if (small) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), buttons],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            buttons,
          ],
        );
      },
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================
  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 700
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard(
              width,
              'Questions',
              _questions.length.toString(),
              Icons.quiz_outlined,
            ),
            _summaryCard(
              width,
              'Class',
              _selectedClass?.name ?? 'All',
              Icons.school_outlined,
            ),
            _summaryCard(
              width,
              'Section',
              _selectedSection?.name ?? 'All',
              Icons.groups_outlined,
            ),
            _summaryCard(
              width,
              'Subject',
              _selectedSubject?.name ?? 'All',
              Icons.menu_book_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(double width, String title, String value, IconData icon) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 850;

            final classDropdown = _buildClassDropdown(
              value: _selectedClass,
              onChanged: (value) async {
                setState(() {
                  _selectedClass = value;
                  _selectedSection = null;
                  _sections = [];
                });

                if (value?.id != null) {
                  await _loadSections(value!.id!);
                }

                await _loadQuestions();
              },
            );

            final sectionDropdown = _buildSectionDropdown(
              sections: _sections,
              value: _selectedSection,
              onChanged: (value) async {
                setState(() {
                  _selectedSection = value;
                });

                await _loadQuestions();
              },
            );

            final subjectDropdown = _buildSubjectDropdown(
              value: _selectedSubject,
              onChanged: (value) async {
                setState(() {
                  _selectedSubject = value;
                });

                await _loadQuestions();
              },
            );

            final dateField = _buildDateField(
              date: _selectedDate,
              onTap: _selectDate,
            );

            if (isSmall) {
              return Column(
                children: [
                  classDropdown,
                  const SizedBox(height: 12),
                  sectionDropdown,
                  const SizedBox(height: 12),
                  subjectDropdown,
                  const SizedBox(height: 12),
                  dateField,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: classDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: sectionDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: subjectDropdown),
                    const SizedBox(width: 12),
                    SizedBox(width: 180, child: dateField),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
      _selectedSubject = null;
      _sections = [];
      _selectedDate = DateTime.now();
      _searchController.clear();
      _searchText = '';
    });

    _loadQuestions();
  }

  // ============================================================
  // QUESTION CONTENT
  // ============================================================

  Widget _buildQuestionContent() {
    if (_loadingQuestions) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return _buildQuestionBasicInfo();
  }

  Widget _buildQuestionBasicInfo() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'MCQ Question Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 700;

                final classInfo = _infoItem(
                  icon: Icons.school_outlined,
                  label: 'Class',
                  value: _selectedClass?.name ?? 'All Classes',
                );

                final sectionInfo = _infoItem(
                  icon: Icons.groups_outlined,
                  label: 'Section',
                  value: _selectedSection?.name ?? 'All Sections',
                );

                final subjectInfo = _infoItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Subject',
                  value: _selectedSubject?.name ?? 'All Subjects',
                );

                final dateInfo = _infoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _formatDisplayDate(_selectedDate),
                );

                if (small) {
                  return Column(
                    children: [
                      classInfo,
                      const SizedBox(height: 12),
                      sectionInfo,
                      const SizedBox(height: 12),
                      subjectInfo,
                      const SizedBox(height: 12),
                      dateInfo,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: classInfo),
                    const SizedBox(width: 12),
                    Expanded(child: sectionInfo),
                    const SizedBox(width: 12),
                    Expanded(child: subjectInfo),
                    const SizedBox(width: 12),
                    Expanded(child: dateInfo),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Available Questions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    _questions.length.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Questions are stored in the question bank and will be used when creating an MCQ test.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // QUESTION CARD
  // ============================================================

  Widget _buildQuestionCard(McqQuestionModel question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // TOP
            // ----------------------------------------------------
            LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 650;

                final title = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Text(
                        '${_filteredQuestions.indexOf(question) + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );

                final actions = Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showEditQuestionDialog(question),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteQuestion(question),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                );

                if (small) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // META
            // ----------------------------------------------------
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaChip(Icons.menu_book_outlined, question.subject),
                _metaChip(Icons.school_outlined, question.className ?? 'Class'),
                _metaChip(
                  Icons.calendar_today_outlined,
                  _formatModelDate(question.questionDate),
                ),
                _metaChip(
                  Icons.star_outline,
                  '${question.marks} mark${question.marks == 1 ? '' : 's'}',
                ),
                _correctChip(question.correctAnswer),
              ],
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------
            // OPTIONS
            // ----------------------------------------------------
            LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 700;

                final options = [
                  _optionCard('A', question.optionA, question.correctAnswer),
                  _optionCard('B', question.optionB, question.correctAnswer),
                  _optionCard('C', question.optionC, question.correctAnswer),
                  _optionCard('D', question.optionD, question.correctAnswer),
                ];

                if (small) {
                  return Column(
                    children: options
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: item,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: options
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: item,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            // ----------------------------------------------------
            // EXPLANATION
            // ----------------------------------------------------
            if (question.explanation != null &&
                question.explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(question.explanation!)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPTION CARD
  // ============================================================

  Widget _optionCard(String letter, String text, String correct) {
    final isCorrect = letter.toUpperCase() == correct.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isCorrect ? 1.5 : 1,
        ),
        color: isCorrect
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.35)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              letter,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, softWrap: true)),
          if (isCorrect) const Icon(Icons.check_circle, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No MCQ questions found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a question or import questions from Excel.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _importExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Excel'),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddQuestionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60),
            const SizedBox(height: 16),
            Text(
              'Unable to load MCQ Question Bank',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });

                _initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWNS
  // ============================================================

  Widget _buildClassDropdown({
    required SchoolClass? value,
    required ValueChanged<SchoolClass?> onChanged,
  }) {
    return DropdownButtonFormField<SchoolClass>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class',
        prefixIcon: Icon(Icons.school_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<SchoolClass>(
          value: null,
          child: Text('All Classes'),
        ),
        ..._classes
            .where((item) => item.id != null)
            .map(
              (item) => DropdownMenuItem<SchoolClass>(
                value: item,
                child: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
              ),
            ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSectionDropdown({
    required List<Section> sections,
    required Section? value,
    required ValueChanged<Section?> onChanged,
  }) {
    return DropdownButtonFormField<Section>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Section',
        prefixIcon: Icon(Icons.groups_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<Section>(
          value: null,
          child: Text('All Sections'),
        ),
        ...sections
            .where((item) => item.id != null)
            .map(
              (item) => DropdownMenuItem<Section>(
                value: item,
                child: Text(item.name ?? '', overflow: TextOverflow.ellipsis),
              ),
            ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSubjectDropdown({
    required SubjectModel? value,
    required ValueChanged<SubjectModel?> onChanged,
  }) {
    return DropdownButtonFormField<SubjectModel>(
      value: value,
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
        ..._subjects.map(
          (item) => DropdownMenuItem<SubjectModel>(
            value: item,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Question Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(_formatDisplayDate(date)),
      ),
    );
  }

  // ============================================================
  // TEXT FIELDS
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: Icon(icon),
              ),
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Widget _buildOptionField({
    required TextEditingController controller,
    required String label,
    required String prefix,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            radius: 14,
            child: Text(
              prefix,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // CHIPS
  // ============================================================

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(text, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _correctChip(String answer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16),
          const SizedBox(width: 5),
          Text(
            'Correct: ${answer.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PARSING
  // ============================================================

  DateTime _parseQuestionDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DateTime.now();
    }

    final text = value.trim();

    try {
      return DateTime.parse(text);
    } catch (_) {}

    try {
      final parts = text.split('-');

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

    return DateTime.now();
  }

  String _formatModelDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final parsed = _parseQuestionDate(value);

    return _formatDisplayDate(parsed);
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}

class ExcelFileData {
  final String name;
  final List<int> bytes;

  ExcelFileData({required this.name, required this.bytes});
}

Future<ExcelFileData?> pickExcelFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.xlsx,.xls'
    ..multiple = false;

  final completer = Completer<ExcelFileData?>();

  input.onChange.listen((event) {
    final files = input.files;

    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final file = files.first;

    debugPrint('SELECTED FILE: ${file.name}');
    debugPrint('FILE SIZE: ${file.size} bytes');

    final reader = html.FileReader();

    reader.onLoadEnd.listen((event) {
      try {
        final result = reader.result;

        debugPrint('FILE READER RESULT TYPE: ${result.runtimeType}');

        if (result == null) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('FileReader returned null.'),
            );
          }
          return;
        }

        Uint8List bytes;

        if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else {
          throw Exception(
            'Unsupported FileReader result type: ${result.runtimeType}',
          );
        }

        debugPrint('FILE BYTES READ: ${bytes.length}');

        if (bytes.isEmpty) {
          throw Exception('Excel file contains no data.');
        }

        if (!completer.isCompleted) {
          completer.complete(
            ExcelFileData(
              name: file.name,
              bytes: bytes.toList(),
            ),
          );
        }
      } catch (e) {
        debugPrint('FILE READER ERROR: $e');

        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    reader.onError.listen((event) {
      debugPrint('FILE READER ON ERROR: $event');

      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Failed to read selected Excel file.'),
        );
      }
    });

    debugPrint('STARTING FileReader.readAsArrayBuffer()...');

    reader.readAsArrayBuffer(file);
  });

  input.click();

  return completer.future;
}