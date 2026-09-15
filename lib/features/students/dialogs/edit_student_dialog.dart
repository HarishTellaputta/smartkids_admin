
import 'package:flutter/material.dart';
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
      _classService = ClassService(token);
      _sectionService = SectionService(token);
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

      final loadedAcademicYears =
          results[0] as List<AcademicYear>;

      final loadedClasses =
          results[1] as List<SchoolClass>;

      final loadedSections =
          results[2] as List<Section>;

      final loadedParents =
          results[3] as List<Parent>;

      AcademicYear? existingAcademicYear;

      for (final academicYear in loadedAcademicYears) {
        if (academicYear.id ==
            widget.student.academicYearId) {
          existingAcademicYear = academicYear;
          break;
        }
      }

      SchoolClass? existingClass;
      Section? existingSection;

      // Find existing Section
      for (final section in loadedSections) {
        if (section.id == widget.student.sectionId) {
          existingSection = section;
          break;
        }
      }

      // Section contains classId.
      // Therefore derive the existing Class from Section.
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

      // Load sections for existing class
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
  // LOAD SECTIONS BY CLASS
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sections: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ACADEMIC YEAR CHANGE
  // ============================================================

  void _onAcademicYearChanged(AcademicYear? value) {
    if (value == null) return;

    setState(() {
      selectedAcademicYear = value;
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
    });

    await _loadSectionsForClass(value.id!);
  }

  // ============================================================
  // SECTION CHANGE
  // ============================================================

  void _onSectionChanged(Section? value) {
    setState(() {
      selectedSection = value;
    });
  }

  // ============================================================
  // PARENT CHANGE
  // ============================================================

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
  // DATE FORMAT
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
      final parsed =
          DateTime.tryParse(controller.text.trim());

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.student.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student ID not found'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (selectedAcademicYear == null ||
        selectedAcademicYear!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Academic Year'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (selectedClass == null ||
        selectedClass!.id == null) {
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
      final firstName =
          firstNameController.text.trim();

      final lastName =
          lastNameController.text.trim();

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
        'admissionNo':
            _nullable(admissionNoController.text),

        'name': fullName,

        'email':
            _nullable(emailController.text),

        'phone':
            _nullable(phoneController.text),

        'dateOfBirth':
            _nullable(dobController.text),

        'gender': selectedGender,

        'bloodGroup': selectedBloodGroup,

        'admissionDate':
            _nullable(admissionDateController.text),

        'academicYearId':
            selectedAcademicYear!.id,

        'sectionId':
            selectedSection!.id,

        // Parent is optional.
        // null means no parent.
        'parentId':
            selectedParent?.id,

        'status':
            selectedStatus,

        /*
         * Keep existing values for fields which are not
         * currently editable in this dialog.
         *
         * These two fields are included because your
         * backend update method explicitly updates them.
         */
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
        'Parent selected: ${selectedParent != null}',
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
        const SnackBar(
          content: Text(
            'Student updated successfully',
          ),
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
          content: Text(
            'Failed to update student: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // NULLABLE
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
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
        ),
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
      initialValue: value,
      isExpanded: true,
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
      onChanged: isSaving
          ? null
          : onChanged,
    );
  }

  // ============================================================
  // ACADEMIC YEAR DROPDOWN
  // ============================================================

  Widget _academicYearDropdown() {
    return DropdownButtonFormField<AcademicYear>(
      initialValue: selectedAcademicYear,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Academic Year',
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
        ),
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
      items: academicYears.map((year) {
        return DropdownMenuItem<AcademicYear>(
          value: year,
          child: Text(
            year.name ?? 'Academic Year',
            overflow: TextOverflow.ellipsis,
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
      decoration: InputDecoration(
        labelText: 'Class',
        prefixIcon: const Icon(
          Icons.school_outlined,
        ),
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
        decoration: InputDecoration(
          labelText: 'Section',
          prefixIcon: const Icon(
            Icons.groups_outlined,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
            Text('Loading sections...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Section>(
      initialValue: selectedSection,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Section',
        prefixIcon: const Icon(
          Icons.groups_outlined,
        ),
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
      items: sections.map((section) {
        return DropdownMenuItem<Section>(
          value: section,
          child: Text(
            section.name,
            overflow: TextOverflow.ellipsis,
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
    /*
     * IMPORTANT FIX:
     *
     * The dropdown type is Parent? instead of Parent.
     * This allows the "No Parent" item to have a null value
     * without causing a type mismatch.
     */
    return DropdownButtonFormField<Parent?>(
      initialValue: selectedParent,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Parent',
        prefixIcon: const Icon(
          Icons.family_restroom_outlined,
        ),
        hintText: 'Select parent (optional)',
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
      items: [
        const DropdownMenuItem<Parent?>(
          value: null,
          child: Text('No Parent'),
        ),
        ...parents.map(
          (parent) {
            return DropdownMenuItem<Parent?>(
              value: parent,
              child: Text(
                parent.displayName,
                overflow: TextOverflow.ellipsis,
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
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
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.red.shade100,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                academicDataError!,
                style: TextStyle(
                  color: Colors.red.shade800,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final dialogWidth = screenWidth > 900
        ? 760.0
        : screenWidth > 600
            ? 600.0
            : screenWidth * 0.94;

    return AlertDialog(
      titlePadding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        8,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        8,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      // ========================================================
      // TITLE
      // ========================================================

      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_outlined,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Edit Student',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // CONTENT
      // ========================================================

      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ==================================================
                // PERSONAL INFORMATION
                // ==================================================

                _sectionTitle(
                  'Personal Information',
                  Icons.person_outline,
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
                            label: 'Phone',
                            icon:
                                Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
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
                            label: 'Phone',
                            icon:
                                Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
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

                const SizedBox(height: 16),

                // ==================================================
                // SELECTED PARENT INFO
                // ==================================================

                if (selectedParent != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            Colors.green.shade100,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.family_restroom,
                          color:
                              Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Selected Parent: ${selectedParent!.displayName}',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.green.shade800,
                              fontWeight:
                                  FontWeight.w500,
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

      // ========================================================
      // ACTIONS
      // ========================================================

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
          onPressed:
              isSaving ? null : _updateStudent,
          icon: isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_outlined,
                  size: 18,
                ),
          label: Text(
            isSaving
                ? 'Updating...'
                : 'Update Student',
          ),
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8),
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
