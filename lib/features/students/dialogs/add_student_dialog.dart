import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartkids_admin/services/student_service.dart';

class AddStudentDialog extends StatefulWidget {
  final StudentService studentService;
  final Future<void> Function() onSaved;

  const AddStudentDialog({
    super.key,
    required this.studentService,
    required this.onSaved,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();

  final admissionNoController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final admissionDateController = TextEditingController();
  
  String selectedGender = 'Male';
  String selectedBloodGroup = 'A+';
  String selectedStatus = 'ACTIVE';

  bool isSaving = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    admissionNoController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    admissionDateController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate({
    required TextEditingController controller,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = _dateFormat.format(picked);
    }
  }

  // ============================================================
  // CREATE STUDENT
  // ============================================================

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      final fullName = [
        firstName,
        lastName,
      ].where((name) => name.isNotEmpty).join(' ');

      final data = <String, dynamic>{
        'admissionNo': _nullable(admissionNoController.text),
        'name': fullName,
        'email': _nullable(emailController.text),
        'phone': _nullable(phoneController.text),
        'dateOfBirth': _nullable(dobController.text),
        'gender': selectedGender,
        'bloodGroup': selectedBloodGroup,
        'admissionDate': _nullable(admissionDateController.text),
        'sectionId': null,
        'parentId': null,
        'academicYearId': null,
        'status': selectedStatus,
      };

      debugPrint('========== CREATE STUDENT DATA ==========');
      debugPrint('$data');
      debugPrint('=========================================');

      await widget.studentService.createStudent(data);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullable(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      enabled: !isSaving,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: !isSaving,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      onTap: () {
        _selectDate(
          controller: controller,
        );
      },
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: isSaving ? null : onChanged,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final dialogWidth = screenWidth > 900
        ? 760.0
        : screenWidth > 600
            ? 600.0
            : screenWidth * 0.94;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_alt_1,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add Student',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ------------------------------------------------
                // PERSONAL INFORMATION
                // ------------------------------------------------

                _sectionTitle(
                  'Personal Information',
                  Icons.person_outline,
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 560;

                    if (!twoColumns) {
                      return Column(
                        children: [
                          _textField(
                            controller: firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _textField(
                            controller: lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 560;

                    if (!twoColumns) {
                      return Column(
                        children: [
                          _dateField(
                            controller: dobController,
                            label: 'Date of Birth',
                            icon: Icons.cake_outlined,
                          ),
                          const SizedBox(height: 14),
                          _dropdownField(
                            label: 'Gender',
                            icon: Icons.wc_outlined,
                            value: selectedGender,
                            items: const [
                              'Male',
                              'Female',
                              'Other',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedGender = value;
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
                          child: _dateField(
                            controller: dobController,
                            label: 'Date of Birth',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _dropdownField(
                            label: 'Gender',
                            icon: Icons.wc_outlined,
                            value: selectedGender,
                            items: const [
                              'Male',
                              'Female',
                              'Other',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedGender = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 560;

                    if (!twoColumns) {
                      return _dropdownField(
                        label: 'Blood Group',
                        icon: Icons.bloodtype_outlined,
                        value: selectedBloodGroup,
                        items: const [
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'AB+',
                          'AB-',
                          'O+',
                          'O-',
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedBloodGroup = value;
                            });
                          }
                        },
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _dropdownField(
                            label: 'Blood Group',
                            icon: Icons.bloodtype_outlined,
                            value: selectedBloodGroup,
                            items: const [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedBloodGroup = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _textField(
                            controller: admissionNoController,
                            label: 'Admission No',
                            icon: Icons.badge_outlined,
                            required: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // ------------------------------------------------
                // CONTACT INFORMATION
                // ------------------------------------------------

                const SizedBox(height: 24),

                _sectionTitle(
                  'Contact Information',
                  Icons.contact_phone_outlined,
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 560;

                    if (!twoColumns) {
                      return Column(
                        children: [
                          _textField(
                            controller: phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _textField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // ------------------------------------------------
                // ACADEMIC INFORMATION
                // ------------------------------------------------

                const SizedBox(height: 24),

                _sectionTitle(
                  'Academic Information',
                  Icons.school_outlined,
                ),

                const SizedBox(height: 14),

                _dateField(
                  controller: admissionDateController,
                  label: 'Admission Date',
                  icon: Icons.event_outlined,
                  required: true,
                ),

                const SizedBox(height: 14),

                _dropdownField(
                  label: 'Status',
                  icon: Icons.toggle_on_outlined,
                  value: selectedStatus,
                  items: const [
                    'ACTIVE',
                    'INACTIVE',
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // PARENT NOTE
                // ------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Parent can be linked later from the Parents section.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: isSaving ? null : _saveStudent,
          icon: isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_outlined,
                  size: 18,
                ),
          label: Text(
            isSaving ? 'Saving...' : 'Save Student',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.blue.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}