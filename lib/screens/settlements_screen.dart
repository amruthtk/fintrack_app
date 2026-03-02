import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../widgets/social_components.dart';
import '../services/upi_service.dart';
import '../utils/helpers.dart';

class SettlementsScreen extends StatefulWidget {
  final String? initialTab;
  const SettlementsScreen({super.key, this.initialTab});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  final Set<String> _expandedPersons = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userId = provider.user?.id ?? '';
        final splits = provider.transactions
            .where((t) => t.type == 'split' && t.splitType != 'pool')
            .toList();

        // People who owe ME (receivables)
        final Map<String, List<SettlementItem>> theyOweMe = {};
        // People I owe (payables)
        final Map<String, List<SettlementItem>> iOweThem = {};

        for (final s in splits) {
          if (s.payerId == userId) {
            // I paid → others owe me
            for (final m in s.members) {
              if (m.id != userId && m.status != 'paid') {
                final debtor = provider.getCachedUser(m.id);
                theyOweMe
                    .putIfAbsent(m.id, () => [])
                    .add(
                      SettlementItem(
                        bill: s,
                        personName: debtor?.name ?? 'Unknown',
                        personId: m.id,
                        amount: m.amount,
                        type: 'receive',
                      ),
                    );
              }
            }
          } else {
            final myEntry = s.members.where((m) => m.id == userId).firstOrNull;
            if (myEntry != null && myEntry.status != 'paid') {
              final payerId = s.payerId ?? '';
              final payer = provider.getCachedUser(payerId);
              iOweThem
                  .putIfAbsent(payerId, () => [])
                  .add(
                    SettlementItem(
                      bill: s,
                      personName: payer?.name ?? 'Unknown',
                      personId: payerId,
                      amount: myEntry.amount,
                      type: 'pay',
                    ),
                  );
            }
          }
        }

        // Compute totals
        double totalReceivable = 0;
        for (final items in theyOweMe.values) {
          for (final item in items) {
            totalReceivable += item.amount;
          }
        }
        double totalPayable = 0;
        for (final items in iOweThem.values) {
          for (final item in items) {
            totalPayable += item.amount;
          }
        }

        // Sort by highest amount
        final sortedReceivableIds = theyOweMe.keys.toList()
          ..sort((a, b) {
            final aT = theyOweMe[a]!.fold(0.0, (s, i) => s + i.amount);
            final bT = theyOweMe[b]!.fold(0.0, (s, i) => s + i.amount);
            return bT.compareTo(aT);
          });
        final sortedPayableIds = iOweThem.keys.toList()
          ..sort((a, b) {
            final aT = iOweThem[a]!.fold(0.0, (s, i) => s + i.amount);
            final bT = iOweThem[b]!.fold(0.0, (s, i) => s + i.amount);
            return bT.compareTo(aT);
          });

        final isEmpty = sortedReceivableIds.isEmpty && sortedPayableIds.isEmpty;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Settlements',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          body: isEmpty
              ? _buildEmptyState(isDark)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    // ── Summary Card ──
                    _buildSummaryCard(isDark, totalReceivable, totalPayable),
                    const SizedBox(height: 24),

