import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/parent_model.dart';
import 'package:smartkids_admin/services/parent_service.dart';
import 'package:smartkids_admin/services/student_service.dart';
import 'package:smartkids_admin/features/parents/parent_details_screen.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  ParentService? _parentService;

  final TextEditingController _searchController = TextEditingController();

  List<Parent> _parents = [];
  List<Parent> _filteredParents = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String _selectedRelationship = 'All';
  String? _errorMessage;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _secondary = Color(0xFF7C3AED);
  static const Color _background = Color(0xFFF6F7FB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

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

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Session expired. Please login again.';
        _isLoading = false;
      });

      return;
    }

    _parentService = ParentService(token);

    await _loadParents();
  }

  Future<void> _loadParents() async {
    if (_parentService == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final parents = await _parentService!.getParents();
      final filtered = _filterParents(parents);

      if (!mounted) return;

      setState(() {
        _parents = parents;
        _filteredParents = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Parent> _filterParents(List<Parent> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((parent) {
      final matchesSearch =
          query.isEmpty ||
          parent.displayName.toLowerCase().contains(query) ||
          (parent.fatherName ?? '').toLowerCase().contains(query) ||
          (parent.motherName ?? '').toLowerCase().contains(query) ||
          (parent.guardianName ?? '').toLowerCase().contains(query) ||
          (parent.contactPhone ?? '').toLowerCase().contains(query) ||
          (parent.contactEmail ?? '').toLowerCase().contains(query) ||
          (parent.address ?? '').toLowerCase().contains(query) ||
          (parent.id?.toString() ?? '').contains(query);

      final matchesRelationship =
          _selectedRelationship == 'All' ||
          (parent.relationship ?? '').toLowerCase() ==
              _selectedRelationship.toLowerCase();

      return matchesSearch && matchesRelationship;
    }).toList();
  }

  void _applyFilters() {
    final filtered = _filterParents(_parents);

    if (!mounted) return;

    setState(() {
      _filteredParents = filtered;
    });
  }

  int get _fatherCount {
    return _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'father')
        .length;
  }

  int get _motherCount {
    return _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'mother')
        .length;
  }

  int get _guardianCount {
    return _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'guardian')
        .length;
  }

  Future<void> _showParentDetails(Parent parent) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ParentDetailsScreen(parent: parent)),
    );

    if (mounted) {
      await _loadParents();
    }
  }

  Future<void> _showAddParentDialog() async {
    final result = await _parentFormDialog();

    if (result == null || _parentService == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _parentService!.createParent(
        fatherName: result['fatherName'],
        motherName: result['motherName'],
        guardianName: result['guardianName'],
        contactPhone: result['contactPhone'],
        contactEmail: result['contactEmail'],
        relationship: result['relationship'],
        address: result['address'],
      );

      if (!mounted) return;

      _showSuccess('Parent added successfully.');
      await _loadParents();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showEditParentDialog(Parent parent) async {
    if (parent.id == null || _parentService == null) return;

    final result = await _parentFormDialog(parent: parent);

    if (result == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _parentService!.updateParent(
        id: parent.id!,
        fatherName: result['fatherName'],
        motherName: result['motherName'],
        guardianName: result['guardianName'],
        contactPhone: result['contactPhone'],
        contactEmail: result['contactEmail'],
        relationship: result['relationship'],
        address: result['address'],
      );

      if (!mounted) return;

      _showSuccess('Parent updated successfully.');
      await _loadParents();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteParent(Parent parent) async {
    if (parent.id == null || _parentService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Parent?',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete ${parent.displayName}?',
            style: const TextStyle(color: _textSecondary, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _parentService!.deleteParent(parent.id!);

      if (!mounted) return;

      _showSuccess('Parent deleted successfully.');
      await _loadParents();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _showLinkStudentDialog(Parent parent) async {
    if (parent.id == null || _parentService == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      _showError('Session expired. Please login again.');
      return;
    }

    try {
      final studentService = StudentService(token);

      final studentPage = await studentService.getStudents(page: 0, size: 100);

      final availableStudents = studentPage.content.where((student) {
        return student.id != null && student.parentId == null;
      }).toList();

      if (!mounted) return;

      if (availableStudents.isEmpty) {
        _showError('No unlinked students available.');
        return;
      }

      int? selectedStudentId;

      final selected = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),

                title: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _secondary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.link_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link Student',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Connect a student to this parent',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9E5FF)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: _primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Parent',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  parent.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Select Student',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
                      initialValue: selectedStudentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Choose a student',
                        prefixIcon: const Icon(
                          Icons.school_rounded,
                          color: _primary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                      items: availableStudents.map((student) {
                        return DropdownMenuItem<int>(
                          value: student.id,
                          child: Text(
                            '${student.name ?? 'Student'}'
                            '${student.admissionNo != null ? ' • ${student.admissionNo}' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStudentId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${availableStudents.length} student${availableStudents.length == 1 ? '' : 's'} available',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedStudentId == null
                        ? null
                        : () => Navigator.pop(dialogContext, selectedStudentId),
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text(
                      'Link Student',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected == null) return;

      await _parentService!.linkStudent(
        parentId: parent.id!,
        studentId: selected,
      );

      if (!mounted) return;

      _showSuccess('Student linked successfully.');
      await _loadParents();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _unlinkStudent(Parent parent, ParentStudent student) async {
    if (parent.id == null || student.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Unlink Student?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Remove ${student.name} from ${parent.displayName}?',
            style: const TextStyle(color: _textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _parentService!.unlinkStudent(
        parentId: parent.id!,
        studentId: student.id!,
      );

      if (!mounted) return;

      _showSuccess('Student unlinked successfully.');
      await _loadParents();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _showFilterDialog() async {
    String selected = _selectedRelationship;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final relationships = ['All', 'Father', 'Mother', 'Guardian'];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Filter Parents',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: relationships.map((relationship) {
                  final isSelected = selected == relationship;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setDialogState(() {
                        selected = relationship;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary.withOpacity(.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _primary : _border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected ? _primary : _textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            relationship,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? _primary : _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'All'),
                  child: const Text('Reset'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, selected),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedRelationship = result;
    });

    _applyFilters();
  }

  Future<Map<String, dynamic>?> _parentFormDialog({Parent? parent}) async {
    final fatherController = TextEditingController(
      text: parent?.fatherName ?? '',
    );
    final motherController = TextEditingController(
      text: parent?.motherName ?? '',
    );
    final guardianController = TextEditingController(
      text: parent?.guardianName ?? '',
    );
    final phoneController = TextEditingController(
      text: parent?.contactPhone ?? '',
    );
    final emailController = TextEditingController(
      text: parent?.contactEmail ?? '',
    );
    final addressController = TextEditingController(
      text: parent?.address ?? '',
    );

    String relationship = parent?.relationship ?? 'Father';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.12),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            parent == null
                                ? Icons.person_add_alt_1_rounded
                                : Icons.edit_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parent == null
                                    ? 'Add New Parent'
                                    : 'Edit Parent',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                parent == null
                                    ? 'Create a parent profile'
                                    : 'Update parent information',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.78),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              'Parent Information',
                              Icons.family_restroom_rounded,
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final twoColumn = constraints.maxWidth >= 560;

                                if (twoColumn) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _textField(
                                              controller: fatherController,
                                              label: 'Father Name',
                                              icon: Icons.person_rounded,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: _textField(
                                              controller: motherController,
                                              label: 'Mother Name',
                                              icon: Icons.person_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _textField(
                                              controller: guardianController,
                                              label: 'Guardian Name',
                                              icon: Icons
                                                  .admin_panel_settings_rounded,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: _dropdownField(
                                              value: relationship,
                                              label: 'Relationship',
                                              icon:
                                                  Icons.family_restroom_rounded,
                                              items: const [
                                                'Father',
                                                'Mother',
                                                'Guardian',
                                              ],
                                              onChanged: (value) {
                                                if (value != null) {
                                                  relationship = value;
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    _textField(
                                      controller: fatherController,
                                      label: 'Father Name',
                                      icon: Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 14),
                                    _textField(
                                      controller: motherController,
                                      label: 'Mother Name',
                                      icon: Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 14),
                                    _textField(
                                      controller: guardianController,
                                      label: 'Guardian Name',
                                      icon: Icons.admin_panel_settings_rounded,
                                    ),
                                    const SizedBox(height: 14),
                                    _dropdownField(
                                      value: relationship,
                                      label: 'Relationship',
                                      icon: Icons.family_restroom_rounded,
                                      items: const [
                                        'Father',
                                        'Mother',
                                        'Guardian',
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          relationship = value;
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 26),
                            _sectionTitle(
                              'Contact Information',
                              Icons.contact_phone_rounded,
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final twoColumn = constraints.maxWidth >= 560;

                                if (twoColumn) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _textField(
                                          controller: phoneController,
                                          label: 'Phone Number',
                                          icon: Icons.phone_rounded,
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _textField(
                                          controller: emailController,
                                          label: 'Email Address',
                                          icon: Icons.email_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    _textField(
                                      controller: phoneController,
                                      label: 'Phone Number',
                                      icon: Icons.phone_rounded,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 14),
                                    _textField(
                                      controller: emailController,
                                      label: 'Email Address',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: addressController,
                              label: 'Address',
                              icon: Icons.location_on_rounded,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFC),
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            Navigator.pop(dialogContext, {
                              'fatherName': _nullableValue(
                                fatherController.text,
                              ),
                              'motherName': _nullableValue(
                                motherController.text,
                              ),
                              'guardianName': _nullableValue(
                                guardianController.text,
                              ),
                              'contactPhone': _nullableValue(
                                phoneController.text,
                              ),
                              'contactEmail': _nullableValue(
                                emailController.text,
                              ),
                              'relationship': relationship,
                              'address': _nullableValue(addressController.text),
                            });
                          },
                          icon: Icon(
                            parent == null
                                ? Icons.add_rounded
                                : Icons.save_rounded,
                            size: 18,
                          ),
                          label: Text(
                            parent == null ? 'Add Parent' : 'Save Changes',
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
      },
    );

    fatherController.dispose();
    motherController.dispose();
    guardianController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();

    return result;
  }

  String? _nullableValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (label == 'Phone Number' &&
            value != null &&
            value.trim().isNotEmpty &&
            value.trim().length < 10) {
          return 'Enter a valid phone number';
        }

        if (label == 'Email Address' &&
            value != null &&
            value.trim().isNotEmpty &&
            !value.contains('@')) {
          return 'Enter a valid email';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 34 : 0),
          child: Icon(icon, size: 20),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parents',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage parent profiles, contacts and student connections',
                  style: TextStyle(color: _textSecondary, fontSize: 13.5),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _showAddParentDialog,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(_primary),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text(
              'Add Parent',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryData(
            title: 'Total Parents',
            value: _parents.length.toString(),
            icon: Icons.groups_rounded,
            description: 'Registered profiles',
          ),
          _SummaryData(
            title: 'Fathers',
            value: _fatherCount.toString(),
            icon: Icons.man_rounded,
            description: 'Father profiles',
          ),
          _SummaryData(
            title: 'Mothers',
            value: _motherCount.toString(),
            icon: Icons.woman_rounded,
            description: 'Mother profiles',
          ),
          _SummaryData(
            title: 'Guardians',
            value: _guardianCount.toString(),
            icon: Icons.admin_panel_settings_rounded,
            description: 'Guardian profiles',
          ),
        ];

        if (constraints.maxWidth < 700) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              return _summaryCard(cards[index]);
            },
          );
        }

        return Row(
          children: cards.map((card) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: card == cards.last ? 0 : 12),
                child: _summaryCard(card),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(data.icon, color: _primary, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  data.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1, color: _border),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                ? _buildError()
                : _filteredParents.isEmpty
                ? _buildEmpty()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 850) {
                        return _buildMobileList();
                      }

                      return _buildDesktopTable();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterButton()),
                    const SizedBox(width: 10),
                    _buildRefreshButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              _buildFilterButton(),
              const SizedBox(width: 10),
              _buildRefreshButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search parent, phone, email or address...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final active = _selectedRelationship != 'All';

    return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: active ? _primary.withOpacity(.06) : Colors.white,
        side: BorderSide(color: active ? _primary : _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(
        Icons.filter_list_rounded,
        size: 19,
        color: active ? _primary : _textSecondary,
      ),
      label: Text(
        active ? _selectedRelationship : 'Filter',
        style: TextStyle(
          color: active ? _primary : _textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Refresh',
      child: IconButton(
        onPressed: _isLoading ? null : _loadParents,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FC),
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.all(13),
        ),
        icon: const Icon(Icons.refresh_rounded, color: _textPrimary),
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 82,
          columnSpacing: 28,
          horizontalMargin: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textSecondary,
            letterSpacing: .5,
          ),
          columns: const [
            DataColumn(label: Text('PARENT')),
            DataColumn(label: Text('RELATIONSHIP')),
            DataColumn(label: Text('PHONE')),
            DataColumn(label: Text('EMAIL')),
            DataColumn(label: Text('STUDENTS')),
            DataColumn(label: Text('ACTION')),
          ],
          rows: _filteredParents.map((parent) {
            return DataRow(
              onSelectChanged: (_) => _showParentDetails(parent),
              cells: [
                DataCell(_parentNameCell(parent)),
                DataCell(_relationshipBadge(parent.relationship)),
                DataCell(
                  Text(
                    parent.contactPhone?.isNotEmpty == true
                        ? parent.contactPhone!
                        : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 190,
                    child: Text(
                      parent.contactEmail?.isNotEmpty == true
                          ? parent.contactEmail!
                          : '—',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(_studentCount(parent)),
                DataCell(_actionMenu(parent)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _parentNameCell(Parent parent) {
    final initials = parent.initials.trim().isNotEmpty
        ? parent.initials
        : _getInitials(parent.displayName);

    return SizedBox(
      width: 230,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(.12),
                  _secondary.withOpacity(.12),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              parent.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCount(Parent parent) {
    final count = parent.students.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: count > 0
            ? Colors.green.withOpacity(.08)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_rounded,
            size: 15,
            color: count > 0 ? Colors.green.shade700 : _textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            count == 1 ? '1 Student' : '$count Students',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: count > 0 ? Colors.green.shade700 : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _relationshipBadge(String? relationship) {
    final value = relationship?.trim().isNotEmpty == true
        ? relationship!.trim()
        : 'Parent';

    IconData icon;

    switch (value.toLowerCase()) {
      case 'father':
        icon = Icons.man_rounded;
        break;
      case 'mother':
        icon = Icons.woman_rounded;
        break;
      case 'guardian':
        icon = Icons.admin_panel_settings_rounded;
        break;
      default:
        icon = Icons.family_restroom_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionMenu(Parent parent) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showParentDetails(parent);
            break;
          case 'edit':
            _showEditParentDialog(parent);
            break;
          case 'link':
            _showLinkStudentDialog(parent);
            break;
          case 'delete':
            _deleteParent(parent);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'view',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.visibility_rounded),
              title: Text('View Details'),
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_rounded),
              title: Text('Edit Parent'),
            ),
          ),
          const PopupMenuItem(
            value: 'link',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link_rounded),
              title: Text('Link Student'),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ];
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _border),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: _textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _filteredParents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final parent = _filteredParents[index];
        return _parentMobileCard(parent);
      },
    );
  }

  Widget _parentMobileCard(Parent parent) {
    final initials = parent.initials.trim().isNotEmpty
        ? parent.initials
        : _getInitials(parent.displayName);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showParentDetails(parent),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withOpacity(.12),
                        _secondary.withOpacity(.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _relationshipBadge(parent.relationship),
                    ],
                  ),
                ),
                _actionMenu(parent),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _mobileInfo(
                    Icons.phone_rounded,
                    parent.contactPhone?.isNotEmpty == true
                        ? parent.contactPhone!
                        : 'No phone',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mobileInfo(
                    Icons.school_rounded,
                    parent.students.isEmpty
                        ? 'No students'
                        : '${parent.students.length} student${parent.students.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
            if (parent.contactEmail?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _mobileInfo(Icons.email_rounded, parent.contactEmail!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mobileInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.8, color: _primary),
          ),
          SizedBox(height: 14),
          Text(
            'Loading parents...',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: Colors.red.shade600,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load parents',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadParents,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final hasFilters =
        _searchController.text.trim().isNotEmpty ||
        _selectedRelationship != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: _primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? 'No parents found' : 'No parents yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasFilters
                  ? 'Try changing your search or filter.'
                  : 'Add your first parent profile to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedRelationship = 'All';
                  });
                  _applyFilters();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
              )
            else
              FilledButton.icon(
                onPressed: _showAddParentDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Parent'),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF166534),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB91C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1200
                ? 28.0
                : constraints.maxWidth >= 700
                ? 20.0
                : 14.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    18,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildSummaryCards(),
                      const SizedBox(height: 18),
                      Expanded(child: _buildMainContent()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final String description;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
  });
}
