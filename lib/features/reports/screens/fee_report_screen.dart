import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/fee_report_model.dart';
import '../services/report_service.dart';

class FeeReportScreen extends StatefulWidget {
  const FeeReportScreen({super.key});

  @override
  State<FeeReportScreen> createState() => _FeeReportScreenState();
}

class _FeeReportScreenState extends State<FeeReportScreen> {
  late final ReportService _service;

  List<FeeReportModel> _items = [];

  DateTime _from = DateTime.now().subtract(
    const Duration(days: 30),
  );

  DateTime _to = DateTime.now();

  bool _loading = false;
  String? _error;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _service = ReportService(ApiClient());

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String _date(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> _load() async {
    if (_from.isAfter(_to)) {
      setState(() {
        _error = 'From date cannot be after To date.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getFeeReport(
        from: _date(_from),
        to: _date(_to),
      );

      if (!mounted) return;

      setState(() {
        _items = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _pick(bool isFrom) async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isFrom ? _from : _to,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2563eb),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xff172033),
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (isFrom) {
        _from = result;
      } else {
        _to = result;
      }
    });

    await _load();
  }

  // =========================================================
  // FILTERED ITEMS
  // =========================================================

  List<FeeReportModel> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final student =
          (item.studentName ?? '').toLowerCase();

      final receipt =
          (item.receiptNumber ?? '').toLowerCase();

      final method =
          (item.paymentMethod ?? '').toLowerCase();

      final remarks =
          (item.remarks ?? '').toLowerCase();

      final date =
          (item.paymentDate ?? '').toLowerCase();

      return student.contains(_searchQuery) ||
          receipt.contains(_searchQuery) ||
          method.contains(_searchQuery) ||
          remarks.contains(_searchQuery) ||
          date.contains(_searchQuery);
    }).toList();
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get _totalCollected {
    return _items.fold(
      0,
      (sum, item) => sum + (item.amount ?? 0),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1500,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),

                      const SizedBox(height: 24),

                      _buildSummaryCards(isMobile),

                      const SizedBox(height: 22),

                      _buildFilters(isMobile),

                      const SizedBox(height: 22),

                      _buildPaymentsSection(
                        filteredItems,
                        isMobile,
                      ),
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

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 26,
      ),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 52 : 62,
            height: isMobile ? 52 : 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xff2563eb),
                  Color(0xff4f8df7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2563eb)
                      .withOpacity(.20),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Report',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                    letterSpacing: -.5,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  isMobile
                      ? 'Fee payment overview'
                      : 'View and analyze fee payment transactions for the selected period',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff6b7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (!isMobile)
            _headerRefreshButton(),
        ],
      ),
    );
  }

  Widget _headerRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _loading ? null : _load,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffe2e8f0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 19,
                color: _loading
                    ? const Color(0xff94a3b8)
                    : const Color(0xff334155),
              ),
              const SizedBox(width: 8),
              const Text(
                'Refresh',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY CARDS
  // =========================================================

  Widget _buildSummaryCards(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _summaryCard(
            title: 'Total Payments',
            value: '${_items.length}',
            subtitle: 'Payments received',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xff2563eb),
            iconBackground: const Color(0xffeaf2ff),
          ),
          const SizedBox(height: 14),
          _summaryCard(
            title: 'Total Collected',
            value:
                '₹${_totalCollected.toStringAsFixed(2)}',
            subtitle: 'Total fee amount collected',
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xff059669),
            iconBackground: const Color(0xffe7f8f1),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Total Payments',
            value: '${_items.length}',
            subtitle: 'Fee payments received',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xff2563eb),
            iconBackground: const Color(0xffeaf2ff),
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: _summaryCard(
            title: 'Total Collected',
            value:
                '₹${_totalCollected.toStringAsFixed(2)}',
            subtitle: 'Total fee amount collected',
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xff059669),
            iconBackground: const Color(0xffe7f8f1),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 29,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff64748b),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0f172a),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff94a3b8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILTER SECTION
  // =========================================================

  Widget _buildFilters(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        'From Date',
                        _from,
                        () => _pick(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        'To Date',
                        _to,
                        () => _pick(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _searchField(),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _searchButton(),
                    ),
                    const SizedBox(width: 10),
                    _resetButton(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _dateField(
                  'From Date',
                  _from,
                  () => _pick(true),
                ),

                const SizedBox(width: 12),

                _dateField(
                  'To Date',
                  _to,
                  () => _pick(false),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: _searchField(),
                ),

                const SizedBox(width: 12),

                _searchButton(),

                const SizedBox(width: 10),

                _resetButton(),
              ],
            ),
    );
  }

  Widget _dateField(
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xfffbfcfe),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffe2e8f0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Color(0xff2563eb),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff64748b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff172033),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText:
            'Search student, receipt, method...',
        hintStyle: const TextStyle(
          color: Color(0xff94a3b8),
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xff64748b),
          size: 21,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xfffbfcfe),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xffe2e8f0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xffe2e8f0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xff2563eb),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _searchButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(
          Icons.search_rounded,
          size: 19,
        ),
        label: const Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff2563eb),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _resetButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _from = DateTime.now().subtract(
              const Duration(days: 30),
            );
            _to = DateTime.now();
            _searchController.clear();
          });

          _load();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff334155),
          side: const BorderSide(
            color: Color(0xffdbe2ea),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(
          Icons.refresh_rounded,
          size: 20,
        ),
      ),
    );
  }

  // =========================================================
  // PAYMENTS SECTION
  // =========================================================

  Widget _buildPaymentsSection(
    List<FeeReportModel> items,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          10,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf2ff),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.list_alt_rounded,
                    color: Color(0xff2563eb),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fee Payments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff172033),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Payment transactions for the selected period',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748b),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isMobile)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5f9),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} records',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff475569),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(
              height: 1,
              color: Color(0xffeef2f7),
            ),

            const SizedBox(height: 4),

            _content(items),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _content(List<FeeReportModel> items) {
    if (_loading) {
      return const SizedBox(
        height: 430,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xff2563eb),
          ),
        ),
      );
    }

    if (_error != null) {
      return _errorState();
    }

    if (_items.isEmpty) {
      return _emptyState(
        'No fee payments found.',
        'There are no fee transactions for the selected date range.',
      );
    }

    if (items.isEmpty) {
      return _emptyState(
        'No matching payments',
        'Try a different student name, receipt number or payment method.',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 76,
          columnSpacing: 34,
          horizontalMargin: 8,
          dividerThickness: .7,
          headingRowColor:
              WidgetStateProperty.all(
            const Color(0xfff5f8fc),
          ),
          columns: const [
            DataColumn(
              label: Text(
                '#',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'DATE',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'STUDENT',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'RECEIPT NO.',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'AMOUNT',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'METHOD',
                style: _headerStyle,
              ),
            ),
            DataColumn(
              label: Text(
                'REMARKS',
                style: _headerStyle,
              ),
            ),
          ],
          rows: List.generate(
            items.length,
            (index) {
              final item = items[index];

              return DataRow(
                cells: [
                  DataCell(
                    _indexBadge(index + 1),
                  ),

                  DataCell(
                    _dateCell(
                      item.paymentDate ?? '-',
                    ),
                  ),

                  DataCell(
                    _studentCell(
                      item.studentName ?? '-',
                    ),
                  ),

                  DataCell(
                    Text(
                      item.receiptNumber ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff334155),
                      ),
                    ),
                  ),

                  DataCell(
                    _amountCell(
                      item.amount ?? 0,
                    ),
                  ),

                  DataCell(
                    _paymentMethod(
                      item.paymentMethod ?? '-',
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        item.remarks ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff64748b),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TABLE CELLS
  // =========================================================

  Widget _indexBadge(int index) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xffeaf2ff),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xff2563eb),
        ),
      ),
    );
  }

  Widget _dateCell(String value) {
    return SizedBox(
      width: 105,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xff334155),
        ),
      ),
    );
  }

  Widget _studentCell(String name) {
    final initials = _initials(name);

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _avatarColor(name),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xff334155),
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xff172033),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCell(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffe9f9f2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '₹${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xff059669),
        ),
      ),
    );
  }

  Widget _paymentMethod(String method) {
    final lower = method.toLowerCase();

    Color background;
    Color foreground;
    IconData icon;

    if (lower.contains('cash')) {
      background = const Color(0xffe9f9f2);
      foreground = const Color(0xff059669);
      icon = Icons.payments_outlined;
    } else if (lower.contains('upi')) {
      background = const Color(0xfff0eafe);
      foreground = const Color(0xff7c3aed);
      icon = Icons.qr_code_2_rounded;
    } else if (lower.contains('card')) {
      background = const Color(0xffeaf2ff);
      foreground = const Color(0xff2563eb);
      icon = Icons.credit_card_rounded;
    } else if (lower.contains('online')) {
      background = const Color(0xffeaf2ff);
      foreground = const Color(0xff2563eb);
      icon = Icons.language_rounded;
    } else {
      background = const Color(0xfff1f5f9);
      foreground = const Color(0xff475569);
      icon = Icons.payment_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            method,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY / ERROR STATES
  // =========================================================

  Widget _emptyState(
    String title,
    String subtitle,
  ) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xffeef2f7),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Color(0xff94a3b8),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff334155),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xfffff1f2),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xffe11d48),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load fee report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff334155),
              ),
            ),

            const SizedBox(height: 7),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff64748b),
                ),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff2563eb),
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xffdbeafe),
      const Color(0xffdcfce7),
      const Color(0xfffef3c7),
      const Color(0xfffce7f3),
      const Color(0xffede9fe),
      const Color(0xffcffafe),
    ];

    final index =
        name.codeUnits.fold(0, (a, b) => a + b) %
            colors.length;

    return colors[index];
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xffe7ebf2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.035),
          blurRadius: 20,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

// ===========================================================
// TABLE HEADER STYLE
// ===========================================================

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: Color(0xff64748b),
  letterSpacing: .4,
);