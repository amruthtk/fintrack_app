import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart' as tx;
import '../utils/helpers.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  DateTime _calculateNextDate(String startDate, String? frequency) {
    DateTime date;
    try {
      date = DateTime.parse(startDate);
    } catch (_) {
      date = DateTime.now();
    }
    final today = DateTime.now();

    while (date.isBefore(today)) {
      switch (frequency) {
        case 'Daily':
          date = date.add(const Duration(days: 1));
          break;
        case 'Weekly':
          date = date.add(const Duration(days: 7));
          break;
        case 'Quarterly':
          date = DateTime(date.year, date.month + 3, date.day);
          break;
        case 'Yearly':
          date = DateTime(date.year + 1, date.month, date.day);
          break;
        default: // Monthly
          date = DateTime(date.year, date.month + 1, date.day);
      }
    }
    return date;
  }

  double _monthlyEquivalent(double amount, String? frequency) {
    switch (frequency) {
      case 'Daily':
        return amount * 30;
      case 'Weekly':
        return amount * 4;
      case 'Quarterly':
        return amount / 3;
      case 'Yearly':
        return amount / 12;
      default: // Monthly
        return amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final subscriptions =
              provider.transactions.where((t) => t.isRecurring == true).toList()
                ..sort((a, b) {
                  final nextA = _calculateNextDate(a.date, a.frequency);
                  final nextB = _calculateNextDate(b.date, b.frequency);
                  return nextA.compareTo(nextB);
                });

          final monthlyTotal = subscriptions.fold<double>(
            0,
            (sum, s) => sum + _monthlyEquivalent(s.amount, s.frequency),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Monthly Burn Rate Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY BURN RATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatCurrency(monthlyTotal),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.repeat_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  '${subscriptions.length} Active Subscriptions',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),

              if (subscriptions.isEmpty)
                _EmptyState(isDark: isDark)
              else
                ...subscriptions.map(
                  (sub) => _SubscriptionCard(
                    sub: sub,
                    isDark: isDark,
                    nextDate: _calculateNextDate(sub.date, sub.frequency),
                    onCancel: () => _showCancelDialog(context, provider, sub),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    AppProvider provider,
    tx.Transaction sub,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 8),
            Text(
              'Cancel Subscription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text('Remove "${sub.title}" from recurring expenses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteTransaction(sub);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription cancelled'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Remove',
              style: TextStyle(color: Color(0xFFF43F5E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final tx.Transaction sub;
  final bool isDark;
  final DateTime nextDate;
  final VoidCallback onCancel;

  const _SubscriptionCard({
    required this.sub,
    required this.isDark,
    required this.nextDate,
    required this.onCancel,
  });

  Color _frequencyColor() {
    switch (sub.frequency) {
      case 'Daily':
        return const Color(0xFFF43F5E);
      case 'Weekly':
        return const Color(0xFFF59E0B);
      case 'Quarterly':
        return const Color(0xFF1E40AF);
      case 'Yearly':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _frequencyColor();
    final nextStr =
        '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            sub.frequency ?? 'Monthly',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sub.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(sub.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 10,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next: $nextStr',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: const Color(
                  0xFFF43F5E,
                ).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFF43F5E),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 40,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NO ACTIVE SUBSCRIPTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a recurring expense to track it here',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
