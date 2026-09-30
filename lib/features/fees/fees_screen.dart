import 'package:flutter/material.dart';

import 'package:smartkids_admin/features/fees/models/fee_model.dart';
import 'package:smartkids_admin/features/fees/models/fee_dashboard_summary_model.dart';
import 'package:smartkids_admin/features/fees/services/fee_service.dart';
import 'package:smartkids_admin/features/fees/fee_details_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:smartkids_admin/features/fees/apply_fee_structure_screen.dart';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import '../../models/section_model.dart';
import '../../models/student_model.dart';

import '../teachers/services/class_service.dart';
import '../teachers/models/class_model.dart';
import '../../services/section_service.dart';
import '../../services/student_service.dart';
import '../../features/fees/paid_payments_screen.dart';

import 'package:smartkids_admin/core/network/api_client.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'models/fee_structure_import_result_model.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final FeeService _feeService = FeeService();
  ApiClient apiClient = ApiClient();

  final TextEditingController searchController = TextEditingController();

  List<StudentFeeModel> feeRecords = [];
  List<SchoolClass> classes = [];
  List<Section> sections = [];
  List<Student> students = [];

  bool _isDownloadingTemplate = false;
  bool _isImportingExcel = false;

  FeeDashboardSummaryModel? dashboardSummary;

  bool isLoading = true;
  bool isSummaryLoading = true;
  bool isFilterLoading = false;

  // List<dynamic> feeStructures = [];
  // bool _isLoadingFeeStructures = false;

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

  Future<void> _downloadFeeStructureTemplate() async {
    if (_isDownloadingTemplate) return;

    setState(() {
      _isDownloadingTemplate = true;
    });

    try {
      final Uint8List bytes = await _feeService.downloadFeeStructureTemplate();

      await FileSaver.instance.saveFile(
        name: 'fee-structure-template',
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee structure template downloaded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingTemplate = false;
        });
      }
    }
  }

  Future<void> _importFeeStructuresExcel() async {
    if (_isImportingExcel) return;

    try {
      final input = html.FileUploadInputElement()..accept = '.xlsx,.xls';

      input.click();

      await input.onChange.first;

      final files = input.files;

      if (files == null || files.isEmpty) {
        return;
      }

      final file = files.first;

      setState(() {
        _isImportingExcel = true;
      });

      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      final result = reader.result;

      if (result == null) {
        throw Exception('Unable to read selected Excel file.');
      }

      final bytes = Uint8List.fromList((result as List<int>));

      final response = await _feeService.importFeeStructuresFromBytes(
        bytes,
        file.name,
      );

      if (!mounted) return;

      final resultModel = FeeStructureImportResultModel.fromJson(response);

      await _showImportResultDialog(resultModel);

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingExcel = false;
        });
      }
    }
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

      final classService = ClassService(apiClient);
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
      //  _feeService.getFeeStructures(),
      ]);

      if (!mounted) return;

      final studentPage = results[3] as StudentPage;

      setState(() {
        feeRecords = results[0] as List<StudentFeeModel>;
        dashboardSummary = results[1] as FeeDashboardSummaryModel;
        classes = results[2] as List<SchoolClass>;
        students = studentPage.content;
        //feeStructures = results[4] as List<dynamic>;

        isLoading = false;
        isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isSummaryLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
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

      final service = SectionService(apiClient);
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

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
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
          (record.studentId?.toString() ?? '').contains(searchQuery) ||
          record.feeName.toLowerCase().contains(searchQuery) ||
          (student?.admissionNo ?? '').toLowerCase().contains(searchQuery);

      final matchesClass =
          selectedClassId == null ||
          student?.sectionId == null ||
          _sectionBelongsToClass(student!.sectionId!, selectedClassId!);

      final matchesSection =
          selectedSectionId == null || student?.sectionId == selectedSectionId;

      final status = _displayStatus(record);

      final matchesStatus = selectedStatus == 'All' || status == selectedStatus;

      return matchesSearch && matchesClass && matchesSection && matchesStatus;
    }).toList();
  }

  bool _sectionBelongsToClass(int sectionId, int classId) {
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

    final section = _findSectionFromAllClasses(student.sectionId!);

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

  // Future<void> _applyFeeStructure(Map<String, dynamic> structure) async {
  //   final structureId = structure['id'];

  //   if (structureId == null) {
  //     _showMessage('Fee structure ID not found.', isError: true);
  //     return;
  //   }

  //   try {
  //     setState(() {
  //       _isLoadingFeeStructures = true;
  //     });

  //     await _feeService.applyFeeStructure(int.parse(structureId.toString()));

  //     if (!mounted) return;

  //     _showMessage('Fee structure applied successfully.');

  //     await _loadData();
  //   } catch (e) {
  //     if (!mounted) return;

  //     _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingFeeStructures = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _openFeeDetails(StudentFeeModel record) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FeeDetailsScreen(record: record)),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showImportResultDialog(
    FeeStructureImportResultModel result,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_upload_outlined, color: Colors.green),
              SizedBox(width: 10),
              Text('Import Completed'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _importResultRow('Total Rows', result.totalRows.toString()),
                  _importResultRow(
                    'Created',
                    result.created.toString(),
                    valueColor: Colors.green,
                  ),
                  _importResultRow(
                    'Skipped',
                    result.skipped.toString(),
                    valueColor: Colors.orange,
                  ),
                  _importResultRow(
                    'Errors',
                    result.errors.toString(),
                    valueColor: Colors.red,
                  ),

                  if (result.errorDetails.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...result.errorDetails.map(
                      (error) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'Row ${error.row}: ${error.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPaymentDialog(StudentFeeModel record) async {
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
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Outstanding',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              _formatCurrency(record.pendingAmount),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(
                            value: 'BANK_TRANSFER',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(value: 'CARD', child: Text('Card')),
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
                            borderRadius: BorderRadius.circular(12),
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
                                  final amount = double.tryParse(
                                    amountController.text.trim(),
                                  );

                                  if (amount == null || amount <= 0) {
                                    _showMessage(
                                      'Enter a valid amount.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (amount > record.pendingAmount) {
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
                                    await _feeService.recordPayment(
                                      studentFeeId: record.id!,
                                      amount: amount,
                                      paymentMethod: paymentMethod,
                                      remarks: remarksController.text.trim(),
                                    );

                                    if (!mounted) return;

                                    Navigator.pop(dialogContext, true);
                                  } catch (e) {
                                    setDialogState(() {
                                      saving = false;
                                    });

                                    _showMessage(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                      isError: true,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Record Payment',
                                  style: TextStyle(fontWeight: FontWeight.w700),
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
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
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildPremiumSummary(),
                  const SizedBox(height: 22),
                  _buildFilters(),
                  // const SizedBox(height: 18),
                  // _buildFeeStructures(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade500),
              ),
            ],
          ),
        ),

        // ============================================================
        // DOWNLOAD TEMPLATE
        // ============================================================
        OutlinedButton.icon(
          onPressed: _isDownloadingTemplate
              ? null
              : _downloadFeeStructureTemplate,
          icon: _isDownloadingTemplate
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined, size: 18),
          label: Text(_isDownloadingTemplate ? 'Downloading...' : 'Template'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ============================================================
        // IMPORT EXCEL
        // ============================================================
        ElevatedButton.icon(
          onPressed: _isImportingExcel ? null : _importFeeStructuresExcel,
          icon: _isImportingExcel
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(_isImportingExcel ? 'Importing...' : 'Import Excel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(width: 10),

        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const ApplyFeeStructureScreen(),
              ),
            );

            if (result == true && mounted) {
              await _loadData();
            }
          },
          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
          label: const Text('Apply Fees'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ============================================================
        // PAID PAYMENTS
        // ============================================================
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaidPaymentsScreen()),
            );
          },
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: const Text('Paid Payments'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF059669),
            side: const BorderSide(color: Color(0xFF059669)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ============================================================
        // REFRESH
        // ============================================================
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
    final percentage = summary?.collectionPercentage ?? 0;

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
                    padding: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
    final value = percentage.clamp(0.0, 100.0).toDouble();

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
                    backgroundColor: const Color(0x33475569),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF60A5FA)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 850;

          final search = TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search student, admission no. or fee...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final classDropdown = DropdownButtonFormField<int?>(
            initialValue: selectedClassId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Class',
              prefixIcon: const Icon(Icons.school_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                    item.name ?? item.grade ?? 'Class ${item.id}',
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

          final sectionDropdown = DropdownButtonFormField<int?>(
            initialValue: selectedSectionId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Section',
              prefixIcon: const Icon(Icons.groups_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
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

          final statusDropdown = DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: const Icon(Icons.filter_alt_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Status')),
              DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
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
              Expanded(flex: 2, child: search),
              const SizedBox(width: 12),
              Expanded(child: classDropdown),
              const SizedBox(width: 12),
              Expanded(child: sectionDropdown),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: statusDropdown),
            ],
          );
        },
      ),
    );
  }

  // Widget _buildFeeStructures() {
  //   return Container(
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(18),
  //       border: Border.all(color: const Color(0xFFE5E7EB)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(20, 19, 20, 14),
  //           child: Row(
  //             children: [
  //               const Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Fee Structures',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w800,
  //                         color: Color(0xFF0F172A),
  //                       ),
  //                     ),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       'Apply configured fees to students',
  //                       style: TextStyle(
  //                         fontSize: 11,
  //                         color: Color(0xFF64748B),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 11,
  //                   vertical: 7,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFF1F5F9),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: Text(
  //                   '${feeStructures.length} structures',
  //                   style: const TextStyle(
  //                     fontSize: 11,
  //                     fontWeight: FontWeight.w700,
  //                     color: Color(0xFF475569),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         const Divider(height: 1, color: Color(0xFFE2E8F0)),

  //         if (feeStructures.isEmpty)
  //           const Padding(
  //             padding: EdgeInsets.symmetric(vertical: 35),
  //             child: Center(
  //               child: Text(
  //                 'No fee structures found.',
  //                 style: TextStyle(color: Color(0xFF64748B)),
  //               ),
  //             ),
  //           )
  //         else
  //           LayoutBuilder(
  //             builder: (context, constraints) {
  //               return SingleChildScrollView(
  //                 scrollDirection: Axis.horizontal,
  //                 child: ConstrainedBox(
  //                   constraints: BoxConstraints(minWidth: constraints.maxWidth),
  //                   child: DataTable(
  //                     headingRowHeight: 48,
  //                     dataRowMinHeight: 62,
  //                     dataRowMaxHeight: 70,
  //                     columnSpacing: 30,
  //                     horizontalMargin: 20,
  //                     columns: const [
  //                       DataColumn(label: Text('FEE')),
  //                       DataColumn(label: Text('CLASS')),
  //                       DataColumn(label: Text('AMOUNT')),
  //                       DataColumn(label: Text('DUE DATE')),
  //                       DataColumn(label: Text('STATUS')),
  //                       DataColumn(label: Text('ACTION')),
  //                     ],
  //                     rows: feeStructures.map((item) {
  //                       final structure = Map<String, dynamic>.from(item);

  //                       final id = structure['id'];

  //                       final name = structure['name']?.toString() ?? '-';

  //                       final amount =
  //                           double.tryParse(
  //                             structure['amount']?.toString() ?? '',
  //                           ) ??
  //                           0;

  //                       final dueDate = structure['dueDate']?.toString() ?? '-';

  //                       final status =
  //                           structure['status']?.toString() ?? 'ACTIVE';

  //                       final classId = structure['classId'];

  //                       String className = '-';

  //                       if (classId != null) {
  //                         final parsedClassId = int.tryParse(
  //                           classId.toString(),
  //                         );

  //                         for (final c in classes) {
  //                           if (c.id == parsedClassId) {
  //                             className = c.name ?? c.grade ?? '-';
  //                             break;
  //                           }
  //                         }
  //                       }

  //                       return DataRow(
  //                         cells: [
  //                           DataCell(
  //                             Text(
  //                               name,
  //                               style: const TextStyle(
  //                                 fontWeight: FontWeight.w700,
  //                               ),
  //                             ),
  //                           ),
  //                           DataCell(Text(className)),
  //                           DataCell(Text(_formatCurrency(amount))),
  //                           DataCell(Text(_formatDate(dueDate))),
  //                           DataCell(_statusChip(status)),
  //                           DataCell(
  //                             ElevatedButton.icon(
  //                               onPressed: _isLoadingFeeStructures
  //                                   ? null
  //                                   : () {
  //                                       _applyFeeStructure(structure);
  //                                     },
  //                               icon: const Icon(
  //                                 Icons.play_arrow_rounded,
  //                                 size: 17,
  //                               ),
  //                               label: const Text('Apply'),
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: const Color(0xFF2563EB),
  //                                 foregroundColor: Colors.white,
  //                                 elevation: 0,
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(10),
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // Future<void> _showFeeStructuresDialog() async {
  //   try {
  //     final structures = await _feeService.getFeeStructures();

  //     if (!mounted) return;

  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         int? applyingId;

  //         return StatefulBuilder(
  //           builder: (context, setDialogState) {
  //             return AlertDialog(
  //               title: const Row(
  //                 children: [
  //                   Icon(Icons.account_balance_wallet_outlined),
  //                   SizedBox(width: 10),
  //                   Text('Fee Structures'),
  //                 ],
  //               ),
  //               content: SizedBox(
  //                 width: 750,
  //                 child: structures.isEmpty
  //                     ? const Center(
  //                         child: Padding(
  //                           padding: EdgeInsets.all(30),
  //                           child: Text(
  //                             'No fee structures found.',
  //                             style: TextStyle(fontSize: 16),
  //                           ),
  //                         ),
  //                       )
  //                     : SingleChildScrollView(
  //                         child: Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: structures.map<Widget>((item) {
  //                             final structure = Map<String, dynamic>.from(item);

  //                             final int? structureId = structure['id'] is int
  //                                 ? structure['id']
  //                                 : int.tryParse('${structure['id'] ?? ''}');

  //                             final String name =
  //                                 '${structure['name'] ?? 'Fee Structure'}';

  //                             final String amount =
  //                                 '${structure['amount'] ?? 0}';

  //                             final String className =
  //                                 '${structure['className'] ?? structure['class_name'] ?? structure['classId'] ?? '-'}';

  //                             final String dueDate =
  //                                 '${structure['dueDate'] ?? structure['due_date'] ?? '-'}';

  //                             final bool isApplying = applyingId == structureId;

  //                             return Card(
  //                               margin: const EdgeInsets.only(bottom: 10),
  //                               child: Padding(
  //                                 padding: const EdgeInsets.all(12),
  //                                 child: Row(
  //                                   children: [
  //                                     Expanded(
  //                                       flex: 3,
  //                                       child: Column(
  //                                         crossAxisAlignment:
  //                                             CrossAxisAlignment.start,
  //                                         children: [
  //                                           Text(
  //                                             name,
  //                                             style: const TextStyle(
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 15,
  //                                             ),
  //                                           ),
  //                                           const SizedBox(height: 5),
  //                                           Text('Class: $className'),
  //                                           Text('Amount: ₹$amount'),
  //                                           Text('Due Date: $dueDate'),
  //                                         ],
  //                                       ),
  //                                     ),

  //                                     ElevatedButton.icon(
  //                                       onPressed:
  //                                           structureId == null || isApplying
  //                                           ? null
  //                                           : () async {
  //                                               setDialogState(() {
  //                                                 applyingId = structureId;
  //                                               });

  //                                               try {
  //                                                 await _feeService
  //                                                     .applyFeeStructure(
  //                                                       structureId,
  //                                                     );

  //                                                 if (!mounted) return;

  //                                                 Navigator.pop(context);

  //                                                 ScaffoldMessenger.of(
  //                                                   context,
  //                                                 ).showSnackBar(
  //                                                   const SnackBar(
  //                                                     content: Text(
  //                                                       'Fee structure applied successfully.',
  //                                                     ),
  //                                                     backgroundColor:
  //                                                         Colors.green,
  //                                                   ),
  //                                                 );

  //                                                 await _loadData();
  //                                               } catch (e) {
  //                                                 setDialogState(() {
  //                                                   applyingId = null;
  //                                                 });

  //                                                 if (!mounted) return;

  //                                                 ScaffoldMessenger.of(
  //                                                   context,
  //                                                 ).showSnackBar(
  //                                                   SnackBar(
  //                                                     content: Text(
  //                                                       'Failed to apply fee structure: $e',
  //                                                     ),
  //                                                     backgroundColor:
  //                                                         Colors.red,
  //                                                   ),
  //                                                 );
  //                                               }
  //                                             },
  //                                       icon: isApplying
  //                                           ? const SizedBox(
  //                                               width: 16,
  //                                               height: 16,
  //                                               child:
  //                                                   CircularProgressIndicator(
  //                                                     strokeWidth: 2,
  //                                                   ),
  //                                             )
  //                                           : const Icon(
  //                                               Icons.play_arrow_rounded,
  //                                             ),
  //                                       label: Text(
  //                                         isApplying ? 'Applying...' : 'Apply',
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             );
  //                           }).toList(),
  //                         ),
  //                       ),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   child: const Text('Close'),
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to load fee structures: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Widget _buildFeeTable(List<StudentFeeModel> records) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
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
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(child: CircularProgressIndicator()),
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
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 76,
                      columnSpacing: 26,
                      horizontalMargin: 20,
                      showCheckboxColumn: false,
                      headingTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                      columns: const [
                        DataColumn(label: Text('STUDENT')),
                        //DataColumn(label: Text('CLASS')),
                        DataColumn(label: Text('FEE')),
                        DataColumn(label: Text('TOTAL')),
                        DataColumn(label: Text('PAID')),
                        DataColumn(label: Text('OUTSTANDING')),
                        DataColumn(label: Text('DUE DATE')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: records.map((record) {
                        return DataRow(
                          onSelectChanged: (_) {
                            _openFeeDetails(record);
                          },
                          cells: [
                            DataCell(
                              _studentCell(record),
                              onTap: () => _openFeeDetails(record),
                            ),
                            // DataCell(Text(_classNameForFee(record))),
                            DataCell(
                              SizedBox(
                                width: 130,
                                child: Text(
                                  record.feeName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(_formatCurrency(record.totalAmount)),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(record.paidAmount),
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(record.pendingAmount),
                                style: TextStyle(
                                  color: record.pendingAmount > 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF059669),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              Text(_formatDate(record.dueDate)),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              _statusChip(_displayStatus(record)),
                              onTap: () => _openFeeDetails(record),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Collect Payment',
                                onPressed: record.pendingAmount > 0
                                    ? () => _showAddPaymentDialog(record)
                                    : null,
                                icon: const Icon(
                                  Icons.add_card_rounded,
                                  size: 20,
                                ),
                                color: const Color(0xFF2563EB),
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
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your search or filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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

  Widget _importResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
