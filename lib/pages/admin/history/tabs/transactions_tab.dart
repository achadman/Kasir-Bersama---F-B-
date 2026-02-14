import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../services/report_service.dart';
import '../../../../controllers/admin_controller.dart';
import '../widgets/transaction_item.dart';
import '../transaction_detail_page.dart';

class TransactionsTab extends StatefulWidget {
  final String storeId;
  const TransactionsTab({super.key, required this.storeId});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final _reportService = ReportService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  final _searchController = TextEditingController();
  String _searchQuery = "";

  String _selectedFilter = "Semua";
  final List<String> _filters = [
    "Semua",
    "Hari Ini",
    "Minggu Ini",
    "Bulan Ini",
  ];

  double get _totalSalesFiltered {
    double total = 0;
    for (var tx in _filteredTransactions) {
      total += (tx['total_amount'] as num).toDouble();
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      DateTime? dateLimit;
      final now = DateTime.now();

      if (_selectedFilter == "Hari Ini") {
        dateLimit = DateTime(now.year, now.month, now.day);
      } else if (_selectedFilter == "Minggu Ini") {
        dateLimit = now.subtract(Duration(days: now.weekday - 1));
        dateLimit = DateTime(dateLimit.year, dateLimit.month, dateLimit.day);
      } else if (_selectedFilter == "Bulan Ini") {
        dateLimit = DateTime(now.year, now.month, 1);
      }

      final adminCtrl = context.read<AdminController>();
      final isCashier = adminCtrl.role == 'cashier';

      debugPrint("TransactionsTab: Loading for storeId: ${widget.storeId}");
      debugPrint(
        "TransactionsTab: Filter: $_selectedFilter, DateLimit: $dateLimit",
      );

      final data = await _reportService.getAllTransactions(
        widget.storeId,
        dateLimit: dateLimit,
        cashierId: isCashier ? adminCtrl.userId : null,
      );

      debugPrint("TransactionsTab: Fetched ${data.length} transactions.");
      if (data.isNotEmpty) {
        debugPrint(
          "TransactionsTab: First Tx created_at: ${data.first['created_at']}",
        );
      }
      if (mounted) {
        setState(() {
          _allTransactions = data;
          _filterTransactions(_searchQuery); // Apply search query after loading
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("TransactionsTab: ERROR loading: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTransactions(String query) {
    setState(() {
      _searchQuery = query; // Update search query
      _filteredTransactions = _allTransactions.where((tx) {
        final id = tx['id'].toString().toLowerCase();
        final name = (tx['profiles']?['full_name'] ?? '')
            .toString()
            .toLowerCase();
        return id.contains(query.toLowerCase()) ||
            name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _openDetail(Map<String, dynamic> transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Unified Header: Search + Filter Dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterTransactions,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Cari ID / Kasir...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: _filters.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedFilter = newValue);
                        _loadTransactions();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  color: const Color(0xFFEA5700),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 8),
                      _buildSummaryCard(),
                      const SizedBox(height: 24),

                      if (_filteredTransactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                            left: 8,
                            right: 8,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 12,
                              ), // Align with row padding
                              Expanded(
                                flex: 3,
                                child: Text("TRANSAKSI", style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text("KASIR", style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "TOTAL",
                                  style: _headerStyle,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24), // Chevron space
                            ],
                          ),
                        ),

                      if (_filteredTransactions.isEmpty)
                        _buildEmptyState()
                      else
                        ..._filteredTransactions.map(
                          (tx) => TransactionItem(
                            transaction: tx,
                            onTap: () => _openDetail(tx),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.grey[500],
    letterSpacing: 0.5,
  );

  Widget _buildSummaryCard() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEA5700,
        ).withOpacity(0.1), // Changed withValues to withOpacity
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEA5700).withOpacity(0.2),
        ), // Changed withValues to withOpacity
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Penjualan ($_selectedFilter)",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  currencyFormat.format(_totalSalesFiltered),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEA5700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEA5700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _filteredTransactions.length.toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Transaksi",
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 100),
        Icon(CupertinoIcons.doc_text_search, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          "Tidak ada transaksi ditemukan",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
