import 'package:flutter/material.dart';

import '../models/available_teacher_user_model.dart';
import '../services/teacher_service.dart';

class AddTeacherDialog extends StatefulWidget {
  final TeacherService teacherService;
  final int schoolId;
  final List<AvailableTeacherUser> availableUsers;
  final bool isLoadingAvailableUsers;

  const AddTeacherDialog({
    super.key,
    required this.teacherService,
    required this.schoolId,
    required this.availableUsers,
    required this.isLoadingAvailableUsers,
  });

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final qualificationController = TextEditingController();
  final designationController = TextEditingController();
  final addressController = TextEditingController();

  AvailableTeacherUser? selectedUser;

  DateTime? selectedDob;
  DateTime? selectedJoiningDate;

  String selectedGender = 'MALE';
  String selectedStatus = 'ACTIVE';

  bool _isSaving = false;

  @override
  void dispose() {
    phoneController.dispose();
    qualificationController.dispose();
    designationController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE TEACHER
  // ============================================================

  Future<void> _createTeacher() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedUser == null) {
      _showMessage(
        'Please select a registered teacher user.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.teacherService.createTeacher(
        schoolId: widget.schoolId,
        userId: selectedUser!.id,
        phone: phoneController.text.trim(),
        dateOfBirth: selectedDob == null
            ? null
            : _formatDate(selectedDob!),
        gender: selectedGender,
        joiningDate: selectedJoiningDate == null
            ? null
            : _formatDate(selectedJoiningDate!),
        qualification:
            qualificationController.text.trim(),
        designation:
            designationController.text.trim(),
        address: addressController.text.trim(),
        status: selectedStatus,
      );

      if (!mounted) return;

      // IMPORTANT:
      // Close dialog immediately after successful API response.
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

  Future<void> _pickDate({
    required bool isDob,
  }) async {
    final now = DateTime.now();

    final initialDate = isDob
        ? (selectedDob ??
            DateTime(
              now.year - 25,
              now.month,
              now.day,
            ))
        : (selectedJoiningDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isDob) {
        selectedDob = picked;
      } else {
        selectedJoiningDate = picked;
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

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
              Icons.person_add_alt_1,
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
                  'Add Teacher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Add a registered teacher to your school',
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
          'Teacher Account',
          Icons.account_circle_outlined,
        ),

        const SizedBox(height: 12),

        _registeredTeacherDropdown(),

        const SizedBox(height: 20),

        _sectionTitle(
          'Personal Information',
          Icons.person_outline,
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _phoneField(),
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
                  child: _phoneField(),
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

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  _dateField(
                    label: 'Date of Birth',
                    value: selectedDob,
                    icon: Icons.cake_outlined,
                    onTap: () {
                      _pickDate(isDob: true);
                    },
                  ),
                  const SizedBox(height: 14),
                  _dateField(
                    label: 'Joining Date',
                    value: selectedJoiningDate,
                    icon: Icons.event_outlined,
                    onTap: () {
                      _pickDate(isDob: false);
                    },
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'Date of Birth',
                    value: selectedDob,
                    icon: Icons.cake_outlined,
                    onTap: () {
                      _pickDate(isDob: true);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _dateField(
                    label: 'Joining Date',
                    value: selectedJoiningDate,
                    icon: Icons.event_outlined,
                    onTap: () {
                      _pickDate(isDob: false);
                    },
                  ),
                ),
              ],
            );
          },
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
                    hint: 'e.g. Teacher, Senior Teacher',
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
                    hint: 'e.g. Teacher, Senior Teacher',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        _dropdownField<String>(
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
        ),

        const SizedBox(height: 20),

        _sectionTitle(
          'Address',
          Icons.location_on_outlined,
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: addressController,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
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
  // REGISTERED TEACHER DROPDOWN
  // ============================================================

  Widget _registeredTeacherDropdown() {
    if (widget.isLoadingAvailableUsers) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Registered Teacher',
          hint: '',
          icon: Icons.person_search_outlined,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Loading teacher users...',
              style: TextStyle(
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.availableUsers.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Registered Teacher',
          hint: '',
          icon: Icons.person_search_outlined,
        ),
        child: const Text(
          'No available teacher users found',
          style: TextStyle(
            color: Color(0xFFB42318),
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: selectedUser?.id,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Registered Teacher',
        hint: 'Select teacher',
        icon: Icons.person_search_outlined,
      ),
      items: widget.availableUsers.map((user) {
        return DropdownMenuItem<int>(
          value: user.id,
          child: Text(
            '${user.username} • ${user.email}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              if (value == null) return;

              final user =
                  widget.availableUsers.firstWhere(
                (item) => item.id == value,
              );

              setState(() {
                selectedUser = user;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Please select a teacher';
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

        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
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
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: 'Select date',
          icon: icon,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null
                    ? 'Select date'
                    : _formatDate(value),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? const Color(0xFF98A2B3)
                      : const Color(0xFF172033),
                  fontWeight: value == null
                      ? FontWeight.w400
                      : FontWeight.w500,
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
        mainAxisAlignment: MainAxisAlignment.end,
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
            onPressed: _isSaving
                ? null
                : _createTeacher,
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
                    Icons.person_add_alt_1,
                    size: 18,
                  ),
            label: Text(
              _isSaving
                  ? 'Creating...'
                  : 'Add Teacher',
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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

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