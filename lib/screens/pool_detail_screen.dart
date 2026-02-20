import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../models/transaction.dart' as tx;

class PoolDetailScreen extends StatelessWidget {
  final String poolId;
  const PoolDetailScreen({super.key, required this.poolId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final pool = provider.transactions
            .where((t) => t.id == poolId)
            .firstOrNull;

        if (pool == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pool')),
            body: const Center(child: Text('Pool not found')),
          );
        }

        final isHost = pool.payerId == provider.user?.id;
        final progress = (pool.poolTarget ?? 0) > 0
            ? ((pool.poolDeclaredTotal ?? 0) / (pool.poolTarget ?? 1)).clamp(
                0.0,
                1.0,
              )
            : 0.0;

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
              pool.title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (isHost && pool.poolStatus == 'open')
                TextButton(
                  onPressed: () => provider.closePool(pool.id),
                  child: const Text(
                    'Close Pool',
                    style: TextStyle(color: Color(0xFFF43F5E)),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: pool.poolStatus == 'open'
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF334155), Color(0xFF475569)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      Helpers.formatCurrency(pool.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${Helpers.formatCurrency(pool.poolDeclaredTotal ?? 0)} collected',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pool.poolStatus == 'open' ? '🟢 Open' : '🔴 Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Members
              Text(
                'Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              for (final m in pool.members)
                _MemberCard(
                  member: m,
                  isHost: isHost,
                  isPayer: m.id == pool.payerId,
                  isDark: isDark,
                  poolOpen: pool.poolStatus == 'open',
                  myId: provider.user?.id ?? '',
                  provider: provider,
                  poolId: pool.id,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final tx.TransactionMember member;
  final bool isHost;
  final bool isPayer;
  final bool isDark;
  final bool poolOpen;
  final String myId;
  final AppProvider provider;
  final String poolId;

  const _MemberCard({
    required this.member,
    required this.isHost,
    required this.isPayer,
    required this.isDark,
    required this.poolOpen,
    required this.myId,
    required this.provider,
    required this.poolId,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusText;
    switch (member.status) {
      case 'paid':
        statusColor = const Color(0xFF10B981);
        statusText = 'Paid';
        break;
      case 'declared':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Declared';
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusText = 'Pending';
    }

    final cachedUser = provider.getCachedUser(member.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(
                  0xFF6366F1,
                ).withValues(alpha: 0.15),
                radius: 18,
                child: Text(
                  cachedUser?.initials ??
                      (member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?'),
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cachedUser?.name ?? member.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isPayer)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (member.amount > 0)
                      Text(
                        Helpers.formatCurrency(member.amount),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          // Action buttons
          if (poolOpen && !isPayer) ...[
            const SizedBox(height: 10),
            if (member.id == myId && member.status == 'pending')
              _DeclareButton(
                provider: provider,
                poolId: poolId,
                memberId: member.id,
              ),
            if (isHost && member.status == 'declared')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      provider.confirmPoolPayment(poolId, member.id),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Confirm Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DeclareButton extends StatefulWidget {
  final AppProvider provider;
  final String poolId;
  final String memberId;

  const _DeclareButton({
    required this.provider,
    required this.poolId,
    required this.memberId,
  });

  @override
  State<_DeclareButton> createState() => _DeclareButtonState();
}

class _DeclareButtonState extends State<_DeclareButton> {
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Your share ₹',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(_amountCtrl.text);
            if (amount != null && amount > 0) {
              await widget.provider.declarePoolShare(
                widget.poolId,
                widget.memberId,
                amount,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Declare'),
        ),
      ],
    );
  }
}
