import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                'Pool',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              elevation: 0,
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
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
        final isOpen = pool.poolStatus == 'open';
        final paidCount = pool.members.where((m) => m.status == 'paid').length;
        final declaredCount = pool.members
            .where((m) => m.status == 'declared')
            .length;

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
              pool.title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            actions: [
              if (isHost && isOpen)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () =>
                        _showCloseConfirmation(context, provider, pool.id),
                    icon: const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Color(0xFFF43F5E),
                    ),
                    label: const Text(
                      'Close',
                      style: TextStyle(
                        color: Color(0xFFF43F5E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // ── Status Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isOpen
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF334155), Color(0xFF475569)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isOpen
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF334155))
                              .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFFF87171),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    Text(
                      Helpers.formatCurrency(pool.amount),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target Amount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: Colors.white,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            label: 'Collected',
                            value: Helpers.formatCurrency(
                              pool.poolDeclaredTotal ?? 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            label: 'Remaining',
                            value: Helpers.formatCurrency(
                              ((pool.poolTarget ?? 0) -
                                      (pool.poolDeclaredTotal ?? 0))
                                  .clamp(0, double.infinity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Stats ──
              Row(
                children: [
                  _QuickStatCard(
                    icon: Icons.group_rounded,
                    label: 'Members',
                    value: '${pool.members.length}',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _QuickStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Paid',
                    value: '$paidCount',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _QuickStatCard(
                    icon: Icons.schedule_rounded,
                    label: 'Pending',
                    value: '${pool.members.length - paidCount - declaredCount}',
                    color: const Color(0xFF94A3B8),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Participants Section ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Participants',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pool.members.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              for (final m in pool.members)
                _MemberCard(
                  member: m,
                  isHost: isHost,
                  isPayer: m.id == pool.payerId,
                  isDark: isDark,
                  poolOpen: isOpen,
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

  void _showCloseConfirmation(
    BuildContext context,
    AppProvider provider,
    String poolId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Close Pool?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Once closed, members can no longer declare payments. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.closePool(poolId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close Pool'),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip (inside gradient card) ──
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
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
          const SizedBox(height: 2),
          Text(
            value,
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
    );
  }
}

// ── Quick Stat Card ──
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Card ──
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
    final IconData statusIcon;
    switch (member.status) {
      case 'paid':
        statusColor = const Color(0xFF10B981);
        statusText = 'Paid';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'declared':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Declared';
        statusIcon = Icons.schedule_rounded;
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    final cachedUser = provider.getCachedUser(member.id);

    // Avatar gradient based on status
    final List<Color> avatarGradient;
    if (member.status == 'paid') {
      avatarGradient = [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (isPayer) {
      avatarGradient = [const Color(0xFF2563EB), const Color(0xFF1E40AF)];
    } else {
      avatarGradient = [const Color(0xFF64748B), const Color(0xFF475569)];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: avatarGradient),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: cachedUser?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            cachedUser!.avatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          cachedUser?.initials ??
                              (member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : '?'),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cachedUser?.name ?? member.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPayer)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Host',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (member.amount > 0)
                        Text(
                          Helpers.formatCurrency(member.amount),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Text(
                          'No amount yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          if (poolOpen && !isPayer) ...[
            if (member.id == myId && member.status == 'pending') ...[
              Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: _DeclareButton(
                  provider: provider,
                  poolId: poolId,
                  memberId: member.id,
                  isDark: isDark,
                ),
              ),
            ],
            if (isHost && member.status == 'declared') ...[
              Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        provider.confirmPoolPayment(poolId, member.id),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Confirm Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
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
  final bool isDark;

  const _DeclareButton({
    required this.provider,
    required this.poolId,
    required this.memberId,
    required this.isDark,
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Your share ₹',
              hintStyle: TextStyle(
                color: widget.isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              filled: true,
              fillColor: widget.isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          child: const Text(
            'Declare',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
