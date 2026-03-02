import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class GroupBillsScreen extends StatelessWidget {
  final String groupId;
  final String groupName;

  const GroupBillsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userId = provider.user?.id ?? '';
        final group = provider.groups.where((g) => g.id == groupId).firstOrNull;
        if (group == null) return const Scaffold(body: Center(child: Text('Group not found')));

        final groupSplits = provider.transactions
            .where((t) => t.type == 'split' && t.splitType != 'pool')
            .where((t) {
          // Primary: exact groupId match
          if (t.groupId == groupId) return true;
          // Fallback: member overlap for older bills without groupId
          if (t.groupId == null) {
            final memberIds = t.members.map((m) => m.id).toSet();
            return group.memberIds.toSet().containsAll(memberIds) &&
                memberIds.length > 1;
          }
          return false;
        }).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              '$groupName Bills',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          body: groupSplits.isEmpty
              ? _buildEmpty(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: groupSplits.length,
                  itemBuilder: (context, index) {
                    final t = groupSplits[index];
                    final payer = provider.getCachedUser(t.payerId ?? '');
                    final isMyBill = t.payerId == userId;

                    // Check if all settled
                    final allSettled = t.members
                        .where((m) => m.id != t.payerId)
                        .every((m) => m.status == 'paid');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Paid by ${isMyBill ? "You" : (payer?.name ?? "Unknown")}',
                                      style: const TextStyle(
                                        fontSize: 12,
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
                                    Helpers.formatCurrency(t.amount),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: allSettled
                                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      allSettled ? 'Settled' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: allSettled
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: t.members
                                .where((m) => m.id != t.payerId)
                                .map((m) {
                              final memberUser = provider.getCachedUser(m.id);
                              final isPaid = m.status == 'paid';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPaid
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                      size: 14,
                                      color: isPaid ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.id == userId ? 'You' : (memberUser?.name.split(' ').first ?? 'User'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isPaid ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                    Text(
                                      ' ${Helpers.formatCurrency(m.amount)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_rounded, size: 50, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Bills Yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Split a bill to see it here!',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
