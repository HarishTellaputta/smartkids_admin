import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/models/academic_year_model.dart';
import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/models/parent_model.dart';

import 'package:smartkids_admin/services/student_service.dart';
import 'package:smartkids_admin/services/academic_year_service.dart';
import 'package:smartkids_admin/services/section_service.dart';
import 'package:smartkids_admin/services/parent_service.dart';

import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/core/network/api_client.dart';

class EditStudentDialog extends StatefulWidget {
  final Student student;
  final StudentService studentService;
  final Future<void> Function() onSaved;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.studentService,
    required this.onSaved,
  });

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  final ApiClient apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController admissionNoController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController dobController;
  late final TextEditingController admissionDateController;

  String selectedGender = 'Male';
  String selectedBloodGroup = 'A+';
  String selectedStatus = 'ACTIVE';

  bool isSaving = false;
  bool isLoadingAcademicData = true;
  bool isLoadingSections = false;

  String? academicDataError;

  late AcademicYearService _academicYearService;
  late ClassService _classService;
  late SectionService _sectionService;
  late ParentService _parentService;

  List<AcademicYear> academicYears = [];
  List<SchoolClass> classes = [];
  List<Section> sections = [];
  List<Parent> parents = [];

  AcademicYear? selectedAcademicYear;
  SchoolClass? selectedClass;
  Section? selectedSection;
  Parent? selectedParent;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    admissionNoController = TextEditingController(
      text: widget.student.admissionNo ?? '',
    );

    final nameParts = _splitName(widget.student.name ?? '');

    firstNameController = TextEditingController(
      text: nameParts.first,
    );

    lastNameController = TextEditingController(
      text: nameParts.second,
    );

    emailController = TextEditingController(
      text: widget.student.email ?? '',
    );

    phoneController = TextEditingController(
      text: widget.student.phone ?? '',
    );

    dobController = TextEditingController(
      text: _formatDateString(widget.student.dateOfBirth),
    );

    admissionDateController = TextEditingController(
      text: _formatDateString(widget.student.admissionDate),
    );

    selectedGender = _validGender(widget.student.gender);
    selectedBloodGroup = _validBloodGroup(widget.student.bloodGroup);
    selectedStatus = _validStatus(widget.student.status);

    _initializeServicesAndLoadData();
  }

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
  // INITIALIZE SERVICES
  // ============================================================

  Future<void> _initializeServicesAndLoadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingAcademicData = false;
          academicDataError =
              'Login session expired. Please login again.';
        });

        return;
      }

      _academicYearService = AcademicYearService(token);
      _classService = ClassService(apiClient);
      _sectionService = SectionService(apiClient);
      _parentService = ParentService(token);

      await _loadAcademicData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAcademicData = false;
        academicDataError =
            'Failed to initialize academic information: $e';
      });
    }
  }

  // ============================================================
  // LOAD ACADEMIC DATA
  // ============================================================

  Future<void> _loadAcademicData() async {
    try {
      final results = await Future.wait([
        _academicYearService.getAcademicYears(),
        _classService.getClasses(),
        _sectionService.getSections(),
        _parentService.getParents(),
      ]);

      final loadedAcademicYears = results[0] as List<AcademicYear>;
      final loadedClasses = results[1] as List<SchoolClass>;
      final loadedSections = results[2] as List<Section>;
      final loadedParents = results[3] as List<Parent>;

      AcademicYear? existingAcademicYear;

      for (final academicYear in loadedAcademicYears) {
        if (academicYear.id == widget.student.academicYearId) {
          existingAcademicYear = academicYear;
          break;
        }
      }

      SchoolClass? existingClass;
      Section? existingSection;

      for (final section in loadedSections) {
        if (section.id == widget.student.sectionId) {
          existingSection = section;
          break;
        }
      }

      if (existingSection != null) {
        for (final schoolClass in loadedClasses) {
          if (schoolClass.id == existingSection.classId) {
            existingClass = schoolClass;
            break;
          }
        }
      }

      Parent? existingParent;

      if (widget.student.parentId != null) {
        for (final parent in loadedParents) {
          if (parent.id == widget.student.parentId) {
            existingParent = parent;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        academicYears = loadedAcademicYears;
        classes = loadedClasses;
        parents = loadedParents;

        selectedAcademicYear = existingAcademicYear;
        selectedClass = existingClass;
        selectedParent = existingParent;

        isLoadingAcademicData = false;
        academicDataError = null;
      });

      if (existingClass?.id != null) {
        await _loadSectionsForClass(
          existingClass!.id!,
          initialSectionId: existingSection?.id,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAcademicData = false;
        academicDataError =
            'Failed to load academic information: $e';
      });
    }
  }

  // ============================================================
  // LOAD SECTIONS
  // ============================================================

  Future<void> _loadSectionsForClass(
    int classId, {
    int? initialSectionId,
  }) async {
    if (!mounted) return;

    setState(() {
      isLoadingSections = true;
      sections = [];
      selectedSection = null;
    });

    try {
      final loadedSections =
          await _sectionService.getSectionsByClassId(classId);

      Section? existingSection;

      if (initialSectionId != null) {
        for (final section in loadedSections) {
          if (section.id == initialSectionId) {
            existingSection = section;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        sections = loadedSections;
        selectedSection = existingSection;
        isLoadingSections = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSections = false;
        selectedSection = null;
      });

      _showErrorSnackBar('Failed to load sections: $e');
    }
  }

  // ============================================================
  // DROPDOWN CHANGES
  // ============================================================

  void _onAcademicYearChanged(AcademicYear? value) {
    if (value == null) return;

    setState(() {
      selectedAcademicYear = value;
    });
  }

  Future<void> _onClassChanged(SchoolClass? value) async {
    if (value == null || value.id == null) return;

    setState(() {
      selectedClass = value;
      selectedSection = null;
      sections = [];
    });

    await _loadSectionsForClass(value.id!);
  }

  void _onSectionChanged(Section? value) {
    setState(() {
      selectedSection = value;
    });
  }

  void _onParentChanged(Parent? value) {
    setState(() {
      selectedParent = value;
    });
  }

  // ============================================================
  // NAME SPLIT
  // ============================================================

  ({String first, String second}) _splitName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return (
        first: '',
        second: '',
      );
    }

    final parts = trimmed.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return (
        first: parts.first,
        second: '',
      );
    }

    return (
      first: parts.first,
      second: parts.sublist(1).join(' '),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDateString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    return _dateFormat.format(parsed);
  }

  Future<void> _selectDate({
    required TextEditingController controller,
  }) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(
        controller.text.trim(),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _dateFormat.format(picked);
    }
  }

  // ============================================================
  // VALID VALUES
  // ============================================================

  String _validGender(String? value) {
    const values = [
      'Male',
      'Female',
      'Other',
    ];

    if (value != null && values.contains(value)) {
      return value;
    }

    return 'Male';
  }

  String _validBloodGroup(String? value) {
    const values = [
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];

    if (value != null && values.contains(value)) {
      return value;
    }

    return 'A+';
  }

  String _validStatus(String? value) {
    const values = [
      'ACTIVE',
      'INACTIVE',
    ];

    final normalized = value?.toUpperCase();

    if (normalized != null &&
        values.contains(normalized)) {
      return normalized;
    }

    return 'ACTIVE';
  }

  // ============================================================
  // UPDATE STUDENT
  // ============================================================

  Future<void> _updateStudent() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.student.id == null) {
      _showErrorSnackBar('Student ID not found');
      return;
    }

    if (selectedAcademicYear == null ||
        selectedAcademicYear!.id == null) {
      _showErrorSnackBar('Please select Academic Year');
      return;
    }

    if (selectedClass == null ||
        selectedClass!.id == null) {
      _showErrorSnackBar('Please select Class');
      return;
    }

    if (selectedSection == null ||
        selectedSection!.id == null) {
      _showErrorSnackBar('Please select Section');
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

      /*
       * IMPORTANT:
       *
       * Backend expects:
       * academicYearId
       * sectionId
       * parentId
       *
       * Class ID is NOT sent because Section already
       * belongs to the selected Class.
       */

      final data = <String, dynamic>{
        'admissionNo': _nullable(
          admissionNoController.text,
        ),

        'name': fullName,

        'email': _nullable(
          emailController.text,
        ),

        'phone': _nullable(
          phoneController.text,
        ),

        'dateOfBirth': _nullable(
          dobController.text,
        ),

        'gender': selectedGender,

        'bloodGroup': selectedBloodGroup,

        'admissionDate': _nullable(
          admissionDateController.text,
        ),

        'academicYearId':
            selectedAcademicYear!.id,

        'sectionId':
            selectedSection!.id,

        // Parent is optional.
        'parentId':
            selectedParent?.id,

        'status':
            selectedStatus,
      };

      debugPrint(
        '========== UPDATE STUDENT ==========',
      );

      debugPrint(
        'Student ID: ${widget.student.id}',
      );

      debugPrint(
        'Academic Year ID: ${selectedAcademicYear!.id}',
      );

      debugPrint(
        'Class ID: ${selectedClass!.id}',
      );

      debugPrint(
        'Section ID: ${selectedSection!.id}',
      );

      debugPrint(
        'Parent ID: ${selectedParent?.id}',
      );

      debugPrint(
        '====================================',
      );

      await widget.studentService.updateStudent(
        widget.student.id!,
        data,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Student updated successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showErrorSnackBar(
        'Failed to update student: ${_cleanErrorMessage(e)}',
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _nullable(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }

    return message;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREMIUM TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      enabled: !isSaving,

      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,

      decoration: _inputDecoration(
        label: label,
        icon: icon,
        required: required,
        hint: isPhone
            ? '10-digit mobile number'
            : isEmail
                ? 'student@example.com'
                : null,
      ).copyWith(
        counterText: isPhone ? '' : null,
      ),

      validator: (value) {
        final text = value?.trim() ?? '';

        if (required && text.isEmpty) {
          return '$label is required';
        }

        if (text.isEmpty) {
          return null;
        }

        if (isPhone) {
          if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(text)) {
            return 'Enter a valid 10-digit mobile number';
          }

          if (RegExp(r'^(\d)\1{9}$').hasMatch(text)) {
            return 'Enter a valid mobile number';
          }
        }

        if (isEmail) {
          final emailRegex = RegExp(
            r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@'
            r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}'
            r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]'
            r'(?:[a-zA-Z0-9-]{0,61}'
            r'[a-zA-Z0-9])?)+$',
          );

          if (!emailRegex.hasMatch(text)) {
            return 'Enter a valid email address';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // PREMIUM DATE FIELD
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

      decoration: _inputDecoration(
        label: label,
        icon: icon,
        required: required,
      ).copyWith(
        suffixIcon: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF2563EB),
            size: 19,
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
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ============================================================
  // PREMIUM STRING DROPDOWN
  // ============================================================

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = true,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        required: required,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              Icon(
                _dropdownIcon(item),
                size: 18,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 9),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: isSaving ? null : onChanged,
      validator: required
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  IconData _dropdownIcon(String value) {
    switch (value) {
      case 'Male':
        return Icons.male_rounded;

      case 'Female':
        return Icons.female_rounded;

      case 'Other':
        return Icons.transgender_rounded;

      case 'ACTIVE':
        return Icons.check_circle_outline_rounded;

      case 'INACTIVE':
        return Icons.pause_circle_outline_rounded;

      case 'A+':
      case 'A-':
      case 'B+':
      case 'B-':
      case 'AB+':
      case 'AB-':
      case 'O+':
      case 'O-':
        return Icons.bloodtype_outlined;

      default:
        return Icons.circle_outlined;
    }
  }

  // ============================================================
  // PREMIUM INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    bool required = false,
    String? hint,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,

      filled: true,
      fillColor: const Color(0xFFF8FAFC),

      prefixIcon: Container(
        width: 52,
        margin: const EdgeInsets.only(right: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFEFF6FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
        ),
        child: Icon(
          icon,
          color: Color(0xFF2563EB),
          size: 20,
        ),
      ),

      prefixIconConstraints: const BoxConstraints(
        minWidth: 52,
        minHeight: 52,
      ),

      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),

      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),

      errorStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // ACADEMIC YEAR DROPDOWN
  // ============================================================

  Widget _academicYearDropdown() {
    return DropdownButtonFormField<AcademicYear>(
      initialValue: selectedAcademicYear,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Academic Year',
        icon: Icons.calendar_month_outlined,
        required: true,
      ),

      items: academicYears.map((year) {
        return DropdownMenuItem<AcademicYear>(
          value: year,
          child: Text(
            year.name ?? 'Academic Year',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),

      onChanged: isSaving
          ? null
          : _onAcademicYearChanged,

      validator: (value) {
        if (value == null) {
          return 'Academic Year is required';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CLASS DROPDOWN
  // ============================================================

  Widget _classDropdown() {
    return DropdownButtonFormField<SchoolClass>(
      initialValue: selectedClass,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Class',
        icon: Icons.school_outlined,
        required: true,
      ),

      items: classes.map((schoolClass) {
        final displayName =
            schoolClass.name ??
            schoolClass.grade ??
            schoolClass.code ??
            'Class';

        return DropdownMenuItem<SchoolClass>(
          value: schoolClass,
          child: Text(
            displayName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),

      onChanged: isSaving
          ? null
          : _onClassChanged,

      validator: (value) {
        if (value == null) {
          return 'Class is required';
        }

        return null;
      },
    );
  }

  // ============================================================
  // SECTION DROPDOWN
  // ============================================================

  Widget _sectionDropdown() {
    if (isLoadingSections) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Section',
          icon: Icons.groups_outlined,
          required: true,
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
              'Loading sections...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Section>(
      initialValue: selectedSection,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Section',
        icon: Icons.groups_outlined,
        required: true,
      ),

      items: sections.map((section) {
        return DropdownMenuItem<Section>(
          value: section,
          child: Text(
            section.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),

      onChanged:
          isSaving || selectedClass == null
              ? null
              : _onSectionChanged,

      validator: (value) {
        if (value == null) {
          return 'Section is required';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PARENT DROPDOWN
  // ============================================================

  Widget _parentDropdown() {
    return DropdownButtonFormField<Parent?>(
      initialValue: selectedParent,
      isExpanded: true,

      decoration: _inputDecoration(
        label: 'Parent',
        icon: Icons.family_restroom_outlined,
        required: false,
        hint: 'Select parent (optional)',
      ),

      items: [
        const DropdownMenuItem<Parent?>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 9),
              Text(
                'No Parent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        ...parents.map(
          (parent) {
            return DropdownMenuItem<Parent?>(
              value: parent,
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      parent.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],

      onChanged: isSaving
          ? null
          : _onParentChanged,
    );
  }

  // ============================================================
  // ACADEMIC INFORMATION SECTION
  // ============================================================

  Widget _academicInformationSection() {
    if (isLoadingAcademicData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading academic information...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (academicDataError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                academicDataError!,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      setState(() {
                        isLoadingAcademicData = true;
                        academicDataError = null;
                      });

                      _initializeServicesAndLoadData();
                    },
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _academicYearDropdown(),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns =
                constraints.maxWidth >= 560;

            if (!twoColumns) {
              return Column(
                children: [
                  _classDropdown(),
                  const SizedBox(height: 14),
                  _sectionDropdown(),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _classDropdown(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _sectionDropdown(),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        _parentDropdown(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final dialogWidth = screenWidth > 1000
        ? 800.0
        : screenWidth > 700
            ? 650.0
            : screenWidth * 0.94;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 900,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 35,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      22,
                      24,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildInfoBanner(),

                        const SizedBox(height: 20),

                        // PERSONAL
                        _sectionTitle(
                          'Personal Information',
                          Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder:
                              (context, constraints) {
                            final twoColumns =
                                constraints.maxWidth >= 560;

                            if (!twoColumns) {
                              return Column(
                                children: [
                                  _textField(
                                    controller:
                                        firstNameController,
                                    label: 'First Name',
                                    icon:
                                        Icons.person_outline,
                                    required: true,
                                  ),
                                  const SizedBox(height: 14),
                                  _textField(
                                    controller:
                                        lastNameController,
                                    label: 'Last Name',
                                    icon:
                                        Icons.person_outline,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller:
                                        firstNameController,
                                    label: 'First Name',
                                    icon:
                                        Icons.person_outline,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _textField(
                                    controller:
                                        lastNameController,
                                    label: 'Last Name',
                                    icon:
                                        Icons.person_outline,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder:
                              (context, constraints) {
                            final twoColumns =
                                constraints.maxWidth >= 560;

                            if (!twoColumns) {
                              return Column(
                                children: [
                                  _dateField(
                                    controller:
                                        dobController,
                                    label:
                                        'Date of Birth',
                                    icon:
                                        Icons.cake_outlined,
                                    required: true,
                                  ),
                                  const SizedBox(height: 14),
                                  _dropdownField(
                                    label: 'Gender',
                                    icon:
                                        Icons.wc_outlined,
                                    value:
                                        selectedGender,
                                    items: const [
                                      'Male',
                                      'Female',
                                      'Other',
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedGender =
                                              value;
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
                                    controller:
                                        dobController,
                                    label:
                                        'Date of Birth',
                                    icon:
                                        Icons.cake_outlined,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _dropdownField(
                                    label: 'Gender',
                                    icon:
                                        Icons.wc_outlined,
                                    value:
                                        selectedGender,
                                    items: const [
                                      'Male',
                                      'Female',
                                      'Other',
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedGender =
                                              value;
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
                          builder:
                              (context, constraints) {
                            final twoColumns =
                                constraints.maxWidth >= 560;

                            if (!twoColumns) {
                              return Column(
                                children: [
                                  _dropdownField(
                                    label:
                                        'Blood Group',
                                    icon:
                                        Icons.bloodtype_outlined,
                                    value:
                                        selectedBloodGroup,
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
                                          selectedBloodGroup =
                                              value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _textField(
                                    controller:
                                        admissionNoController,
                                    label:
                                        'Admission No',
                                    icon:
                                        Icons.badge_outlined,
                                    required: true,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _dropdownField(
                                    label:
                                        'Blood Group',
                                    icon:
                                        Icons.bloodtype_outlined,
                                    value:
                                        selectedBloodGroup,
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
                                          selectedBloodGroup =
                                              value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _textField(
                                    controller:
                                        admissionNoController,
                                    label:
                                        'Admission No',
                                    icon:
                                        Icons.badge_outlined,
                                    required: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // CONTACT
                        _sectionTitle(
                          'Contact Information',
                          Icons.contact_phone_outlined,
                        ),

                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder:
                              (context, constraints) {
                            final twoColumns =
                                constraints.maxWidth >= 560;

                            if (!twoColumns) {
                              return Column(
                                children: [
                                  _textField(
                                    controller:
                                        phoneController,
                                    label:
                                        'Mobile Number',
                                    icon:
                                        Icons.phone_rounded,
                                    keyboardType:
                                        TextInputType.phone,
                                    required: true,
                                    isPhone: true,
                                  ),
                                  const SizedBox(height: 14),
                                  _textField(
                                    controller:
                                        emailController,
                                    label: 'Email',
                                    icon:
                                        Icons.email_outlined,
                                    keyboardType:
                                        TextInputType
                                            .emailAddress,
                                    required: true,
                                    isEmail: true,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller:
                                        phoneController,
                                    label:
                                        'Mobile Number',
                                    icon:
                                        Icons.phone_rounded,
                                    keyboardType:
                                        TextInputType.phone,
                                    required: true,
                                    isPhone: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _textField(
                                    controller:
                                        emailController,
                                    label: 'Email',
                                    icon:
                                        Icons.email_outlined,
                                    keyboardType:
                                        TextInputType
                                            .emailAddress,
                                    required: true,
                                    isEmail: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // ACADEMIC
                        _sectionTitle(
                          'Academic Information',
                          Icons.school_outlined,
                        ),

                        const SizedBox(height: 14),

                        _academicInformationSection(),

                        const SizedBox(height: 14),

                        _dateField(
                          controller:
                              admissionDateController,
                          label: 'Admission Date',
                          icon:
                              Icons.event_outlined,
                          required: true,
                        ),

                        const SizedBox(height: 14),

                        _dropdownField(
                          label: 'Status',
                          icon:
                              Icons.toggle_on_outlined,
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

                        const SizedBox(height: 14),

                        // PARENT INFO
                        if (selectedParent != null)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF0FDF4),
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(0xFFDCFCE7),
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .family_restroom_rounded,
                                    color:
                                        Color(0xFF16A34A),
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'Parent Linked',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w800,
                                          color:
                                              Color(0xFF166534),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        selectedParent!
                                            .displayName,
                                        style:
                                            const TextStyle(
                                          fontSize: 13,
                                          color:
                                              Color(0xFF15803D),
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        18,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Update student information and academic details',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (!isSaving)
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: 'Close',
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO BANNER
  // ============================================================

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Fields marked with * are mandatory. '
              'Parent selection is optional.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.blue.shade900,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor:
                    const Color(0xFF374151),
                side: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed:
                  isSaving ? null : _updateStudent,
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(50),
                backgroundColor:
                    const Color(0xFF2563EB),
                disabledBackgroundColor:
                    const Color(0xFF93C5FD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 200),
                child: isSaving
                    ? const Row(
                        key: ValueKey('updating'),
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Updating...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        key: ValueKey('update'),
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Update Student',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}