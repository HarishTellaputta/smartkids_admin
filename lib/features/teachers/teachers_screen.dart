import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/teacher_model.dart';
import 'models/class_model.dart';
import 'models/teacher_assignment_model.dart';

import 'services/teacher_service.dart';
import 'services/class_service.dart';
import 'services/teacher_assignment_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int _schoolId = 1;
  static const int _userId = 101;

  // ============================================================
  // SERVICES
  // ============================================================

  TeacherService? _teacherService;
  ClassService? _classService;
  TeacherAssignmentService? _assignmentService;

  // ============================================================
  // DATA
  // ============================================================

  List<Teacher> _teachers = [];
  List<Teacher> _filteredTeachers = [];
  List<SchoolClass> _classes = [];

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isLoadingClasses = false;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // INIT
  // ============================================================

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

      if (token == null || token.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          _showMessage(
            'JWT token not found. Please login again.',
            isError: true,
          );
        }

        return;
      }

      _teacherService = TeacherService(token);
      _classService = ClassService(token);
      _assignmentService = TeacherAssignmentService(token);

      await _loadTeachers();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showMessage(
          e.toString(),
          isError: true,
        );
      }
    }
  }

  // ============================================================
  // LOAD TEACHERS
  // ============================================================

  Future<void> _loadTeachers() async {
    if (_teacherService == null) return;

    setState(() {
      _isLoading = true;
    });

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

      _showMessage(
        e.toString(),
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> _loadClasses() async {
    if (_classService == null) return;

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final classes =
          await _classService!.getClassesBySchool(_schoolId);

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

      _showMessage(
        e.toString(),
        isError: true,
      );
    }
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    final result = _teachers.where((teacher) {
      final matchesSearch =
          query.isEmpty ||
          (teacher.name ?? '')
              .toLowerCase()
              .contains(query) ||
          (teacher.employeeId ?? '')
              .toLowerCase()
              .contains(query) ||
          (teacher.phone ?? '')
              .toLowerCase()
              .contains(query) ||
          (teacher.email ?? '')
              .toLowerCase()
              .contains(query) ||
          (teacher.designation ?? '')
              .toLowerCase()
              .contains(query) ||
          (teacher.qualification ?? '')
              .toLowerCase()
              .contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ||
          (teacher.status ?? '').toUpperCase() ==
              _selectedStatus.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();

    setState(() {
      _filteredTeachers = result;
    });
  }

  // ============================================================
  // ADD TEACHER
  // ============================================================

  void _showAddTeacherDialog() {
    final formKey = GlobalKey<FormState>();

    final employeeIdController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final qualificationController = TextEditingController();
    final designationController = TextEditingController();
    final dobController = TextEditingController();
    final joiningDateController = TextEditingController();
    final addressController = TextEditingController();

    String selectedGender = 'MALE';
    String selectedStatus = 'ACTIVE';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Teacher'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller:
                                    employeeIdController,
                                label: 'Employee ID',
                                icon: Icons.badge_outlined,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller: nameController,
                                label: 'Teacher Name',
                                icon: Icons.person_outline,
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                label: 'Gender',
                                value: selectedGender,
                                items: const [
                                  'MALE',
                                  'FEMALE',
                                  'OTHER',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedGender = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdown(
                                label: 'Status',
                                value: selectedStatus,
                                items: const [
                                  'ACTIVE',
                                  'INACTIVE',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller: phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                required: true,
                                keyboardType:
                                    TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                required: true,
                                keyboardType:
                                    TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller:
                                    qualificationController,
                                label: 'Qualification',
                                icon:
                                    Icons.school_outlined,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller:
                                    designationController,
                                label: 'Designation',
                                icon:
                                    Icons.work_outline,
                                required: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                context: context,
                                controller: dobController,
                                label: 'Date of Birth',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateField(
                                context: context,
                                controller:
                                    joiningDateController,
                                label: 'Joining Date',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _textField(
                          controller: addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          required: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!
                              .validate()) {
                            return;
                          }

                          if (dobController.text.trim().isEmpty) {
                            _showMessage(
                              'Please select Date of Birth.',
                              isError: true,
                            );
                            return;
                          }

                          if (joiningDateController
                              .text
                              .trim()
                              .isEmpty) {
                            _showMessage(
                              'Please select Joining Date.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _teacherService!
                                .createTeacher(
                              schoolId: _schoolId,
                              employeeId:
                                  employeeIdController.text
                                      .trim(),
                              name:
                                  nameController.text.trim(),
                              email:
                                  emailController.text.trim(),
                              phone:
                                  phoneController.text.trim(),
                              dateOfBirth:
                                  dobController.text.trim(),
                              gender: selectedGender,
                              joiningDate:
                                  joiningDateController.text
                                      .trim(),
                              qualification:
                                  qualificationController
                                      .text
                                      .trim(),
                              designation:
                                  designationController.text
                                      .trim(),
                              address:
                                  addressController.text
                                      .trim(),
                              status: selectedStatus,
                              userId: _userId,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              'Teacher created successfully.',
                            );

                            await _loadTeachers();
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            _showMessage(
                              e.toString(),
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT TEACHER
  // ============================================================

  void _showEditTeacherDialog(Teacher teacher) {
    if (teacher.id == null) return;

    final formKey = GlobalKey<FormState>();

    final employeeIdController = TextEditingController(
      text: teacher.employeeId ?? '',
    );

    final nameController = TextEditingController(
      text: teacher.name ?? '',
    );

    final phoneController = TextEditingController(
      text: teacher.phone ?? '',
    );

    final emailController = TextEditingController(
      text: teacher.email ?? '',
    );

    final qualificationController = TextEditingController(
      text: teacher.qualification ?? '',
    );

    final designationController = TextEditingController(
      text: teacher.designation ?? '',
    );

    final dobController = TextEditingController(
      text: teacher.dateOfBirth ?? '',
    );

    final joiningDateController = TextEditingController(
      text: teacher.joiningDate ?? '',
    );

    final addressController = TextEditingController(
      text: teacher.address ?? '',
    );

    String selectedGender =
        teacher.gender ?? 'MALE';

    String selectedStatus =
        teacher.status ?? 'ACTIVE';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Teacher'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller:
                                    employeeIdController,
                                label: 'Employee ID',
                                icon: Icons.badge_outlined,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller: nameController,
                                label: 'Teacher Name',
                                icon: Icons.person_outline,
                                required: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                label: 'Gender',
                                value: selectedGender,
                                items: const [
                                  'MALE',
                                  'FEMALE',
                                  'OTHER',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedGender =
                                          value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdown(
                                label: 'Status',
                                value: selectedStatus,
                                items: const [
                                  'ACTIVE',
                                  'INACTIVE',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedStatus =
                                          value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller: phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                required: true,
                                keyboardType:
                                    TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                required: true,
                                keyboardType:
                                    TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                controller:
                                    qualificationController,
                                label: 'Qualification',
                                icon:
                                    Icons.school_outlined,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                controller:
                                    designationController,
                                label: 'Designation',
                                icon:
                                    Icons.work_outline,
                                required: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                context: context,
                                controller: dobController,
                                label: 'Date of Birth',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dateField(
                                context: context,
                                controller:
                                    joiningDateController,
                                label: 'Joining Date',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _textField(
                          controller: addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          required: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!
                              .validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _teacherService!
                                .updateTeacher(
                              id: teacher.id!,
                              schoolId:
                                  teacher.schoolId ??
                                      _schoolId,
                              employeeId:
                                  employeeIdController.text
                                      .trim(),
                              name:
                                  nameController.text.trim(),
                              email:
                                  emailController.text.trim(),
                              phone:
                                  phoneController.text.trim(),
                              dateOfBirth:
                                  dobController.text.trim(),
                              gender: selectedGender,
                              joiningDate:
                                  joiningDateController.text
                                      .trim(),
                              qualification:
                                  qualificationController
                                      .text
                                      .trim(),
                              designation:
                                  designationController.text
                                      .trim(),
                              address:
                                  addressController.text
                                      .trim(),
                              status: selectedStatus,
                              userId: _userId,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              'Teacher updated successfully.',
                            );

                            await _loadTeachers();
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            _showMessage(
                              e.toString(),
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE TEACHER
  // ============================================================

  Future<void> _deleteTeacher(Teacher teacher) async {
    if (teacher.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Teacher'),
          content: Text(
            'Are you sure you want to delete '
            '${teacher.name ?? 'this teacher'}?',
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

    if (confirmed != true) return;

    try {
      await _teacherService!.deleteTeacher(
        teacher.id!,
      );

      if (!mounted) return;

      _showMessage(
        'Teacher deleted successfully.',
      );

      await _loadTeachers();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString(),
        isError: true,
      );
    }
  }

  // ============================================================
  // VIEW TEACHER
  // ============================================================

  Future<void> _showTeacherDetails(
    Teacher teacher,
  ) async {
    List<TeacherAssignment> assignments = [];
    bool loadingAssignments = true;

    if (teacher.id != null &&
        _assignmentService != null) {
      try {
        assignments = await _assignmentService!
            .getAssignmentsByTeacher(
          teacher.id!,
        );
      } catch (_) {
        assignments = [];
      }
    }

    loadingAssignments = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: Text(
                  _initial(
                    teacher.name,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  teacher.name ?? 'Teacher',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _detailSection(
                    'Professional Information',
                  ),
                  _detailRow(
                    'Employee ID',
                    teacher.employeeId,
                  ),
                  _detailRow(
                    'Designation',
                    teacher.designation,
                  ),
                  _detailRow(
                    'Qualification',
                    teacher.qualification,
                  ),
                  _detailRow(
                    'Status',
                    teacher.status,
                  ),

                  const SizedBox(height: 16),

                  _detailSection(
                    'Contact Information',
                  ),
                  _detailRow(
                    'Phone',
                    teacher.phone,
                  ),
                  _detailRow(
                    'Email',
                    teacher.email,
                  ),
                  _detailRow(
                    'Address',
                    teacher.address,
                  ),

                  const SizedBox(height: 16),

                  _detailSection(
                    'Personal Information',
                  ),
                  _detailRow(
                    'Gender',
                    teacher.gender,
                  ),
                  _detailRow(
                    'Date of Birth',
                    teacher.dateOfBirth,
                  ),
                  _detailRow(
                    'Joining Date',
                    teacher.joiningDate,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Assigned Classes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${assignments.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (loadingAssignments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (assignments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No classes assigned yet.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...assignments.map(
                      (assignment) {
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.grey.shade200,
                            ),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration:
                                    BoxDecoration(
                                  color: Colors.blue
                                      .withOpacity(.08),
                                  borderRadius:
                                      BorderRadius.circular(
                                    8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.class_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      assignment.className ??
                                          'Unknown Class',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      assignment.subject ??
                                          'No Subject',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Remove Assignment',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    assignment.id == null
                                        ? null
                                        : () async {
                                            final result =
                                                await _removeAssignment(
                                              assignment,
                                            );

                                            if (result &&
                                                dialogContext
                                                    .mounted) {
                                              Navigator.pop(
                                                dialogContext,
                                              );

                                              _showTeacherDetails(
                                                teacher,
                                              );
                                            }
                                          },
                              ),
                            ],
                          ),
                        );
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
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showAssignClassDialog(
                  teacher,
                );
              },
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
              label: const Text(
                'Assign Class',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ASSIGN CLASS DIALOG
  // ============================================================

  Future<void> _showAssignClassDialog(
    Teacher teacher,
  ) async {
    if (teacher.id == null) return;

    if (_classes.isEmpty) {
      await _loadClasses();
    }

    if (!mounted) return;

    final subjectController =
        TextEditingController();

    SchoolClass? selectedClass;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Assign Class',
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher: ${teacher.name ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoadingClasses)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    else if (_classes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: const Text(
                          'No classes found for this school.',
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedClass?.id,
                        decoration:
                            const InputDecoration(
                          labelText: 'Class',
                          prefixIcon: Icon(
                            Icons.class_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        items: _classes
                            .where(
                              (item) =>
                                  item.id != null,
                            )
                            .map(
                              (item) {
                                return DropdownMenuItem<
                                    int>(
                                  value: item.id,
                                  child: Text(
                                    item.name ??
                                        'Class ${item.id}',
                                  ),
                                );
                              },
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          final classItem =
                              _classes.firstWhere(
                            (item) =>
                                item.id == value,
                          );

                          setDialogState(() {
                            selectedClass =
                                classItem;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a class';
                          }

                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: subjectController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Subject',
                        hintText:
                            'Example: Mathematics',
                        prefixIcon: Icon(
                          Icons.menu_book_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Subject name is sent to the backend as text.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ||
                          selectedClass == null
                      ? null
                      : () async {
                          final subject =
                              subjectController.text
                                  .trim();

                          if (subject.isEmpty) {
                            _showMessage(
                              'Please enter subject.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _assignmentService!
                                .createAssignment(
                              teacherId:
                                  teacher.id!,
                              classId:
                                  selectedClass!.id!,
                              subject: subject,
                            );

                            if (!mounted) return;

                            Navigator.pop(
                              dialogContext,
                            );

                            _showMessage(
                              'Class assigned successfully.',
                            );

                            _showTeacherDetails(
                              teacher,
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            _showMessage(
                              e.toString(),
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Assign',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REMOVE ASSIGNMENT
  // ============================================================

  Future<bool> _removeAssignment(
    TeacherAssignment assignment,
  ) async {
    if (assignment.id == null) {
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Remove Assignment',
          ),
          content: Text(
            'Remove ${assignment.className ?? 'class'} '
            'from ${assignment.subject ?? 'subject'}?',
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    try {
      await _assignmentService!.deleteAssignment(
        assignment.id!,
      );

      if (!mounted) return false;

      _showMessage(
        'Assignment removed successfully.',
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      _showMessage(
        e.toString(),
        isError: true,
      );

      return false;
    }
  }

  // ============================================================
  // FILTER DIALOG
  // ============================================================

  void _showFilterDialog() {
    String tempStatus = _selectedStatus;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Filter Teachers',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'All',
                        selected:
                            tempStatus == 'All',
                        onSelected: () {
                          setDialogState(() {
                            tempStatus = 'All';
                          });
                        },
                      ),
                      _filterChip(
                        label: 'ACTIVE',
                        selected:
                            tempStatus == 'ACTIVE',
                        onSelected: () {
                          setDialogState(() {
                            tempStatus = 'ACTIVE';
                          });
                        },
                      ),
                      _filterChip(
                        label: 'INACTIVE',
                        selected:
                            tempStatus == 'INACTIVE',
                        onSelected: () {
                          setDialogState(() {
                            tempStatus = 'INACTIVE';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus =
                          tempStatus;
                    });

                    Navigator.pop(dialogContext);

                    _applyFilters();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
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
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadTeachers,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  0,
                ),
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
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
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
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Teachers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage teachers and their professional information.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddTeacherDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Teacher'),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    final total = _teachers.length;

    final active = _teachers.where(
      (teacher) =>
          (teacher.status ?? '')
              .toUpperCase() ==
          'ACTIVE',
    ).length;

    final inactive = _teachers.where(
      (teacher) =>
          (teacher.status ?? '')
              .toUpperCase() ==
          'INACTIVE',
    ).length;

    final designations = _teachers
        .map(
          (teacher) =>
              teacher.designation?.trim(),
        )
        .where(
          (designation) =>
              designation != null &&
              designation!.isNotEmpty,
        )
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard(
              width: cardWidth,
              title: 'Total Teachers',
              value: total.toString(),
              icon: Icons.people_outline,
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Active Teachers',
              value: active.toString(),
              icon: Icons.check_circle_outline,
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Inactive',
              value: inactive.toString(),
              icon: Icons.pause_circle_outline,
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Designations',
              value: designations.toString(),
              icon: Icons.work_outline,
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
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText:
                    'Search teachers...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchController.text
                            .isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();

                              _searchQuery = '';

                              _applyFilters();

                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    const Color(0xFFF5F7FB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(
              Icons.filter_list,
            ),
            label: Text(
              _selectedStatus == 'All'
                  ? 'Filter'
                  : _selectedStatus,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER TABLE
  // ============================================================

  Widget _buildTeacherTable() {
    if (_isLoading) {
      return const SizedBox(
        height: 350,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredTeachers.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'No teachers found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Try changing your search or filter.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 65,
            dataRowMaxHeight: 75,
            columnSpacing: 28,
            headingRowColor:
                WidgetStatePropertyAll(
              const Color(0xFFF8FAFC),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'Teacher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Employee ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Designation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qualification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: _filteredTeachers.map(
              (teacher) {
                return DataRow(
                  cells: [
                    DataCell(
                      _teacherCell(teacher),
                    ),
                    DataCell(
                      Text(
                        teacher.employeeId ?? '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        teacher.designation ?? '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        teacher.qualification ?? '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        teacher.phone ?? '-',
                      ),
                    ),
                    DataCell(
                      _statusBadge(
                        teacher.status,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            icon: const Icon(
                              Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              _showTeacherDetails(
                                teacher,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(
                              Icons.edit_outlined,
                            ),
                            onPressed: () {
                              _showEditTeacherDialog(
                                teacher,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Assign Class',
                            icon: const Icon(
                              Icons.assignment_outlined,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              _showAssignClassDialog(
                                teacher,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _deleteTeacher(
                                teacher,
                              );
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
      ),
    );
  }

  // ============================================================
  // TEACHER CELL
  // ============================================================

  Widget _teacherCell(Teacher teacher) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Colors.blue.withOpacity(.10),
            child: Text(
              _initial(teacher.name),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teacher.name ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String? status) {
    final active =
        (status ?? '').toUpperCase() == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(.10)
            : Colors.red.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status ?? '-',
        style: TextStyle(
          color: active
              ? Colors.green.shade700
              : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (required &&
            (value == null ||
                value.trim().isEmpty)) {
          return '$label is required';
        }

        if (label == 'Phone' &&
            value != null &&
            value.trim().isNotEmpty) {
          if (!RegExp(r'^\d{10}$')
              .hasMatch(value.trim())) {
            return 'Enter valid 10 digit phone';
          }
        }

        if (label == 'Email' &&
            value != null &&
            value.trim().isNotEmpty) {
          if (!RegExp(
            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
          ).hasMatch(value.trim())) {
            return 'Enter valid email';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value)
          ? value
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map(
        (item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        },
      ).toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.calendar_today_outlined,
        ),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime initialDate =
            DateTime.now();

        if (controller.text.isNotEmpty) {
          final parsed =
              DateTime.tryParse(
            controller.text,
          );

          if (parsed != null) {
            initialDate = parsed;
          }
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          final formatted =
              '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';

          controller.text = formatted;
        }
      },
    );
  }

  // ============================================================
  // DETAIL SECTION
  // ============================================================

  Widget _detailSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String? value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null ||
                      value.trim().isEmpty
                  ? '-'
                  : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }

  // ============================================================
  // INITIAL
  // ============================================================

  String _initial(String? name) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : Colors.green,
        ),
      );
  }
}