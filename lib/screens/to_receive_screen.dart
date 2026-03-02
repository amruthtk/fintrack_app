import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../widgets/social_components.dart';
import '../utils/helpers.dart';

class ToReceiveScreen extends StatelessWidget {
  const ToReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userId = provider.user?.id ?? '';
        final splits = provider.transactions
            .where((t) => t.type == 'split' && t.splitType != 'pool')
            .toList();

        // Collect all bills where others owe me
        final Map<String, List<SettlementItem>> receivablesByPerson = {};
        for (final s in splits) {
          if (s.payerId == userId) {
            for (final m in s.members) {
              if (m.id != userId && m.status != 'paid') {
                final debtor = provider.getCachedUser(m.id);
                receivablesByPerson
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
          }
        }

        final totalReceivable = receivablesByPerson.values
            .expand((v) => v)
            .fold(0.0, (sum, item) => sum + item.amount);
        final totalBills = receivablesByPerson.values.fold(
          0,
          (sum, items) => sum + items.length,
        );
        final sortedPersonIds = receivablesByPerson.keys.toList()
          ..sort((a, b) {
            final aTotal = receivablesByPerson[a]!.fold(
              0.0,
              (s, i) => s + i.amount,
            );
            final bTotal = receivablesByPerson[b]!.fold(
              0.0,
              (s, i) => s + i.amount,
            );
            return bTotal.compareTo(aTotal);
          });

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'To Receive',
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
          body: sortedPersonIds.isEmpty
              ? _buildEmpty(isDark)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    // ── Summary Header ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total to Receive',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(totalReceivable),
                                    style: GoogleFonts.inter(
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$totalBills pending ${totalBills == 1 ? 'bill' : 'bills'} from ${sortedPersonIds.length} ${sortedPersonIds.length == 1 ? 'person' : 'people'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Person Cards ──
                    ...sortedPersonIds.map((personId) {
                      final items = receivablesByPerson[personId]!;
                      final personTotal = items.fold(
                        0.0,
                        (s, i) => s + i.amount,
                      );
                      final user = provider.getCachedUser(personId);
                      final personName = items.first.personName;

                      return _PersonReceiveCard(
                        personId: personId,
                        personName: personName,
                        user: user,
                        items: items,
                        total: personTotal,
                        isDark: isDark,
                        provider: provider,
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        EmptyState(
          icon: Icons.arrow_downward_rounded,
          message: 'Nothing to collect.\nNo one owes you anything right now!',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _PersonReceiveCard extends StatefulWidget {
  final String personId;
  final String personName;
  final dynamic user;
  final List<SettlementItem> items;
  final double total;
  final bool isDark;
  final AppProvider provider;

  const _PersonReceiveCard({
    required this.personId,
    required this.personName,
    required this.user,
    required this.items,
    required this.total,
    required this.isDark,
    required this.provider,
  });

  @override
  State<_PersonReceiveCard> createState() => _PersonReceiveCardState();
}

class _PersonReceiveCardState extends State<_PersonReceiveCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: _expanded ? Radius.zero : const Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: widget.user?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              widget.user!.avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            Helpers.getInitials(widget.personName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.personName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} ${widget.items.length == 1 ? 'bill' : 'bills'} pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Helpers.formatCurrency(widget.total),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded bills
          if (_expanded) ...[
            Container(
              height: 1,
              color: widget.isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
            ),
            // Confirm received button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    for (final item in widget.items) {
                      widget.provider.settleSplit(item.bill.id, item.personId);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Confirmed payment from ${widget.personName}',
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // Individual bills
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: widget.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.bill.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Bill total: ${Helpers.formatCurrency(item.bill.amount)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Helpers.formatCurrency(item.amount),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            // Individual settle button
                            GestureDetector(
                              onTap: () {
                                widget.provider.settleSplit(
                                  item.bill.id,
                                  item.personId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as received'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}
