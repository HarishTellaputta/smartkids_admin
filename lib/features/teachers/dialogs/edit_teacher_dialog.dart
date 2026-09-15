import 'package:flutter/material.dart';

import '../models/teacher_model.dart';
import '../services/teacher_service.dart';

class EditTeacherDialog extends StatefulWidget {
  final TeacherService teacherService;
  final Teacher teacher;
  final int schoolId;

  const EditTeacherDialog({
    super.key,
    required this.teacherService,
    required this.teacher,
    required this.schoolId,
  });

  @override
  State<EditTeacherDialog> createState() =>
      _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<EditTeacherDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController employeeIdController;
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController qualificationController;
  late final TextEditingController designationController;
  late final TextEditingController addressController;
  late final TextEditingController dobController;
  late final TextEditingController joiningDateController;

  String selectedGender = 'MALE';
  String selectedStatus = 'ACTIVE';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    employeeIdController = TextEditingController(
      text: widget.teacher.employeeId ?? '',
    );

    nameController = TextEditingController(
      text: widget.teacher.name ?? '',
    );

    emailController = TextEditingController(
      text: widget.teacher.email ?? '',
    );

    phoneController = TextEditingController(
      text: widget.teacher.phone ?? '',
    );

    qualificationController = TextEditingController(
      text: widget.teacher.qualification ?? '',
    );

    designationController = TextEditingController(
      text: widget.teacher.designation ?? '',
    );

    addressController = TextEditingController(
      text: widget.teacher.address ?? '',
    );

    dobController = TextEditingController(
      text: widget.teacher.dateOfBirth ?? '',
    );

    joiningDateController = TextEditingController(
      text: widget.teacher.joiningDate ?? '',
    );

    selectedGender =
        _normalizeGender(widget.teacher.gender);

