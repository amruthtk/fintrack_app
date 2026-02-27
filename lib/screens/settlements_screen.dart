import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _SettlementsScreenState extends State<SettlementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedPersons = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'payables' ? 1 : 0,
    );
    // Refresh transactions so newly created splits from other users are visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      final userId = provider.user?.id;
      if (userId != null) {
        provider.fetchTransactions(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userId = provider.user?.id ?? '';
        final splits = provider.transactions
            .where((t) => t.type == 'split' && t.splitType != 'pool')
            .toList();

        final rawPayables = <SettlementItem>[];
        for (final s in splits) {
          if (s.payerId != userId) {
            final myEntry = s.members.where((m) => m.id == userId).firstOrNull;
            if (myEntry != null && myEntry.status != 'paid') {
              final payer = provider.getCachedUser(s.payerId ?? '');
              rawPayables.add(
                SettlementItem(
                  bill: s,
                  personName: payer?.name ?? 'Unknown',
                  personId: s.payerId ?? '',
                  amount: myEntry.amount,
                  type: 'pay',
                ),
              );
            }
          }
        }

        final rawReceivables = <SettlementItem>[];
        for (final s in splits) {
          if (s.payerId == userId) {
            for (final m in s.members) {
              if (m.id != userId && m.status != 'paid') {
                final debtor = provider.getCachedUser(m.id);
                rawReceivables.add(
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

        // Grouping logic
        Map<String, List<SettlementItem>> groupItems(
          List<SettlementItem> items,
        ) {
          final groups = <String, List<SettlementItem>>{};
          for (final item in items) {
            groups.putIfAbsent(item.personId, () => []).add(item);
          }
          return groups;
        }

        final groupedPayables = groupItems(rawPayables);
        final groupedReceivables = groupItems(rawReceivables);

        return Scaffold(
          backgroundColor: Colors.transparent,
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
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'To Receive'),
                Tab(text: 'To Pay'),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSettlementList(
                  context,
                  provider,
                  groupedReceivables,
                  isDark,
                  'receive',
                ),
                _buildSettlementList(
                  context,
                  provider,
                  groupedPayables,
                  isDark,
                  'pay',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettlementList(
    BuildContext context,
    AppProvider provider,
    Map<String, List<SettlementItem>> groupedItems,
    bool isDark,
    String type,
  ) {
    if (groupedItems.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_rounded,
        message: 'All settled up! 🎉',
        isDark: isDark,
      );
    }

    final sortedIds = groupedItems.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: sortedIds.length,
      itemBuilder: (context, index) {
        final personId = sortedIds[index];
        final items = groupedItems[personId]!;
        final total = items.fold(0.0, (sum, item) => sum + item.amount);
        final personName = items.first.personName;
        final isExpanded = _expandedPersons.contains(personId);
        final user = provider.getCachedUser(personId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF6366F1,
                  ).withValues(alpha: 0.1),
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          Helpers.getInitials(personName),
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  personName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  '${items.length} pending bills',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Helpers.formatCurrency(total),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: type == 'pay'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPersons.remove(personId);
                    } else {
                      _expandedPersons.add(personId);
                    }
                  });
                },
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SettlementCard(
                          item: item,
                          isDark: isDark,
                          onPay: type == 'pay'
                              ? () => _handlePay(context, provider, item)
                              : null,
                          onSettle: () {
                            if (type == 'pay') {
                              _showPaymentMethodPicker(context, provider, item);
                            } else {
                              provider.settleSplit(item.bill.id, item.personId);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodPicker(
    BuildContext context,
    AppProvider provider,
    SettlementItem item,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = provider.user?.wallets ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How did you pay?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select payment method for ₹${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Wallet options
              ...wallets.map((w) {
                final icon = w.type == 'cash'
                    ? Icons.account_balance_wallet_rounded
                    : w.type == 'credit'
                    ? Icons.credit_card_rounded
                    : Icons.account_balance_rounded;
                final color = w.type == 'cash'
                    ? const Color(0xFF10B981)
                    : w.type == 'credit'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6366F1);
                return _paymentOption(
                  context: ctx,
                  icon: icon,
                  color: color,
                  title: w.name,
                  subtitle: '₹${w.balance.toStringAsFixed(0)} available',
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await provider.requestSettlement(
                        item.bill.id,
                        provider.user?.id ?? '',
                        paymentMethod: w.type,
                        walletId: w.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment marked via ${w.name}'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: const Color(0xFFF43F5E),
                          ),
                        );
                      }
                    }
                  },
                );
              }),
              // UPI (already paid externally)
              _paymentOption(
                context: ctx,
                icon: Icons.phone_android_rounded,
                color: const Color(0xFF3B82F6),
                title: 'UPI (Already Paid)',
                subtitle: 'Paid via external UPI app',
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.requestSettlement(
                    item.bill.id,
                    provider.user?.id ?? '',
                    paymentMethod: 'upi',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment marked via UPI'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
              // Compensated (bought something)
              _paymentOption(
                context: ctx,
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFFEC4899),
                title: 'Compensated',
                subtitle: 'Bought something for them instead',
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.requestSettlement(
                    item.bill.id,
                    provider.user?.id ?? '',
                    paymentMethod: 'compensated',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as compensated'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePay(
    BuildContext context,
    AppProvider provider,
    SettlementItem item,
  ) async {
    // Try cache first, then fetch fresh from Firestore if needed
    var payer = provider.getCachedUser(item.personId);
    if (payer == null || (payer.upiId == null || payer.upiId!.isEmpty)) {
      // Fetch fresh user data from Firestore
      final fetched = await provider.fetchUsersByIds([
        item.personId,
      ], force: true);
      if (fetched.isNotEmpty) {
        payer = fetched.first;
      }
    }
    final upiId = payer?.upiId;
    if (upiId == null || upiId.isEmpty) {
      if (!context.mounted) return;
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
      amount: item.amount,
      note: item.bill.title,
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
