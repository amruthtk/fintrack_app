import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../models/transaction.dart' as tx;

class SettlementItem {
  final tx.Transaction bill;
  final String personName;
  final String personId;
  final double amount;
  final String type;

  SettlementItem({
    required this.bill,
    required this.personName,
    required this.personId,
    required this.amount,
    required this.type,
  });
}

class SettlementCard extends StatelessWidget {
  final SettlementItem item;
  final bool isDark;
  final VoidCallback? onPay;
  final VoidCallback? onSettle;

  const SettlementCard({
    super.key,
    required this.item,
    required this.isDark,
    this.onPay,
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final isPay = item.type == 'pay';
    final color = isPay ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPay
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.personName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      item.bill.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatCurrency(item.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          if (isPay && onPay != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSettle,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Paid'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay UPI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isPay && onSettle != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Confirm Received'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const SectionTitle({super.key, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
