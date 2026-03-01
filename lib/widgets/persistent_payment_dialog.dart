import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class PersistentPaymentDialog extends StatelessWidget {
  final Map<String, dynamic> pendingData;

  const PersistentPaymentDialog({super.key, required this.pendingData});

  static void show(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PersistentPaymentDialog(pendingData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = pendingData['amount'] as double;
    final appName = pendingData['appName'] as String;
    final walletId = pendingData['walletId'] as String?;
    final walletType = pendingData['walletType'] as String?;
    final merchantName = pendingData['merchantName'] as String;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Have you completed your\nrecent external payment?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please confirm the transaction status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Amount (External)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Banking App',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        appName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppProvider>().setPendingPayment(null);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF43F5E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Report Failed\nPayment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF43F5E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExpenditureDetails(context, amount, walletId, walletType, merchantName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Success',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenditureDetails(
    BuildContext context,
    double amount,
    String? walletId,
    String? walletType,
    String merchantName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _ExpenditureDetailsSheet(
        amount: amount,
        walletId: walletId,
        walletType: walletType,
        merchantName: merchantName,
      ),
    );
  }
}

class _ExpenditureDetailsSheet extends StatefulWidget {
  final double amount;
  final String? walletId;
  final String? walletType;
  final String merchantName;

  const _ExpenditureDetailsSheet({
    required this.amount,
    required this.walletId,
    required this.walletType,
    required this.merchantName,
  });

  @override
  State<_ExpenditureDetailsSheet> createState() => _ExpenditureDetailsSheetState();
}

class _ExpenditureDetailsSheetState extends State<_ExpenditureDetailsSheet> {
  late final TextEditingController titleCtrl;
  String selectedCategory = 'Shopping';
  bool isSplit = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: 'Paid to ${widget.merchantName}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const categories = [
      'Food', 'Transport', 'Travel', 'Shopping', 'Entertainment',
      'Health', 'Bills', 'Education', 'Home', 'Subscription', 'Other'
    ];
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        Text('₹${widget.amount.toStringAsFixed(widget.amount == widget.amount.roundToDouble() ? 0 : 2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  hintText: 'What was this for?',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final active = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: active ? null : Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isSplit = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isSplit ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_rounded, size: 16, color: !isSplit ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            const SizedBox(width: 6),
                            Text('Self', style: TextStyle(fontWeight: FontWeight.w700, color: !isSplit ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isSplit = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSplit ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_rounded, size: 16, color: isSplit ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            const SizedBox(width: 6),
                            Text('Split', style: TextStyle(fontWeight: FontWeight.w700, color: isSplit ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<AppProvider>();
                  
                  if (isSplit) {
                    Navigator.pop(context);
                    context.push(
                      '/split?amount=${widget.amount.toStringAsFixed(2)}&title=${Uri.encodeComponent(titleCtrl.text.trim())}',
                    );
                    // Clear pending since we're moving to a specific flow
                    provider.setPendingPayment(null);
                    return;
                  }

                  final wallet = provider.user?.wallets.firstWhere((w) => w.id == widget.walletId).name ?? 'Unknown';
                  
                  await provider.createBill({
                    'title': titleCtrl.text.trim(),
                    'amount': widget.amount,
                    'type': 'expense',
                    'category': selectedCategory,
                    'wallet': wallet,
                    'walletType': widget.walletType,
                    'paymentMode': 'upi',
                    'date': Helpers.todayDate(),
                    'time': Helpers.currentTime(),
                  });
                  
                  provider.setPendingPayment(null);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isSplit ? 'Continue to Split' : 'Record Payment', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
