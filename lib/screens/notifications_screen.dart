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
                        typeColor = const Color(0xFF6366F1);
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
                                  0xFF6366F1,
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
                                    onPressed: () => provider.approveSettlement(
                                      notif.id,
                                      notif.billId ?? '',
                                      notif.memberId ?? '',
                                      notif.amount ?? 0,
                                      notif.fromUserId,
                                      notif.wallet,
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
                                    color: Color(0xFF6366F1),
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
}