                    // ── SECTION: They Owe You ──
                    if (sortedReceivableIds.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.arrow_downward_rounded,
                        title: 'They Owe You',
                        total: totalReceivable,
                        count: sortedReceivableIds.length,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      ...sortedReceivableIds.map((personId) {
                        final items = theyOweMe[personId]!;
                        final total = items.fold(0.0, (s, i) => s + i.amount);
                        final user = provider.getCachedUser(personId);
                        return _PersonCard(
                          personId: personId,
                          personName: items.first.personName,
                          user: user,
                          items: items,
                          total: total,
                          isDark: isDark,
                          isOweMe: true,
                          isExpanded: _expandedPersons.contains('r_$personId'),
                          onToggle: () {
                            setState(() {
                              final key = 'r_$personId';
                              if (_expandedPersons.contains(key)) {
                                _expandedPersons.remove(key);
                              } else {
                                _expandedPersons.add(key);
                              }
                            });
                          },
                          provider: provider,
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // ── SECTION: You Owe Them ──
                    if (sortedPayableIds.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.arrow_upward_rounded,
                        title: 'You Owe',
                        total: totalPayable,
                        count: sortedPayableIds.length,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      ...sortedPayableIds.map((personId) {
                        final items = iOweThem[personId]!;
                        final total = items.fold(0.0, (s, i) => s + i.amount);
                        final user = provider.getCachedUser(personId);
                        return _PersonCard(
                          personId: personId,
                          personName: items.first.personName,
                          user: user,
                          items: items,
                          total: total,
                          isDark: isDark,
                          isOweMe: false,
                          isExpanded: _expandedPersons.contains('p_$personId'),
                          onToggle: () {
                            setState(() {
                              final key = 'p_$personId';
                              if (_expandedPersons.contains(key)) {
                                _expandedPersons.remove(key);
                              } else {
                                _expandedPersons.add(key);
                              }
                            });
                          },
                          provider: provider,
                        );
                      }),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        EmptyState(
          icon: Icons.handshake_rounded,
          message: 'No pending settlements.\nYou\'re all clear!',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    double totalReceivable,
    double totalPayable,
  ) {
    final netBalance = totalReceivable - totalPayable;
    final isPositive = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF2563EB,
            ).withValues(alpha: isDark ? 0.1 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Net Balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : '-'}${Helpers.formatCurrency(netBalance.abs())}',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Overall, people owe you' : 'Overall, you owe others',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'To Receive',
                  amount: totalReceivable,
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryChip(
                  label: 'To Pay',
                  amount: totalPayable,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required double total,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const Spacer(),
        Text(
          Helpers.formatCurrency(total),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Person Card ──
class _PersonCard extends StatelessWidget {
  final String personId;
  final String personName;
  final dynamic user;
  final List<SettlementItem> items;
  final double total;
  final bool isDark;
  final bool isOweMe;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppProvider provider;

  const _PersonCard({
    required this.personId,
    required this.personName,
    required this.user,
    required this.items,
    required this.total,
    required this.isDark,
    required this.isOweMe,
    required this.isExpanded,
    required this.onToggle,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isOweMe
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: isExpanded ? Radius.zero : const Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOweMe
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [
                                const Color(0xFFF59E0B),
                                const Color(0xFFD97706),
                              ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: user?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.avatarUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            Helpers.getInitials(personName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${items.length} ${items.length == 1 ? 'bill' : 'bills'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(total),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          // Expanded
          if (isExpanded) ...[
            Container(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: isOweMe
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          for (final item in items) {
                            provider.settleSplit(item.bill.id, item.personId);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Confirmed payment from $personName',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Confirm All Received'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              for (final item in items) {
                                provider.requestSettlement(
                                  item.bill.id,
                                  provider.user?.id ?? '',
                                );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Settlement request sent to $personName',
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark Paid'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePay(context, provider),
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: const Text('Pay UPI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Bill breakdown
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.receipt_rounded,
                            size: 12,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.bill.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Helpers.formatCurrency(item.amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePay(BuildContext context, AppProvider provider) async {
    final payer = provider.getCachedUser(personId);
    final upiId = payer?.upiId;
    if (upiId == null || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${payer?.name ?? 'This user'} hasn't set up their UPI ID yet",
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final upiUrl = UpiService.buildUpiUrl(
      upiId: upiId,
      payeeName: payer?.name ?? 'Friend',
      amount: total,
      note: 'Settlement for ${items.length} bills',
    );

    final launched = await UpiService.launchUpiApp(upiUrl);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No UPI app found on this device'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
    }
  }
}

// ── Summary Chip ──
class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  Helpers.formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
