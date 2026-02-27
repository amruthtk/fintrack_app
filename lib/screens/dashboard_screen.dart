import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final stats = provider.dashboardData;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPrivate = provider.isPrivate;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ).createShader(bounds),
                          child: const Text(
                            'FinTrack',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      // Notification bell
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF334155),
                                size: 22,
                              ),
                            ),
                            if (provider.unreadCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF43F5E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${provider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile button (Repositioned here)
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.5)
                                  : const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? Text(
                                    Helpers.getInitials(user?.name ?? 'G'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6366F1),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Total Balance Card
                  _BalanceCard(
                    totalBalance: user?.totalBalance ?? 0,
                    cashBalance:
                        (user == null ||
                            user.wallets.any((w) => w.type == 'cash'))
                        ? (user?.wallets
                                  .where((w) => w.type == 'cash')
                                  .fold<double>(0.0, (s, w) => s + w.balance) ??
                              0.0)
                        : null,
                    bankBalance:
                        (user == null ||
                            user.wallets.any((w) => w.type == 'bank'))
                        ? (user?.wallets
                                  .where((w) => w.type == 'bank')
                                  .fold<double>(0.0, (s, w) => s + w.balance) ??
                              0.0)
                        : null,
                    creditBalance:
                        (user == null ||
                            user.wallets.any((w) => w.type == 'credit'))
                        ? (user?.wallets
                                  .where((w) => w.type == 'credit')
                                  .fold<double>(0.0, (s, w) => s + w.balance) ??
                              0.0)
                        : null,
                    isPrivate: isPrivate,
                    isDark: isDark,
                    onTogglePrivacy: () =>
                        provider.isPrivate = !provider.isPrivate,
                  ),

                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Spent',
                          value: stats.totalSpent,
                          icon: Icons.trending_down_rounded,
                          color: const Color(0xFFF43F5E),
                          isPrivate: isPrivate,
                          isDark: isDark,
                          onTap: () => context.push('/today-spent'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'To Pay',
                          value: stats.toPay,
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFF59E0B),
                          isPrivate: isPrivate,
                          isDark: isDark,
                          onTap: () =>
                              context.push('/to-pay'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'To Get',
                          value: stats.toReceive,
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF10B981),
                          isPrivate: isPrivate,
                          isDark: isDark,
                          onTap: () =>
                              context.push('/to-receive'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _QuickActions(isDark: isDark),

                  const SizedBox(height: 24),

                  // Recent Activity
                  _RecentActivity(
                    activities: provider.recentActivities,
                    allTransactions: provider.transactions,
                    isPrivate: isPrivate,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Balance Card ---
class _BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double? cashBalance;
  final double? bankBalance;
  final double? creditBalance;
  final bool isPrivate;
  final bool isDark;
  final VoidCallback onTogglePrivacy;

  const _BalanceCard({
    required this.totalBalance,
    this.cashBalance,
    this.bankBalance,
    this.creditBalance,
    required this.isPrivate,
    required this.isDark,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPrivate
                        ? '₹ ••••••'
                        : Helpers.formatCurrency(totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTogglePrivacy,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPrivate
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (cashBalance != null) ...[
                  _buildWalletChip(
                    'Cash',
                    cashBalance!,
                    Icons.money_rounded,
                    const Color(0xFF10B981),
                    onTap: () => context.push('/transactions?wallet=Cash'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (bankBalance != null) ...[
                  _buildWalletChip(
                    'Bank',
                    bankBalance!,
                    Icons.account_balance_rounded,
                    const Color(0xFF3B82F6),
                    onTap: () => context.push('/transactions?wallet=Bank'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (creditBalance != null) ...[
                  _buildWalletChip(
                    'Credit',
                    creditBalance!,
                    Icons.credit_card_rounded,
                    const Color(0xFF8B5CF6),
                    onTap: () => context.push('/transactions?wallet=Credit'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletChip(
    String label,
    double balance,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isPrivate ? '••••' : Helpers.formatCurrency(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Stat Card ---
class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isPrivate;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isPrivate,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
            alpha: onTap != null ? 1.0 : 0.8,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
          border: onTap != null
              ? Border.all(color: color.withValues(alpha: 0.1), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isPrivate ? '•••' : Helpers.formatCurrency(value),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Quick Actions ---
class _QuickActions extends StatelessWidget {
  final bool isDark;
  const _QuickActions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionChip(
              icon: Icons.handshake_rounded,
              label: 'Settlements',
              onTap: () => context.push('/settlements'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _ActionChip(
              icon: Icons.savings_rounded,
              label: 'Pools',
              onTap: () => context.push('/pools'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Recent Activity ---
class _RecentActivity extends StatelessWidget {
  final List activities;
  final List allTransactions;
  final bool isPrivate;
  final bool isDark;

  const _RecentActivity({
    required this.activities,
    required this.allTransactions,
    required this.isPrivate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final display = activities.isNotEmpty
        ? activities.take(5).toList()
        : allTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              activities.isNotEmpty ? "Today's Activity" : 'Recent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/transactions'),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (display.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No transactions yet. Tap + to start!',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        for (final tx in display)
          _TransactionTile(tx: tx, isPrivate: isPrivate, isDark: isDark),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic tx;
  final bool isPrivate;
  final bool isDark;

  const _TransactionTile({
    required this.tx,
    required this.isPrivate,
    required this.isDark,
  });

  IconData _getIcon() {
    switch (tx.category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Bills':
        return Icons.receipt_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _getColor() {
    switch (tx.type) {
      case 'income':
        return const Color(0xFF10B981);
      case 'split':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFF43F5E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                  tx.title.isNotEmpty ? tx.title : tx.category,
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
                  tx.category,
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
          Text(
            isPrivate
                ? '•••'
                : '${tx.type == 'income' ? '+' : '-'}${Helpers.formatCurrency(tx.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
