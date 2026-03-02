import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  final String? initialWallet;
  const TransactionsScreen({super.key, this.initialWallet});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _typeFilter = 'all'; // 'all', 'expense', 'income', 'split'
  String _categoryFilter = 'All';
  String _walletFilter = 'All';
  String _paymentModeFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount'
  bool _sortAsc = false;
  // bool _showFilters = false; // Removed as we use a sheet now
  bool _pendingOnly = false;
  bool _recurringOnly = false;
  bool _includeAdjustments = true;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  static const expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Education',
    'Home',
    'Subscription',
    'Other',
  ];

  static const incomeCategories = [
    'Salary',
    'Freelance',
    'Bonus',
    'Investment',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialWallet != null) {
      _walletFilter = widget.initialWallet!;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2563EB),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _typeFilter = 'all';
      _categoryFilter = 'All';
      _walletFilter = 'All';
      _paymentModeFilter = 'All';
      _selectedDate = null;
      _sortBy = 'date';
      _sortAsc = false;
      _pendingOnly = false;
      _recurringOnly = false;
      _includeAdjustments = true;
    });
  }

  bool get _hasActiveFilters =>
      _typeFilter != 'all' ||
      _categoryFilter != 'All' ||
      _walletFilter != 'All' ||
      _paymentModeFilter != 'All' ||
      _selectedDate != null ||
      _pendingOnly ||
      _recurringOnly ||
      !_includeAdjustments;

  int get _activeFilterCount {
    int count = 0;
    if (_typeFilter != 'all') count++;
    if (_categoryFilter != 'All') count++;
    if (_walletFilter != 'All') count++;
    if (_paymentModeFilter != 'All') count++;
    if (_selectedDate != null) count++;
    if (_pendingOnly) count++;
    if (_recurringOnly) count++;
    if (!_includeAdjustments) count++;
    return count;
  }

  Future<void> _exportCsv(List<Transaction> transactions) async {
    if (transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions to export'),
            backgroundColor: Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      // Build CSV rows
      final headers = [
        'Date',
        'Time',
        'Title',
        'Type',
        'Category',
        'Amount',
        'Wallet',
        'Payment Mode',
        'Split Members',
      ];

      final rows = <List<dynamic>>[headers];

      for (final t in transactions) {
        final members = t.members.isNotEmpty
            ? t.members
                  .map((m) => '${m.name}(${Helpers.formatCurrency(m.amount)})')
                  .join('; ')
            : '';

        rows.add([
          t.date,
          t.time,
          t.title.isNotEmpty ? t.title : t.category,
          t.type,
          t.category,
          t.amount,
          t.wallet ?? '',
          t.paymentMode ?? '',
          members,
        ]);
      }

      final csvBuffer = StringBuffer();
      for (final row in rows) {
        csvBuffer.writeln(
          row
              .map((cell) {
                final str = cell.toString();
                if (str.contains(',') ||
                    str.contains('"') ||
                    str.contains('\n')) {
                  return '"${str.replaceAll('"', '""')}"';
                }
                return str;
              })
              .join(','),
        );
      }
      final csvData = csvBuffer.toString();

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/fintrack_transactions_$dateStr.csv');
      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FinTrack Transactions - $dateStr',
        text: '${transactions.length} transactions exported from FinTrack',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFF43F5E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final List<String> currentCategories = ['All'];
        if (_typeFilter == 'expense') {
          currentCategories.addAll(expenseCategories);
        } else if (_typeFilter == 'income') {
          currentCategories.addAll(incomeCategories);
        } else {
          currentCategories.addAll(
            provider.transactions.map((t) => t.category).toSet().toList(),
          );
        }

        // Payment modes from transactions

        var filtered = provider.transactions.toList();

        // Type filter
        if (_typeFilter != 'all') {
          filtered = filtered.where((t) => t.type == _typeFilter).toList();
        }

        // Category filter
        if (_categoryFilter != 'All') {
          filtered = filtered
              .where((t) => t.category == _categoryFilter)
              .toList();
        }

        // Wallet filter
        if (_walletFilter != 'All') {
          final targetType = _walletFilter.toLowerCase();
          filtered = filtered
              .where(
                (t) =>
                    t.walletType == targetType ||
                    (t.wallet?.toLowerCase().contains(targetType) ?? false),
              )
              .toList();
        }

        // Payment mode filter
        if (_paymentModeFilter != 'All') {
          filtered = filtered
              .where((t) => t.paymentMode == _paymentModeFilter)
              .toList();
        }

        // Date filter
        if (_selectedDate != null) {
          final dateStr =
              '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
          filtered = filtered.where((t) => t.date == dateStr).toList();
        }

        // Pending filter (status != paid for splits)
        if (_pendingOnly) {
          filtered = filtered
              .where(
                (t) =>
                    t.type == 'split' &&
                    t.members.any((m) => m.status != 'paid'),
              )
              .toList();
        }

        // Recurring filter
        if (_recurringOnly) {
          filtered = filtered.where((t) => t.isRecurring ?? false).toList();
        }

        // Adjustments filter
        if (!_includeAdjustments) {
          filtered = filtered.where((t) => !(t.isAdjustment)).toList();
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.category.toLowerCase().contains(q),
              )
              .toList();
        }

        // Sort
        filtered.sort((a, b) {
          int cmp;
          if (_sortBy == 'amount') {
            cmp = a.amount.compareTo(b.amount);
          } else {
            // Sort by date, then time, then createdAt
            cmp = a.date.compareTo(b.date);
            if (cmp == 0) {
              cmp = a.time.compareTo(b.time);
            }
            if (cmp == 0 && a.createdAt != null && b.createdAt != null) {
              cmp = a.createdAt!.compareTo(b.createdAt!);
            }
          }
          return _sortAsc ? cmp : -cmp;
        });

        // Summary stats for filtered
        final totalExpense = filtered
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = filtered
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            title: Text(
              'History',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              // Calendar button
              IconButton(
                onPressed: _pickDate,
                icon: Stack(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: _selectedDate != null
                          ? const Color(0xFF2563EB)
                          : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                    ),
                    if (_selectedDate != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Pick date',
              ),
              // Download button
              IconButton(
                onPressed: () => _exportCsv(filtered),
                icon: Icon(
                  Icons.download_rounded,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                tooltip: 'Download CSV',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // Selected date indicator
              if (_selectedDate != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate!.day} ${_monthName(_selectedDate!.month)} ${_selectedDate!.year}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search Bar + Sort
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context, provider),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 16,
                                  color: _hasActiveFilters
                                      ? const Color(0xFF2563EB)
                                      : (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8)),
                                ),
                                Text(
                                  'Filter',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: _hasActiveFilters
                                        ? const Color(0xFF2563EB)
                                        : (isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                            if (_activeFilterCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort toggle button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_sortBy == 'date' && !_sortAsc) {
                            _sortAsc = true;
                          } else if (_sortBy == 'date' && _sortAsc) {
                            _sortBy = 'amount';
                            _sortAsc = false;
                          } else if (_sortBy == 'amount' && !_sortAsc) {
                            _sortAsc = true;
                          } else {
                            _sortBy = 'date';
                            _sortAsc = false;
                          }
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _sortAsc
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 16,
                              color: const Color(0xFF2563EB),
                            ),
                            Text(
                              _sortBy == 'date' ? 'Date' : 'Amt',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Summary bar
              if (filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      if (totalIncome > 0)
                        Text(
                          '+${Helpers.formatCurrency(totalIncome)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      if (totalIncome > 0 && totalExpense > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      if (totalExpense > 0)
                        Text(
                          '-${Helpers.formatCurrency(totalExpense)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                    ],
                  ),
                ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasActiveFilters || _selectedDate != null
                                  ? 'No matching transactions'
                                  : 'No transactions yet',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            if (_hasActiveFilters || _selectedDate != null) ...[
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(
                                  Icons.filter_list_off_rounded,
                                  size: 16,
                                ),
                                label: const Text('Clear all filters'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final t = filtered[index];
                          return _TransactionCard(
                            transaction: t,
                            isDark: isDark,
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'Delete Transaction',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF43F5E,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await provider.deleteTransaction(t);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Local state for the sheet
    String localType = _typeFilter;
    String localWallet = _walletFilter;
    String localPaymentMode = _paymentModeFilter;
    bool localPending = _pendingOnly;
    bool localRecurring = _recurringOnly;
    bool localAdjustments = _includeAdjustments;
    DateTime? localDate = _selectedDate;

    int selectedCategoryIdx = 0;
    final categories = ['Method', 'Status', 'Type', 'Date Range'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final wallets = provider.user?.wallets ?? [];
            final paymentModes = [
              'All',
              'UPI',
              'Debit Card',
              'Net Banking',
              'Handover',
              'Swipe',
              'Gateway',
            ];

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Filter by',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedCategoryIdx == index;
                              return InkWell(
                                onTap: () => setModalState(
                                  () => selectedCategoryIdx = index,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    categories[index],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF818CF8)
                                                : const Color(0xFF2563EB))
                                          : (isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Content Area
                        Expanded(
                          child: IndexedStack(
                            index: selectedCategoryIdx,
                            children: [
                              // Method
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  _buildFilterHeader('Source', isDark),
                                  const SizedBox(height: 12),
                                  _buildSelectionItem(
                                    'All',
                                    localWallet == 'All',
                                    isDark,
                                    () => setModalState(
                                      () => localWallet = 'All',
                                    ),
                                  ),
                                  ...wallets.map((w) {
                                    final label = w.name;
                                    final type =
                                        w.type[0].toUpperCase() +
                                        w.type.substring(1);
                                    return _buildSelectionItem(
                                      '$label ($type)',
                                      localWallet == type,
                                      isDark,
                                      () => setModalState(
                                        () => localWallet = type,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                  _buildFilterHeader('Payment Mode', isDark),
                                  const SizedBox(height: 12),
                                  ...paymentModes.map(
                                    (m) => _buildSelectionItem(
                                      m,
                                      localPaymentMode == m,
                                      isDark,
                                      () => setModalState(
                                        () => localPaymentMode = m,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Status
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  _buildToggleItem(
                                    'Pending Splits',
                                    localPending,
                                    isDark,
                                    () => setModalState(
                                      () => localPending = !localPending,
                                    ),
                                  ),
                                  _buildToggleItem(
                                    'Recurring Bills',
                                    localRecurring,
                                    isDark,
                                    () => setModalState(
                                      () => localRecurring = !localRecurring,
                                    ),
                                  ),
                                  _buildToggleItem(
                                    'Include Adjustments',
                                    localAdjustments,
                                    isDark,
                                    () => setModalState(
                                      () =>
                                          localAdjustments = !localAdjustments,
                                    ),
                                  ),
                                ],
                              ),

                              // Type
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  _buildSelectionItem(
                                    'All',
                                    localType == 'all',
                                    isDark,
                                    () =>
                                        setModalState(() => localType = 'all'),
                                  ),
                                  _buildSelectionItem(
                                    'Expense',
                                    localType == 'expense',
                                    isDark,
                                    () => setModalState(
                                      () => localType = 'expense',
                                    ),
                                  ),
                                  _buildSelectionItem(
                                    'Income',
                                    localType == 'income',
                                    isDark,
                                    () => setModalState(
                                      () => localType = 'income',
                                    ),
                                  ),
                                  _buildSelectionItem(
                                    'Split',
                                    localType == 'split',
                                    isDark,
                                    () => setModalState(
                                      () => localType = 'split',
                                    ),
                                  ),
                                ],
                              ),

                              // Date Range
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  _buildSelectionItem(
                                    localDate == null
                                        ? 'Any Date'
                                        : Helpers.formatDate(localDate!),
                                    localDate == null,
                                    isDark,
                                    () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            localDate ?? DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (d != null)
                                        setModalState(() => localDate = d);
                                    },
                                  ),
                                  if (localDate != null)
                                    _buildSelectionItem(
                                      'Clear Date',
                                      false,
                                      isDark,
                                      () =>
                                          setModalState(() => localDate = null),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                localType = 'all';
                                localWallet = 'All';
                                localPaymentMode = 'All';
                                localPending = false;
                                localRecurring = false;
                                localAdjustments = true;
                                localDate = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _typeFilter = localType;
                                _walletFilter = localWallet;
                                _paymentModeFilter = localPaymentMode;
                                _pendingOnly = localPending;
                                _recurringOnly = localRecurring;
                                _includeAdjustments = localAdjustments;
                                _selectedDate = localDate;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterHeader(String label, bool isDark) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildSelectionItem(
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark
                      ? (isSelected ? Colors.white : const Color(0xFF94A3B8))
                      : (isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B)),
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isDark
                  ? (isActive ? Colors.white : const Color(0xFF94A3B8))
                  : (isActive
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B)),
            ),
          ),
          Switch.adaptive(
            value: isActive,
            onChanged: (_) => onTap(),
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Color _chipColor(String type) {
    switch (type) {
      case 'expense':
        return const Color(0xFFF43F5E);
      case 'income':
        return const Color(0xFF10B981);
      case 'split':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _monthName(int month) {
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
    return months[month];
  }
}

// ── Filter Section ──
class _FilterSection extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget child;

  const _FilterSection({
    required this.label,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Filter Chip ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color
              : (isDark
                    ? const Color(0xFF0F172A).withOpacity(0.5)
                    : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: active
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

// ── Transaction Card ──
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.isDark,
    required this.onDelete,
  });

  Color _getColor() {
    switch (transaction.type) {
      case 'income':
        return const Color(0xFF10B981);
      case 'split':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFF43F5E);
    }
  }

  IconData _getIcon() {
    switch (transaction.category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Home':
        return Icons.home_rounded;
      case 'Subscription':
        return Icons.subscriptions_rounded;
      case 'Salary':
        return Icons.work_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      case 'Bonus':
        return Icons.card_giftcard_rounded;
      case 'Investment':
        return Icons.trending_up_rounded;
      case 'Gift':
        return Icons.redeem_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: transaction.type == 'split'
            ? () => _showSplitDetails(context, isDark)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.3)
                  : const Color(0xFFF1F5F9),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIcon(), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title.isNotEmpty
                          ? transaction.title
                          : transaction.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          transaction.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 8,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        Text(
                          transaction.date,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        if (transaction.paymentMode != null &&
                            transaction.paymentMode!.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          Text(
                            transaction.paymentMode!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (transaction.type == 'split' &&
                        transaction.members.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 10,
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Split: ${transaction.members.take(3).map((m) => m.name.isNotEmpty ? m.name : 'User').join(', ')}${transaction.members.length > 3 ? ' +${transaction.members.length - 3} others' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2563EB),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${transaction.type == 'income' ? '+' : '-'}${Helpers.formatCurrency(transaction.amount)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (transaction.type == 'split')
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                  if (transaction.wallet != null)
                    Text(
                      transaction.wallet!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitDetails(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.group_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Split Participants',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${Helpers.formatCurrency(transaction.amount)}',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...transaction.members.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (m.name.isNotEmpty ? m.name[0] : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          m.name.isNotEmpty ? m.name : 'User',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Helpers.formatCurrency(m.amount),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
