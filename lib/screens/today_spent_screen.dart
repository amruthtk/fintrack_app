import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../models/transaction.dart';

class TodaySpentScreen extends StatelessWidget {
  const TodaySpentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final today = Helpers.todayDate();
        final todayExpenses = provider.transactions
            .where((t) =>
                t.type == 'expense' &&
                t.date == today &&
                !t.isAdjustment)
            .toList()
          ..sort((a, b) {
            // Sort by time descending (most recent first)
            return b.time.compareTo(a.time);
          });

        final totalSpent =
            todayExpenses.fold(0.0, (sum, t) => sum + t.amount);

        // Group by category
        final Map<String, double> categoryTotals = {};
        for (final t in todayExpenses) {
          categoryTotals[t.category] =
              (categoryTotals[t.category] ?? 0) + t.amount;
        }
        final sortedCategories = categoryTotals.keys.toList()
          ..sort((a, b) =>
              categoryTotals[b]!.compareTo(categoryTotals[a]!));

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Today\'s Spending',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            foregroundColor:
                isDark ? Colors.white : const Color(0xFF0F172A),
            actions: [
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          body: todayExpenses.isEmpty
              ? _buildEmpty(isDark)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    // ── Summary Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF43F5E),
                            Color(0xFFE11D48),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.trending_down_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent Today',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(totalSpent),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${todayExpenses.length} ${todayExpenses.length == 1 ? 'transaction' : 'transactions'} across ${categoryTotals.length} ${categoryTotals.length == 1 ? 'category' : 'categories'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Category Breakdown ──
                    if (sortedCategories.isNotEmpty) ...[
                      Text(
                        'By Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: sortedCategories.map((category) {
                            final amount = categoryTotals[category]!;
                            final percent = totalSpent > 0
                                ? (amount / totalSpent)
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF43F5E)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Helpers.getCategoryIcon(
                                          category),
                                      size: 16,
                                      color: const Color(0xFFF43F5E),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Text(
                                              category,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              Helpers.formatCurrency(
                                                  amount),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    Color(0xFFF43F5E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child:
                                              LinearProgressIndicator(
                                            value: percent,
                                            minHeight: 4,
                                            backgroundColor:
                                                const Color(0xFFF43F5E)
                                                    .withValues(
                                                        alpha: 0.1),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                              Color(0xFFF43F5E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Transactions List ──
                    Text(
                      'All Transactions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...todayExpenses.map((t) => _TransactionTile(
                          transaction: t,
                          isDark: isDark,
                        )),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_rounded,
              size: 56,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Spending Today!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t spent anything today.\nKeep saving! 💪',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;

  const _TransactionTile({
    required this.transaction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Helpers.getCategoryIcon(transaction.category),
              color: const Color(0xFFF43F5E),
              size: 20,
            ),
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
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    if (transaction.wallet != null) ...[
                      const Text(
                        '  •  ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        transaction.wallet!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${Helpers.formatCurrency(transaction.amount)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF43F5E),
                ),
              ),
              Text(
                Helpers.formatTime(transaction.time),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
