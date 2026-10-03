import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:smartkids_admin/models/academic_year_model.dart';
import 'package:smartkids_admin/models/parent_model.dart';
import 'package:smartkids_admin/models/section_model.dart';

import 'package:smartkids_admin/services/student_service.dart';
import 'package:smartkids_admin/services/academic_year_service.dart';
import 'package:smartkids_admin/services/section_service.dart';
import 'package:smartkids_admin/services/parent_service.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/features/teachers/models/class_model.dart';

import 'package:smartkids_admin/core/network/api_client.dart';

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
  ApiClient apiClient = ApiClient();

  final _formKey = GlobalKey<FormState>();

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
  bool isLoadingDropdowns = true;
  bool isLoadingSections = false;

  String? dropdownError;

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
    _initializeServicesAndLoadData();
  }

  @override
  void dispose() {
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
          isLoadingDropdowns = false;
          dropdownError = 'Login session expired. Please login again.';
        });

        return;
      }

      _academicYearService = AcademicYearService(token);
      _classService = ClassService(apiClient);
      _sectionService = SectionService(apiClient);
      _parentService = ParentService(token);

      await _loadDropdownData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDropdowns = false;
        dropdownError = 'Failed to initialize dropdowns: $e';
      });
    }
  }

  // ============================================================
  // LOAD DROPDOWN DATA
  // ============================================================

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait([
        _academicYearService.getAcademicYears(),
        _classService.getClasses(),
        _parentService.getParents(),
      ]);

      final loadedAcademicYears = results[0] as List<AcademicYear>;
      final loadedClasses = results[1] as List<SchoolClass>;
      final loadedParents = results[2] as List<Parent>;

      if (!mounted) return;

      setState(() {
        academicYears = loadedAcademicYears;
        classes = loadedClasses;
        parents = loadedParents;
        isLoadingDropdowns = false;
        dropdownError = null;
      });

      // Automatically select current academic year if available.
      AcademicYear? currentYear;

      for (final year in loadedAcademicYears) {
        if (year.current == true) {
          currentYear = year;
          break;
        }
      }

      if (currentYear != null && mounted) {
        setState(() {
          selectedAcademicYear = currentYear;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDropdowns = false;
        dropdownError = 'Failed to load academic information: $e';
      });
    }
  }

  // ============================================================
  // ACADEMIC YEAR CHANGE
  // ============================================================

  void _onAcademicYearChanged(AcademicYear? value) {
    if (value == null) return;

    setState(() {
      selectedAcademicYear = value;

      // Class/Section must be selected again after
      // changing the academic year.
      selectedClass = null;
      selectedSection = null;
      sections = [];
    });
  }

  // ============================================================
  // CLASS CHANGE
  // ============================================================

  Future<void> _onClassChanged(SchoolClass? value) async {
    if (value == null || value.id == null) return;

    setState(() {
      selectedClass = value;
      selectedSection = null;
      sections = [];
      isLoadingSections = true;
    });

    try {
      final loadedSections = await _sectionService.getSectionsByClassId(
        value.id!,
      );

      if (!mounted) return;

      setState(() {
        sections = loadedSections;
        isLoadingSections = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSections = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sections: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    if (selectedAcademicYear == null || selectedAcademicYear!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Academic Year'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedClass == null || selectedClass!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Section'),
          backgroundColor: Colors.red,
        ),
      );
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

      // ========================================================
      // IMPORTANT:
      // Admission number is NOT sent from frontend.
      // Backend will generate it automatically.
      // ========================================================

      final data = <String, dynamic>{
        'name': fullName,
        'email': _nullable(emailController.text),
        'phone': _nullable(phoneController.text),
        'dateOfBirth': _nullable(dobController.text),
        'gender': selectedGender,
        'bloodGroup': selectedBloodGroup,
        'admissionDate': _nullable(admissionDateController.text),

        // Academic relationship
        'academicYearId': selectedAcademicYear!.id,
        'sectionId': selectedSection!.id,

        // Parent is optional
        'parentId': selectedParent?.id,

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
    bool isPhone = false,
    bool isEmail = false,
  }) {
    final isRequired = required || isPhone || isEmail;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      enabled: !isSaving,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        counterText: isPhone ? '' : null,

        prefixIcon: Container(
          margin: const EdgeInsets.all(7),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),

        filled: true,
        fillColor: const Color(0xFFF8FAFC),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),

        floatingLabelStyle: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      validator: (value) {
        final text = value?.trim() ?? '';

        // Required validation
        if (isRequired && text.isEmpty) {
          return '$label is required';
        }

        // Phone validation
        if (isPhone) {
          if (!RegExp(r'^[0-9]{10}$').hasMatch(text)) {
            return 'Enter a valid 10-digit mobile number';
          }

          if (RegExp(r'^(\d)\1{9}$').hasMatch(text)) {
            return 'Enter a valid mobile number';
          }

          if (!RegExp(r'^[6-9]').hasMatch(text)) {
            return 'Mobile number must start with 6, 7, 8 or 9';
          }
        }

        // Email validation
        if (isEmail) {
          final emailRegex = RegExp(
            r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@'
            r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}'
            r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]'
            r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
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
        labelText: required ? '$label *' : label,

        prefixIcon: Container(
          margin: const EdgeInsets.all(7),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),

        suffixIcon: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            size: 19,
            color: Colors.blue.shade700,
          ),
        ),

        filled: true,
        fillColor: const Color(0xFFF8FAFC),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      onTap: () {
        _selectDate(controller: controller);
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
  // STRING DROPDOWN
  // ============================================================

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,

      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),

      dropdownColor: Colors.white,
      menuMaxHeight: 280,

      decoration: _premiumDropdownDecoration(label: '$label *', icon: icon),

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getDropdownIcon(item),
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: isSaving ? null : onChanged,

      validator: (selectedValue) {
        if (selectedValue == null || selectedValue.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
    );
  }

  IconData _getDropdownIcon(String value) {
    switch (value) {
      case 'Male':
        return Icons.male_rounded;
      case 'Female':
        return Icons.female_rounded;
      case 'Other':
        return Icons.person_outline_rounded;

      case 'A+':
      case 'A-':
      case 'B+':
      case 'B-':
      case 'AB+':
      case 'AB-':
      case 'O+':
      case 'O-':
        return Icons.bloodtype_rounded;

      case 'ACTIVE':
        return Icons.check_circle_outline_rounded;

      case 'INACTIVE':
        return Icons.pause_circle_outline_rounded;

      default:
        return Icons.check_rounded;
    }
  } // ============================================================
  // ACADEMIC YEAR DROPDOWN
  // ============================================================

  Widget _academicYearDropdown() {
    return DropdownButtonFormField<AcademicYear>(
      initialValue: selectedAcademicYear,
      isExpanded: true,

      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),

      dropdownColor: Colors.white,
      menuMaxHeight: 300,

      decoration: _premiumDropdownDecoration(
        label: 'Academic Year',
        icon: Icons.calendar_month_rounded,
      ),

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),

      items: academicYears.map((year) {
        final isCurrent = year.current == true;

        return DropdownMenuItem<AcademicYear>(
          value: year,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  year.name ?? 'Academic Year',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              if (isCurrent) ...[
                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    'CURRENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),

      onChanged: isSaving ? null : _onAcademicYearChanged,

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

      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),

      dropdownColor: Colors.white,
      menuMaxHeight: 320,

      decoration: _premiumDropdownDecoration(
        label: 'Class',
        icon: Icons.school_rounded,
        hintText: 'Select class',
      ),

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),

      items: classes.map((schoolClass) {
        final displayName =
            schoolClass.name ??
            schoolClass.grade ??
            schoolClass.code ??
            'Class';

        return DropdownMenuItem<SchoolClass>(
          value: schoolClass,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.class_rounded,
                  size: 17,
                  color: Colors.indigo.shade600,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: isSaving || selectedAcademicYear == null
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
        decoration: _premiumDropdownDecoration(
          label: 'Section',
          icon: Icons.groups_rounded,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading sections...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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

      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),

      dropdownColor: Colors.white,
      menuMaxHeight: 280,

      decoration: _premiumDropdownDecoration(
        label: 'Section',
        icon: Icons.groups_rounded,
        hintText: 'Select section',
      ),

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),

      items: sections.map((section) {
        return DropdownMenuItem<Section>(
          value: section,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  section.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Section ${section.name}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: isSaving || selectedClass == null
          ? null
          : (value) {
              setState(() {
                selectedSection = value;
              });
            },

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
    return DropdownButtonFormField<Parent>(
      initialValue: selectedParent,
      isExpanded: true,

      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),

      dropdownColor: Colors.white,
      menuMaxHeight: 320,

      decoration: _premiumDropdownDecoration(
        label: 'Parent',
        icon: Icons.family_restroom_rounded,
        hintText: 'Select parent (optional)',
      ),

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),

      items: [
        const DropdownMenuItem<Parent>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.person_off_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                'No Parent',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        ...parents.map((parent) {
          return DropdownMenuItem<Parent>(
            value: parent,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    parent.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],

      onChanged: isSaving
          ? null
          : (value) {
              setState(() {
                selectedParent = value;
              });
            },
    );
  }
  // ============================================================
  // BUILD ACADEMIC DROPDOWNS
  // ============================================================

  Widget _academicDropdownSection() {
    if (isLoadingDropdowns) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading academic information...'),
          ],
        ),
      );
    }

    if (dropdownError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dropdownError!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      setState(() {
                        isLoadingDropdowns = true;
                        dropdownError = null;
                      });

                      _initializeServicesAndLoadData();
                    },
              child: const Text('Retry'),
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
            final twoColumns = constraints.maxWidth >= 560;

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
                Expanded(child: _classDropdown()),
                const SizedBox(width: 14),
                Expanded(child: _sectionDropdown()),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_alt_1, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add Student',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
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

                // ==================================================
                // PERSONAL INFORMATION
                // ==================================================
                _sectionTitle('Personal Information', Icons.person_outline),

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
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _dropdownField(
                            label: 'Gender',
                            icon: Icons.wc_outlined,
                            value: selectedGender,
                            items: const ['Male', 'Female', 'Other'],
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
                            items: const ['Male', 'Female', 'Other'],
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

                // ==================================================
                // BLOOD GROUP
                // ==================================================
                _dropdownField(
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

                // ==================================================
                // CONTACT INFORMATION
                // ==================================================
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
                            label: 'Mobile Number',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            required: true,
                            isPhone: true,
                            hint: '10-digit mobile number',
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            required: true,
                            isEmail: true,
                            hint: 'student@example.com',
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

                // ==================================================
                // ACADEMIC INFORMATION
                // ==================================================
                const SizedBox(height: 24),

                _sectionTitle('Academic Information', Icons.school_outlined),

                const SizedBox(height: 14),

                _academicDropdownSection(),

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
                  items: const ['ACTIVE', 'INACTIVE'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PARENT NOTE
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
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
                          selectedParent == null
                              ? 'Parent selection is optional. You can link a parent later from the Parents section.'
                              : 'Selected parent: ${selectedParent!.displayName}',
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
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(isSaving ? 'Saving...' : 'Save Student'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.blue.shade700),
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

  InputDecoration _premiumDropdownDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      prefixIcon: Container(
        margin: const EdgeInsets.all(7),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.blue.shade700),
      ),

      filled: true,
      fillColor: const Color(0xFFF8FAFC),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),

      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      floatingLabelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
