import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount'
  bool _sortAsc = false;
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
            cmp = a.date.compareTo(b.date);
          }
          return _sortAsc ? cmp : -cmp;
        });

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            title: Text(
              'History',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_sortBy == 'date') {
                      _sortBy = 'amount';
                    } else {
                      _sortBy = 'date';
                    }
                  });
                },
                icon: Icon(
                  _sortBy == 'date'
                      ? Icons.calendar_today_rounded
                      : Icons.payments_rounded,
                  color: const Color(0xFF6366F1),
                ),
                tooltip: 'Sort by $_sortBy',
              ),
              IconButton(
                onPressed: () => setState(() => _sortAsc = !_sortAsc),
                icon: Icon(
                  _sortAsc
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search merchant or category...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // Compact Dropdown Filters
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 1. Type
                    _buildDropdownFilter(
                      ['all', 'expense', 'income', 'split'],
                      _typeFilter,
                      (val) => setState(() {
                        _typeFilter = val;
                        _categoryFilter = 'All';
                      }),
                      isDark,
                      const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    // 2. Category
                    _buildDropdownFilter(
                      currentCategories,
                      _categoryFilter,
                      (val) => setState(() => _categoryFilter = val),
                      isDark,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    // 3. Wallet
                    _buildDropdownFilter(
                      [
                        'All',
                        ...provider.user?.wallets
                                .map(
                                  (w) =>
                                      w.type[0].toUpperCase() +
                                      w.type.substring(1),
                                )
                                .toSet() ??
                            ['Cash', 'Bank', 'Credit'],
                      ],
                      _walletFilter,
                      (val) => setState(() => _walletFilter = val),
                      isDark,
                      const Color(0xFF8B5CF6),
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
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  title: const Text('Delete Transaction'),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Color(0xFFF43F5E),
                                        ),
                                      ),
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

  Widget _buildDropdownFilter(
    List<String> items,
    String currentValue,
    Function(String) onSelected,
    bool isDark,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(currentValue) ? currentValue : items.first,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: color,
            ),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            onChanged: (val) {
              if (val != null) onSelected(val);
            },
            items: items.map((item) {
              final label = item.length > 1
                  ? item[0].toUpperCase() + item.substring(1)
                  : item.toUpperCase();
              return DropdownMenuItem(
                value: item,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

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
        return const Color(0xFF6366F1);
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
          borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.category} • ${transaction.date}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
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
                                0xFF6366F1,
                              ).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Split: ${transaction.members.take(3).map((m) => m.name.isNotEmpty ? m.name : 'User').join(', ')}${transaction.members.length > 3 ? ' +${transaction.members.length - 3} others' : ''}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
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
                        style: TextStyle(
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
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
                Icon(
                  Icons.group_rounded,
                  color: const Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Split Participants',
                  style: TextStyle(
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
              style: const TextStyle(
                color: Color(0xFF94A3B8),
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
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (m.name.isNotEmpty ? m.name[0] : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          m.name.isNotEmpty ? m.name : 'User',
                          style: TextStyle(
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
                      style: TextStyle(
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