    selectedStatus =
        _normalizeStatus(widget.teacher.status);
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    qualificationController.dispose();
    designationController.dispose();
    addressController.dispose();
    dobController.dispose();
    joiningDateController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> _updateTeacher() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.teacher.id == null) {
      _showMessage(
        'Teacher ID is missing.',
        isError: true,
      );
      return;
    }

    if (widget.teacher.userId == null) {
      _showMessage(
        'Teacher user ID is missing.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.teacherService.updateTeacher(
        id: widget.teacher.id!,
        schoolId:
            widget.teacher.schoolId ?? widget.schoolId,
        employeeId:
            employeeIdController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        dateOfBirth: dobController.text.trim(),
        gender: selectedGender,
        joiningDate:
            joiningDateController.text.trim(),
        qualification:
            qualificationController.text.trim(),
        designation:
            designationController.text.trim(),
        address: addressController.text.trim(),
        status: selectedStatus,
        userId: widget.teacher.userId!,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate(
    TextEditingController controller,
  ) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.trim().isNotEmpty) {
      try {
        initialDate =
            DateTime.parse(controller.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    controller.text = _formatDate(picked);

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screenHeight * 0.90,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      24,
                    ),
                    child: _buildForm(),
                  ),
                ),
              ),
              _buildFooter(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE7EAF0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Teacher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Update teacher information',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        _sectionTitle(
          'Basic Information',
          Icons.person_outline,
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _textField(
                    controller: employeeIdController,
                    label: 'Employee ID',
                    hint: 'Enter employee ID',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: nameController,
                    label: 'Name',
                    hint: 'Enter teacher name',
                    icon: Icons.person_outline,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _textField(
                    controller: employeeIdController,
                    label: 'Employee ID',
                    hint: 'Enter employee ID',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: nameController,
                    label: 'Name',
                    hint: 'Enter teacher name',
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
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _emailField(),
                  const SizedBox(height: 14),
                  _phoneField(),
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(child: _emailField()),
                const SizedBox(width: 14),
                Expanded(child: _phoneField()),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        _sectionTitle(
          'Personal Information',
          Icons.info_outline,
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _dateField(
                    controller: dobController,
                    label: 'Date of Birth',
                    icon: Icons.cake_outlined,
                  ),
                  const SizedBox(height: 14),
                  _genderDropdown(),
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  child: _genderDropdown(),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        _dateField(
          controller: joiningDateController,
          label: 'Joining Date',
          icon: Icons.event_outlined,
        ),

        const SizedBox(height: 20),

        _sectionTitle(
          'Professional Information',
          Icons.work_outline,
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _textField(
                    controller: qualificationController,
                    label: 'Qualification',
                    hint: 'e.g. B.Ed, M.Sc',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: designationController,
                    label: 'Designation',
                    hint: 'e.g. Teacher',
                    icon: Icons.badge_outlined,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _textField(
                    controller: qualificationController,
                    label: 'Qualification',
                    hint: 'e.g. B.Ed, M.Sc',
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _textField(
                    controller: designationController,
                    label: 'Designation',
                    hint: 'e.g. Teacher',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        _statusDropdown(),

        const SizedBox(height: 20),

        _sectionTitle(
          'Address',
          Icons.location_on_outlined,
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: addressController,
          maxLines: 3,
          decoration: _inputDecoration(
            label: 'Address',
            hint: 'Enter complete address',
            icon: Icons.home_outlined,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL
  // ============================================================

  Widget _emailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(
        label: 'Email',
        hint: 'teacher@example.com',
        icon: Icons.email_outlined,
      ),
      validator: (value) {
        final email = value?.trim() ?? '';

        if (email.isEmpty) {
          return 'Email is required';
        }

        if (!RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(email)) {
          return 'Enter valid email';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PHONE
  // ============================================================

  Widget _phoneField() {
    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: _inputDecoration(
        label: 'Phone',
        hint: '10-digit mobile number',
        icon: Icons.phone_outlined,
      ).copyWith(
        counterText: '',
      ),
      validator: (value) {
        final phone = value?.trim() ?? '';

        if (phone.isEmpty) {
          return 'Phone is required';
        }

        if (!RegExp(
          r'^[6-9]\d{9}$',
        ).hasMatch(phone)) {
          return 'Enter valid 10-digit phone';
        }

        return null;
      },
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Widget _genderDropdown() {
    return _dropdownField<String>(
      value: selectedGender,
      label: 'Gender',
      icon: Icons.wc_outlined,
      items: const [
        DropdownMenuItem(
          value: 'MALE',
          child: Text('Male'),
        ),
        DropdownMenuItem(
          value: 'FEMALE',
          child: Text('Female'),
        ),
        DropdownMenuItem(
          value: 'OTHER',
          child: Text('Other'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusDropdown() {
    return _dropdownField<String>(
      value: selectedStatus,
      label: 'Status',
      icon: Icons.toggle_on_outlined,
      items: const [
        DropdownMenuItem(
          value: 'ACTIVE',
          child: Text('ACTIVE'),
        ),
        DropdownMenuItem(
          value: 'INACTIVE',
          child: Text('INACTIVE'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedStatus = value;
        });
      },
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: _isSaving
          ? null
          : () {
              _pickDate(controller);
            },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: 'YYYY-MM-DD',
          icon: icon,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty
                    ? 'Select date'
                    : controller.text,
                style: TextStyle(
                  fontSize: 14,
                  color: controller.text.isEmpty
                      ? const Color(0xFF98A2B3)
                      : const Color(0xFF172033),
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: Color(0xFF667085),
            ),
          ],
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
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
    );
  }

  // ============================================================
  // GENERIC DROPDOWN
  // ============================================================

  Widget _dropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(
        label: label,
        hint: 'Select $label',
        icon: icon,
      ),
      items: items,
      onChanged: _isSaving ? null : onChanged,
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE7EAF0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed:
                _isSaving ? null : _updateTeacher,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
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
              _isSaving
                  ? 'Updating...'
                  : 'Update Teacher',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
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
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD0D5DD),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _normalizeGender(String? gender) {
    final value = gender?.trim().toUpperCase();

    if (value == 'FEMALE') return 'FEMALE';
    if (value == 'OTHER') return 'OTHER';

    return 'MALE';
  }

  String _normalizeStatus(String? status) {
    final value = status?.trim().toUpperCase();

    if (value == 'INACTIVE') {
      return 'INACTIVE';
    }

    return 'ACTIVE';
  }

  String _formatDate(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

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
              isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}