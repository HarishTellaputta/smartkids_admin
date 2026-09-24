import 'package:flutter/material.dart';

import 'package:smartkids_admin/features/fees/models/fee_model.dart';
import 'package:smartkids_admin/features/fees/models/fee_dashboard_summary_model.dart';
import 'package:smartkids_admin/features/fees/services/fee_service.dart';
import 'package:smartkids_admin/features/fees/fee_details_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/section_model.dart';
import '../../models/student_model.dart';

import '../teachers/services/class_service.dart';
import '../teachers/models/class_model.dart';
import '../../services/section_service.dart';
import '../../services/student_service.dart';

import 'fee_details_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final FeeService _feeService = FeeService();

  final TextEditingController searchController = TextEditingController();

  List<StudentFeeModel> feeRecords = [];
  List<SchoolClass> classes = [];
  List<Section> sections = [];
  List<Student> students = [];

  FeeDashboardSummaryModel? dashboardSummary;

  bool isLoading = true;
  bool isSummaryLoading = true;
  bool isFilterLoading = false;

  String? errorMessage;

  String searchQuery = '';
  String selectedStatus = 'All';

  int? selectedClassId;
  int? selectedSectionId;

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });

    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      isSummaryLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final classService = ClassService(token);
      final studentService = StudentService(token);

      final results = await Future.wait([
        _feeService.getPendingFees(),
        _feeService.getDashboardSummary(),
        classService.getClasses(),
        studentService.getStudents(
          page: 0,
          size: 1000,
          sortBy: 'id',
          sortDirection: 'asc',
        ),
      ]);

      if (!mounted) return;

      final studentPage = results[3] as StudentPage;

      setState(() {
        feeRecords = results[0] as List<StudentFeeModel>;
        dashboardSummary =
            results[1] as FeeDashboardSummaryModel;
        classes = results[2] as List<SchoolClass>;
        students = studentPage.content;

        isLoading = false;
        isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isSummaryLoading = false;
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _loadSections(int classId) async {
    setState(() {
      isFilterLoading = true;
      selectedSectionId = null;
      sections = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final service = SectionService(token);
      final result = await service.getSectionsByClassId(classId);

      if (!mounted) return;

      setState(() {
        sections = result;
        isFilterLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isFilterLoading = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  List<StudentFeeModel> get filteredRecords {
    return feeRecords.where((record) {
      final student = students.cast<Student?>().firstWhere(
            (s) => s?.id == record.studentId,
            orElse: () => null,
          );

      final matchesSearch =
          searchQuery.isEmpty ||
          record.studentName.toLowerCase().contains(searchQuery) ||
          (record.studentId?.toString() ?? '')
              .contains(searchQuery) ||
          record.feeName.toLowerCase().contains(searchQuery) ||
          (student?.admissionNo ?? '')
              .toLowerCase()
              .contains(searchQuery);

      final matchesClass = selectedClassId == null ||
          student?.sectionId == null ||
          _sectionBelongsToClass(
            student!.sectionId!,
            selectedClassId!,
          );

      final matchesSection = selectedSectionId == null ||
          student?.sectionId == selectedSectionId;

      final status = _displayStatus(record);

      final matchesStatus =
          selectedStatus == 'All' ||
          status == selectedStatus;

      return matchesSearch &&
          matchesClass &&
          matchesSection &&
          matchesStatus;
    }).toList();
  }

  bool _sectionBelongsToClass(
    int sectionId,
    int classId,
  ) {
    final section = _findSectionById(sectionId);

    if (section == null) {
      return false;
    }

    return section.classId == classId;
  }

  Section? _findSectionById(int id) {
    for (final section in sections) {
      if (section.id == id) {
        return section;
      }
    }

    // When a class is not selected, sections may not be loaded.
    // Use student's current section information as fallback.
    return null;
  }

  String _displayStatus(StudentFeeModel record) {
    if (record.pendingAmount <= 0) {
      return 'PAID';
    }

    if (record.paidAmount > 0) {
      return 'PARTIAL';
    }

    return 'PENDING';
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '-';

    try {
      final d = DateTime.parse(date);

      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${d.day.toString().padLeft(2, '0')} '
          '${months[d.month]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  Student? _studentForFee(StudentFeeModel record) {
    for (final student in students) {
      if (student.id == record.studentId) {
        return student;
      }
    }

    return null;
  }

  String _classNameForFee(StudentFeeModel record) {
    final student = _studentForFee(record);

    if (student == null || student.sectionId == null) {
      return '-';
    }

    final section = _findSectionFromAllClasses(
      student.sectionId!,
    );

    if (section != null && section.className != null) {
      return section.className!;
    }

    if (selectedClassId != null) {
      for (final c in classes) {
        if (c.id == selectedClassId) {
          return c.name ?? c.grade ?? '-';
        }
      }
    }

    return '-';
  }

  Section? _findSectionFromAllClasses(int sectionId) {
    for (final section in sections) {
      if (section.id == sectionId) {
        return section;
      }
    }

    return null;
  }

  Future<void> _openFeeDetails(
    StudentFeeModel record,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FeeDetailsScreen(
          record: record,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showAddPaymentDialog(
    StudentFeeModel record,
  ) async {
    final amountController = TextEditingController();
    final remarksController = TextEditingController();

    String paymentMethod = 'CASH';
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collect Payment',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        record.studentName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Outstanding',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              _formatCurrency(
                                record.pendingAmount,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CASH',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'UPI',
                            child: Text('UPI'),
                          ),
                          DropdownMenuItem(
                            value: 'BANK_TRANSFER',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'CARD',
                            child: Text('Card'),
                          ),
                          DropdownMenuItem(
                            value: 'CHEQUE',
                            child: Text('Cheque'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    paymentMethod = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final amount =
                                      double.tryParse(
                                    amountController.text
                                        .trim(),
                                  );

                                  if (amount == null ||
                                      amount <= 0) {
                                    _showMessage(
                                      'Enter a valid amount.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (amount >
                                      record.pendingAmount) {
                                    _showMessage(
                                      'Amount exceeds pending fee.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    saving = true;
                                  });

                                  try {
                                    await _feeService
                                        .recordPayment(
                                      studentFeeId:
                                          record.id!,
                                      amount: amount,
                                      paymentMethod:
                                          paymentMethod,
                                      remarks:
                                          remarksController
                                              .text
                                              .trim(),
                                    );

                                    if (!mounted) return;

                                    Navigator.pop(
                                      dialogContext,
                                      true,
                                    );
                                  } catch (e) {
                                    setDialogState(() {
                                      saving = false;
                                    });

                                    _showMessage(
                                      e.toString()
                                          .replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                      isError: true,
                                    );
                                  }
                                },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Record Payment',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    remarksController.dispose();

    if (result == true && mounted) {
      await _loadData();
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = filteredRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildPremiumSummary(),
                  const SizedBox(height: 22),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  _buildFeeTable(records),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Fees & Payments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage student fees and payment collection',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey.shade500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: isLoading ? null : _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildPremiumSummary() {
    final summary = dashboardSummary;

    final total = summary?.totalFee ?? 0;
    final collected = summary?.collected ?? 0;
    final outstanding = summary?.pending ?? 0;
    final percentage =
        summary?.collectionPercentage ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 720;

        final cards = [
          _summaryItem(
            title: 'Total Fee',
            value: _formatCurrency(total),
            subtitle: 'Overall assigned',
            icon: Icons.account_balance_wallet_outlined,
            iconBackground: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
          ),
          _summaryItem(
            title: 'Collected',
            value: _formatCurrency(collected),
            subtitle: 'Total received',
            icon: Icons.payments_outlined,
            iconBackground: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
          ),
          _summaryItem(
            title: 'Outstanding',
            value: _formatCurrency(outstanding),
            subtitle: 'Amount remaining',
            icon: Icons.pending_actions_outlined,
            iconBackground: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFDC2626),
          ),
          _collectionRateCard(percentage),
        ];

        if (mobile) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionRateCard(double percentage) {
    final value =
        percentage.clamp(0.0, 100.0).toDouble();

    return Container(
      height: 142,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 82,
            width: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 82,
                  width: 82,
                  child: CircularProgressIndicator(
                    value: value / 100,
                    strokeWidth: 8,
                    backgroundColor:
                        const Color(0x33475569),
                    valueColor:
                        const AlwaysStoppedAnimation(
                      Color(0xFF60A5FA),
                    ),
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection Rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Current fee collection',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 850;

          final search = TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText:
                  'Search student, admission no. or fee...',
              prefixIcon:
                  const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final classDropdown =
              DropdownButtonFormField<int?>(
            initialValue: selectedClassId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Class',
              prefixIcon:
                  const Icon(Icons.school_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Classes'),
              ),
              ...classes.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(
                    item.name ??
                        item.grade ??
                        'Class ${item.id}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() {
                selectedClassId = value;
                selectedSectionId = null;
                sections = [];
              });

              if (value != null) {
                await _loadSections(value);
              }
            },
          );

          final sectionDropdown =
              DropdownButtonFormField<int?>(
            initialValue: selectedSectionId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Section',
              prefixIcon:
                  const Icon(Icons.groups_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Sections'),
              ),
              ...sections.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: selectedClassId == null
                ? null
                : (value) {
                    setState(() {
                      selectedSectionId = value;
                    });
                  },
          );

          final statusDropdown =
              DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon:
                  const Icon(Icons.filter_alt_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'All',
                child: Text('All Status'),
              ),
              DropdownMenuItem(
                value: 'PENDING',
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: 'PARTIAL',
                child: Text('Partial'),
              ),
              DropdownMenuItem(
                value: 'PAID',
                child: Text('Paid'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedStatus = value;
              });
            },
          );

          if (mobile) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                classDropdown,
                const SizedBox(height: 12),
                sectionDropdown,
                const SizedBox(height: 12),
                statusDropdown,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: search,
              ),
              const SizedBox(width: 12),
              Expanded(child: classDropdown),
              const SizedBox(width: 12),
              Expanded(child: sectionDropdown),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: statusDropdown,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeeTable(
    List<StudentFeeModel> records,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              19,
              20,
              14,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Click a student record to view payment details',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${records.length} records',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 70,
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            _errorState()
          else if (records.isEmpty)
            _emptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 76,
                      columnSpacing: 26,
                      horizontalMargin: 20,
                      showCheckboxColumn: false,
                      headingTextStyle:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text('STUDENT'),
                        ),
                        DataColumn(
                          label: Text('CLASS'),
                        ),
                        DataColumn(
                          label: Text('FEE'),
                        ),
                        DataColumn(
                          label: Text('TOTAL'),
                        ),
                        DataColumn(
                          label: Text('PAID'),
                        ),
                        DataColumn(
                          label: Text('OUTSTANDING'),
                        ),
                        DataColumn(
                          label: Text('DUE DATE'),
                        ),
                        DataColumn(
                          label: Text('STATUS'),
                        ),
                        DataColumn(
                          label: Text('ACTION'),
                        ),
                      ],
                      rows: records.map((record) {
                        return DataRow(
                          onSelectChanged: (_) {
                            _openFeeDetails(record);
                          },
                          cells: [
                            DataCell(
                              _studentCell(record),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _classNameForFee(record),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 130,
                                child: Text(
                                  record.feeName,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(
                                  record.totalAmount,
                                ),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(
                                  record.paidAmount,
                                ),
                                style: const TextStyle(
                                  color:
                                      Color(0xFF059669),
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(
                                  record.pendingAmount,
                                ),
                                style: TextStyle(
                                  color:
                                      record.pendingAmount >
                                              0
                                          ? const Color(
                                              0xFFDC2626,
                                            )
                                          : const Color(
                                              0xFF059669,
                                            ),
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatDate(
                                  record.dueDate,
                                ),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              _statusChip(
                                _displayStatus(record),
                              ),
                              onTap: () =>
                                  _openFeeDetails(record),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Collect Payment',
                                onPressed:
                                    record.pendingAmount >
                                            0
                                        ? () =>
                                            _showAddPaymentDialog(
                                              record,
                                            )
                                        : null,
                                icon: const Icon(
                                  Icons.add_card_rounded,
                                  size: 20,
                                ),
                                color:
                                    const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _studentCell(StudentFeeModel record) {
    final name = record.studentName.isEmpty
        ? 'Student #${record.studentId}'
        : record.studentName;

    return SizedBox(
      width: 185,
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                name.isEmpty
                    ? '?'
                    : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${record.studentId ?? '-'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    Color background;

    switch (status) {
      case 'PAID':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;
      case 'PARTIAL':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;
      default:
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE2E2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'No fee records found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your search or filters.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
