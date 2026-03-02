import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final TextEditingController _bankCtrl = TextEditingController(text: '0');
  final TextEditingController _cashCtrl = TextEditingController(text: '0');
  final FocusNode _bankFocus = FocusNode();
  final FocusNode _cashFocus = FocusNode();
  bool _skipCash = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _bankCtrl.dispose();
    _cashCtrl.dispose();
    _bankFocus.dispose();
    _cashFocus.dispose();
    super.dispose();
  }

  double get bankValue => double.tryParse(_bankCtrl.text) ?? 0;
  double get cashValue =>
      _skipCash ? 0 : (double.tryParse(_cashCtrl.text) ?? 0);
  double get totalValue => bankValue + cashValue;

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutQuart);
      setState(() => _currentStep++);
      // Move focus to cash field after page transition
      Future.delayed(600.ms, () {
        if (mounted) {
          _bankFocus.unfocus();
          _cashFocus.requestFocus();
          // Select all text so user can type over the '0'
          _cashCtrl.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _cashCtrl.text.length,
          );
        }
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: 500.ms,
        curve: Curves.easeOutQuart,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleComplete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      final user = provider.user;
      final existingWallets = user?.wallets ?? [];

      // Only update balances for wallets the user already has — don't add new ones
      final newWallets = existingWallets.map((w) {
        if (w.id == 'bank') {
          return Wallet(
            id: 'bank',
            name: w.name,
            type: 'bank',
            balance: bankValue,
          );
        } else if (w.id == 'cash') {
          return Wallet(
            id: 'cash',
            name: w.name,
            type: 'cash',
            balance: cashValue,
          );
        }
        return w; // Keep credit card or any other wallet as-is
      }).toList();

      await provider.saveWallets(newWallets);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF2563EB,
                ).withValues(alpha: isDark ? 0.1 : 0.05),
              ),
            ).animate().fadeIn(duration: 1.seconds).scale(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          LucideIcons.x,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: Colors.white,
                              size: 32,
                            ),
                          )
                          .animate()
                          .scale(delay: 200.ms)
                          .shimmer(delay: 1.seconds),
                      const SizedBox(height: 16),
                      Text(
                            'Wealth Calibration',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .moveY(begin: 10, end: 0),
                      const SizedBox(height: 4),
                      Text(
                        "Let's sync your finances to get accurate tracking",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressIndicator(
                      1,
                      isActive: _currentStep == 1,
                      isDone: _currentStep > 1,
                    ),
                    const SizedBox(width: 8),
                    _buildProgressIndicator(
                      2,
                      isActive: _currentStep == 2,
                      isDone: false,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Step Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepPage(
                        index: 1,
                        isDark: isDark,
                        title: 'Bank Account Balance',
                        subtitle: 'Step 1',
                        icon: LucideIcons.landmark,
                        iconColor: const Color(0xFF3B82F6),
                        controller: _bankCtrl,
                        autoFocus: true,
                      ),
                      _buildStepPage(
                        index: 2,
                        isDark: isDark,
                        title: 'Cash in Hand',
                        subtitle: 'Step 2',
                        icon: LucideIcons.banknote,
                        iconColor: const Color(0xFF10B981),
                        controller: _cashCtrl,
                        isCash: true,
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 1)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                'Back',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : (_currentStep == 1
                                    ? _nextStep
                                    : _handleComplete),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentStep == 1
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentStep == 1
                                          ? 'Continue'
                                          : 'Complete Setup',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentStep == 1
                                          ? LucideIcons.arrowRight
                                          : LucideIcons.check,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Bank',
                        bankValue,
                        const Color(0xFF3B82F6),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      _buildSummaryItem(
                        'Cash',
                        _skipCash ? null : cashValue,
                        const Color(0xFF10B981),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      _buildSummaryItem(
                        'Total',
                        totalValue,
                        isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    int step, {
    required bool isActive,
    required bool isDone,
  }) {
    return AnimatedContainer(
      duration: 500.ms,
      width: isActive ? 48 : (isDone ? 32 : 32),
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2563EB)
            : (isDone
                  ? const Color(0xFF10B981)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildStepPage({
    required int index,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    bool isCash = false,
    bool autoFocus = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: iconColor,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).moveX(begin: 30, end: 0),
          const SizedBox(height: 32),

          if (isCash && _skipCash)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.smile,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cash tracking? No problem!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can add cash balances anytime from Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ).animate().scale()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'CURRENT BALANCE (APPROX.)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: controller == _bankCtrl ? _bankFocus : _cashFocus,
                  keyboardType: TextInputType.number,
                  enableInteractiveSelection: false,
                  autofocus: autoFocus,
                  onTap: () {
                    // Select all text on tap so user can type over the '0'
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );
                  },
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      if (text.length > 1 &&
                          text.startsWith('0') &&
                          !text.startsWith('0.')) {
                        final stripped = text.replaceFirst(RegExp(r'^0+'), '');
                        final result = stripped.isEmpty ? '0' : stripped;
                        return TextEditingValue(
                          text: result,
                          selection: TextSelection.collapsed(
                            offset: result.length,
                          ),
                        );
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (v) => setState(() {}),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "Don't worry about exact amounts. You can reconcile later!",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

          if (isCash) ...[
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => setState(() => _skipCash = !_skipCash),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF475569),
              ),
              child: Text(
                _skipCash ? '← I DO USE CASH' : "I DON'T USE CASH →",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double? value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value == null
              ? '—'
              : Helpers.formatCurrency(value).replaceAll('₹', '₹'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
