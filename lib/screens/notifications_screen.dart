import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
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
              'Notifications',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            actions: [
              if (provider.notifications.isNotEmpty)
                TextButton(
                  onPressed: () => provider.clearNotifications(),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Color(0xFFF43F5E)),
                  ),
                ),
            ],
          ),
          body: provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications',
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
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = provider.notifications[index];
                    final Color typeColor;
                    final IconData typeIcon;

                    switch (notif.type) {
                      case 'settlement_request':
                        typeColor = const Color(0xFFF59E0B);
                        typeIcon = Icons.payments_rounded;
                        break;
                      case 'settlement_approved':
                        typeColor = const Color(0xFF10B981);
                        typeIcon = Icons.check_circle_rounded;
                        break;
                      case 'pool_invite':
                        typeColor = const Color(0xFF06B6D4);
                        typeIcon = Icons.savings_rounded;
                        break;
                      default:
                        typeColor = const Color(0xFF2563EB);
                        typeIcon = Icons.call_split_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(notif.read ? 0xFF1E293B : 0xFF1E2A3B)
                            : Color(notif.read ? 0xFFFFFFFF : 0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                        border: notif.read
                            ? null
                            : Border.all(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.2),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  typeIcon,
                                  color: typeColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'from ${notif.fromUserName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (notif.amount != null)
                                Text(
                                  Helpers.formatCurrency(notif.amount!),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: typeColor,
                                  ),
                                ),
                            ],
                          ),

                          // Actions for settlement requests
                          if (notif.type == 'settlement_request' &&
                              notif.status == 'pending') ...[
                            // Show how debtor claims to have paid
                            if (notif.paymentMethod != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _paymentMethodIcon(notif.paymentMethod!),
                                      size: 14,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Paid via ${_paymentMethodLabel(notif.paymentMethod!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        provider.deleteNotification(notif.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFF43F5E),
                                      side: const BorderSide(
                                        color: Color(0xFFF43F5E),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _showReceiveWalletPicker(
                                      context,
                                      provider,
                                      notif,
                                      isDark,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Mark as read
                          if (!notif.read &&
                              notif.type != 'settlement_request') ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => provider.markAsRead(notif.id),
                                child: const Text(
                                  'Mark as read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.account_balance_wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'upi':
        return Icons.phone_android_rounded;
      case 'compensated':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank Transfer';
      case 'credit':
        return 'Credit Card';
      case 'upi':
        return 'UPI';
      case 'compensated':
        return 'Compensation';
      default:
        return 'Other';
    }
  }

  void _showReceiveWalletPicker(
    BuildContext context,
    AppProvider provider,
    dynamic notif,
    bool isDark,
  ) {
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
                'Where did you receive the payment?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${notif.fromUserName} paid ₹${(notif.amount ?? 0).toStringAsFixed(0)}${notif.paymentMethod != null ? ' via ${_paymentMethodLabel(notif.paymentMethod!)}' : ''}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Wallet options (excluding credit cards for receiving)
              ...wallets.where((w) => w.type != 'credit').map((w) {
                final icon = w.type == 'cash'
                    ? Icons.account_balance_wallet_rounded
                    : Icons.account_balance_rounded;
                final color = w.type == 'cash'
                    ? const Color(0xFF10B981)
                    : const Color(0xFF2563EB);
                return _walletOption(
                  context: ctx,
                  icon: icon,
                  color: color,
                  title: w.name,
                  subtitle: '₹${w.balance.toStringAsFixed(0)} current balance',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.approveSettlement(
                      notif.id,
                      notif.billId ?? '',
                      notif.memberId ?? '',
                      notif.amount ?? 0,
                      notif.fromUserId,
                      notif.wallet,
                      receivedWalletId: w.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Settlement approved — ₹${(notif.amount ?? 0).toStringAsFixed(0)} added to ${w.name}',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                );
              }),
              // No wallet tracking option
              _walletOption(
                context: ctx,
                icon: Icons.do_not_disturb_alt_rounded,
                color: const Color(0xFF94A3B8),
                title: 'Don\'t track',
                subtitle: 'Approve without adding to any wallet',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  provider.approveSettlement(
                    notif.id,
                    notif.billId ?? '',
                    notif.memberId ?? '',
                    notif.amount ?? 0,
                    notif.fromUserId,
                    null, // no wallet
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settlement approved'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _walletOption({
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
}
