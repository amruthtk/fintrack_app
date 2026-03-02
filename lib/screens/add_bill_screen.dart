import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class AddBillScreen extends StatefulWidget {
  final String initialType;
  final bool lockType;
  const AddBillScreen({
    super.key,
    this.initialType = 'expense',
    this.lockType = false,
  });

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  late String _type;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Other';
  String? _selectedWalletId;
  String? _selectedPaymentMode;
  bool _isSubmitting = false;
  bool _showCalculator = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'Monthly';

  static const expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Education',
    'Home',
    'Subscription',
    'Other',
  ];

  static const incomeCategories = [
    'Salary',
    'Freelance',
    'Bonus',
    'Investment',
    'Gift',
    'Other',
  ];

  static const categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Travel': Icons.flight_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.medical_services_rounded,
    'Bills': Icons.receipt_rounded,
    'Education': Icons.school_rounded,
    'Home': Icons.home_rounded,
    'Subscription': Icons.subscriptions_rounded,
    'Salary': Icons.work_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Bonus': Icons.card_giftcard_rounded,
    'Investment': Icons.trending_up_rounded,
    'Gift': Icons.redeem_rounded,
    'Other': Icons.category_rounded,
  };

  final Map<String, List<Map<String, dynamic>>> _walletModes = {
    'bank': [
      {'id': 'upi', 'name': 'UPI', 'icon': Icons.smartphone_rounded},
      {'id': 'debit', 'name': 'Debit Card', 'icon': Icons.credit_card_rounded},
      {'id': 'netbanking', 'name': 'Net Banking', 'icon': Icons.public_rounded},
    ],
    'cash': [
      {'id': 'handover', 'name': 'Cash', 'icon': Icons.payments_rounded},
    ],
    'credit': [
      {'id': 'swipe', 'name': 'Card Swipe', 'icon': Icons.credit_card_rounded},
      {'id': 'gateway', 'name': 'Online Gateway', 'icon': Icons.public_rounded},
    ],
  };

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _titleCtrl.addListener(_autoSetCategory);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_autoSetCategory);
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _autoSetCategory() {
    if (_type != 'expense') return;
    final m = _titleCtrl.text.toLowerCase();
    if (m.isEmpty) return;

    String? match;
    if (m.contains('netflix') ||
        m.contains('spotify') ||
        m.contains('prime') ||
        m.contains('hulu') ||
        m.contains('disney')) {
      match = 'Subscription';
    } else if (m.contains('uber') ||
        m.contains('ola') ||
        m.contains('rapido') ||
        m.contains('lyft')) {
      match = 'Transport';
    } else if (m.contains('swiggy') ||
        m.contains('zomato') ||
        m.contains('mcdonald') ||
        m.contains('starbucks') ||
        m.contains('domino')) {
      match = 'Food';
    } else if (m.contains('amazon') ||
        m.contains('flipkart') ||
        m.contains('myntra') ||
        m.contains('apple') ||
        m.contains('meesho')) {
      match = 'Shopping';
    } else if (m.contains('inox') ||
        m.contains('pvr') ||
        m.contains('bookmyshow')) {
      match = 'Entertainment';
    } else if (m.contains('hospital') ||
        m.contains('pharma') ||
        m.contains('medic') ||
        m.contains('doctor') ||
        m.contains('apollo')) {
      match = 'Health';
    } else if (m.contains('electricity') ||
        m.contains('water') ||
        m.contains('wifi') ||
        m.contains('jio') ||
        m.contains('airtel')) {
      match = 'Bills';
    } else if (m.contains('rent') ||
        m.contains('maintenance') ||
        m.contains('society')) {
      match = 'Home';
    }

    if (match != null && match != _category) {
      setState(() => _category = match!);
    }
  }

  void _evaluateExpression(String expr) {
    try {
      // Remove anything except digits and math operators
      final sanitized = expr.replaceAll(RegExp(r'[^0-9+\-*/.]'), '');
      if (sanitized.isEmpty) return;

      // Simple recursive descent for basic math
      final result = _parseMath(sanitized);
      if (result != null && !result.isNaN && result.isFinite) {
        _amountCtrl.text = result == result.roundToDouble()
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
      }
    } catch (_) {}
  }

  double? _parseMath(String expr) {
    final parts = expr.split(RegExp(r'(?=[+\-])|(?<=[+\-])'));
    double result = 0;
    double sign = 1;
    for (var part in parts) {
      if (part == '+') {
        sign = 1;
      } else if (part == '-') {
        sign = -1;
      } else {
        // Handle multiplication and division
        final tokens = part.split(RegExp(r'(?=[*/])|(?<=[*/])'));
        double product = 1;
        String op = '*';
        for (var token in tokens) {
          if (token == '*') {
            op = '*';
          } else if (token == '/') {
            op = '/';
          } else {
            final val = double.tryParse(token);
            if (val == null) return null;
            if (op == '*') {
              product *= val;
            } else {
              if (val == 0) return null;
              product /= val;
            }
          }
        }
        result += sign * product;
        sign = 1;
      }
    }
    return result;
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _showToast('Please enter a valid amount');
      return;
    }

    if (_selectedWalletId == null) {
      _showToast('Please select a payment source');
      return;
    }

    if (_type == 'expense' && _selectedPaymentMode == null) {
      _showToast('Please select a payment mode');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<AppProvider>();
      final wallet = provider.user?.wallets.firstWhere(
        (w) => w.id == _selectedWalletId,
      );

      await provider.createBill({
        'title': _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : _category,
        'amount': amount,
        'type': _type,
        'category': _category,
        'wallet': wallet?.name,
        'walletType': wallet?.type,
        'paymentMode': _selectedPaymentMode,
        'date': Helpers.todayDate(),
        'time': Helpers.currentTime(),
        'isRecurring': _isRecurring,
        'frequency': _isRecurring ? _recurringFrequency : null,
      });

      if (mounted) {
        _showToast(
          _type == 'income' ? 'Income recorded!' : 'Expense recorded!',
          isSuccess: true,
        );
        // Correctly redirect to Home
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showToast(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showToast(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : const Color(0xFFF43F5E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = _type == 'income';
    final themeColor = isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          isIncome ? 'Add Income' : 'Add Expense',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final wallets = provider.user?.wallets ?? [];
          final selectedWallet = wallets
              .where((w) => w.id == _selectedWalletId)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // Type Switch
              if (!widget.lockType)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TypeButton(
                        label: 'Expense',
                        active: !isIncome,
                        color: const Color(0xFFF43F5E),
                        onTap: () => setState(() => _type = 'expense'),
                      ),
                      _TypeButton(
                        label: 'Income',
                        active: isIncome,
                        color: const Color(0xFF10B981),
                        onTap: () => setState(() => _type = 'income'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isIncome ? 'Receiving Amount' : 'Spending Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            inputFormatters: [
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                final text = newValue.text;
                                // Strip leading zeros (but allow '0' alone and '0.')
                                if (text.length > 1 &&
                                    text.startsWith('0') &&
                                    !text.startsWith('0.')) {
                                  final stripped = text.replaceFirst(
                                    RegExp(r'^0+'),
                                    '',
                                  );
                                  final result = stripped.isEmpty
                                      ? '0'
                                      : stripped;
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
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -2,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calculator button row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showCalculator = !_showCalculator),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _showCalculator
                            ? const Color(0xFF2563EB)
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate_rounded,
                            size: 16,
                            color: _showCalculator
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CALCULATOR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: _showCalculator
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Inline Calculator
              if (_showCalculator) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SMART CALCULATOR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showCalculator = false),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.4,
                        children:
                            [
                              '7',
                              '8',
                              '9',
                              '÷',
                              '4',
                              '5',
                              '6',
                              '×',
                              '1',
                              '2',
                              '3',
                              '-',
                              '0',
                              '.',
                              '=',
                              '+',
                            ].map((key) {
                              final isOp = [
                                '÷',
                                '×',
                                '-',
                                '+',
                                '=',
                              ].contains(key);
                              return GestureDetector(
                                onTap: () {
                                  if (key == '=') {
                                    _evaluateExpression(_amountCtrl.text);
                                    setState(() => _showCalculator = false);
                                  } else {
                                    final mathKey = key == '×'
                                        ? '*'
                                        : key == '÷'
                                        ? '/'
                                        : key;
                                    final current = _amountCtrl.text;
                                    _amountCtrl.text =
                                        (current == '0' || current.isEmpty)
                                        ? (isOp ? '0$mathKey' : mathKey)
                                        : current + mathKey;
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isOp
                                        ? const Color(0xFF2563EB)
                                        : (isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isOp
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final t = _amountCtrl.text;
                                _amountCtrl.text = t.length > 1
                                    ? t.substring(0, t.length - 1)
                                    : '0';
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.backspace_rounded,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'BACK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _amountCtrl.text = '0',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF43F5E,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'CLEAR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: Color(0xFFF43F5E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Description
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: isIncome
                      ? 'Income Source Name'
                      : 'Merchant / Spending Goal',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.indigoAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recurring Expense Toggle
              if (!isIncome)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                size: 18,
                                color: _isRecurring
                                    ? const Color(0xFF2563EB)
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Recurring Expense',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _isRecurring,
                            onChanged: (v) => setState(() => _isRecurring = v),
                            activeTrackColor: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                [
                                  'Daily',
                                  'Weekly',
                                  'Monthly',
                                  'Quarterly',
                                  'Yearly',
                                ].map((f) {
                                  final active = _recurringFrequency == f;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _recurringFrequency = f,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? const Color(0xFF2563EB)
                                              : (isDark
                                                    ? const Color(0xFF0F172A)
                                                    : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          f,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: active
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white54
                                                      : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Categories
              _SectionTitle(title: 'Category', isDark: isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (isIncome ? incomeCategories : expenseCategories)
                      .map((c) {
                        final active = _category == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ActionChip(
                            onPressed: () => setState(() => _category = c),
                            label: Text(c),
                            avatar: Icon(
                              categoryIcons[c] ?? Icons.category_rounded,
                              size: 16,
                              color: active ? Colors.white : themeColor,
                            ),
                            backgroundColor: active ? themeColor : Colors.white,
                            labelStyle: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: active
                                  ? Colors.transparent
                                  : Colors.black12,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Step 1: Wallet Source
              _SectionTitle(
                title: isIncome
                    ? 'Step 1: Where is it going?'
                    : 'Step 1: Payment Source',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: wallets.map((w) {
                  final active = _selectedWalletId == w.id;
                  final icon = w.type == 'bank'
                      ? Icons.account_balance_rounded
                      : w.type == 'credit'
                      ? Icons.credit_card_rounded
                      : Icons.payments_rounded;
                  return _WalletCard(
                    name: w.name,
                    balance: w.balance,
                    icon: icon,
                    active: active,
                    onTap: () {
                      setState(() {
                        _selectedWalletId = w.id;
                        _selectedPaymentMode = null; // Reset mode
                      });
                    },
                  );
                }).toList(),
              ),

              // Step 2: Mode (Only for Expense)
              if (!isIncome && selectedWallet != null) ...[
                const SizedBox(height: 32),
                _SectionTitle(title: 'Step 2: Payment Mode', isDark: isDark),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (_walletModes[selectedWallet.type] ?? []).map((m) {
                    final active = _selectedPaymentMode == m['id'];
                    return _ModeChip(
                      label: m['name'],
                      icon: m['icon'],
                      active: active,
                      onTap: () =>
                          setState(() => _selectedPaymentMode = m['id']),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 48),

              // Final Confirmation
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    shadowColor: themeColor.withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isIncome ? 'CONFIRM DEPOSIT' : 'CONFIRM PAYMENT',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: active ? Colors.white : Colors.blueGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final String name;
  final double balance;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _WalletCard({
    required this.name,
    required this.balance,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: active ? Colors.indigoAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.transparent : Colors.black12,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.indigoAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.indigoAccent,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '₹${balance.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 9,
                color: active ? Colors.white70 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? Colors.black : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
