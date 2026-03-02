import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

// Reuse the same UPI app definitions from scan_screen
class _UpiApp {
  final String name;
  final String packageName;
  final Color color;
  final IconData icon;

  const _UpiApp({
    required this.name,
    required this.packageName,
    required this.color,
    required this.icon,
  });
}

const _knownUpiApps = [
  _UpiApp(
    name: 'GPay',
    packageName: 'com.google.android.apps.nbu.paisa.user',
    color: Color(0xFF4285F4),
    icon: Icons.g_mobiledata_rounded,
  ),
  _UpiApp(
    name: 'PhonePe',
    packageName: 'com.phonepe.app',
    color: Color(0xFF5F259F),
    icon: Icons.phone_android_rounded,
  ),
  _UpiApp(
    name: 'Paytm',
    packageName: 'net.one97.paytm',
    color: Color(0xFF00BAF2),
    icon: Icons.account_balance_wallet_rounded,
  ),
  _UpiApp(
    name: 'Amazon Pay',
    packageName: 'in.amazon.mShop.android.shopping',
    color: Color(0xFFFF9900),
    icon: Icons.shopping_cart_rounded,
  ),
  _UpiApp(
    name: 'WhatsApp',
    packageName: 'com.whatsapp',
    color: Color(0xFF25D366),
    icon: Icons.chat_rounded,
  ),
  _UpiApp(
    name: 'CRED',
    packageName: 'com.dreamplug.androidapp',
    color: Color(0xFF1A1A2E),
    icon: Icons.credit_score_rounded,
  ),
  _UpiApp(
    name: 'BHIM',
    packageName: 'in.org.npci.upiapp',
    color: Color(0xFF00A651),
    icon: Icons.currency_rupee_rounded,
  ),
  _UpiApp(
    name: 'iMobile',
    packageName: 'com.csam.icici.bank.imobile',
    color: Color(0xFFFF6600),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'SBI Pay',
    packageName: 'com.sbi.upi',
    color: Color(0xFF1A4F8C),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'PNB',
    packageName: 'com.fss.pnbpsp',
    color: Color(0xFF8B0000),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'Axis',
    packageName: 'com.axis.mobile',
    color: Color(0xFF800020),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'Kotak',
    packageName: 'com.msf.kbank.mobile',
    color: Color(0xFFED1C24),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'IDFC',
    packageName: 'com.idfc.bankingapp',
    color: Color(0xFF9B1B30),
    icon: Icons.account_balance_rounded,
  ),
  _UpiApp(
    name: 'MobiKwik',
    packageName: 'com.mobikwik_new',
    color: Color(0xFF3F51B5),
    icon: Icons.wallet_rounded,
  ),
  _UpiApp(
    name: 'super.money',
    packageName: 'money.super.payments',
    color: Color(0xFF00C853),
    icon: Icons.payments_rounded,
  ),
];

class QuickSendScreen extends StatefulWidget {
  const QuickSendScreen({super.key});

  @override
  State<QuickSendScreen> createState() => _QuickSendScreenState();
}

class _QuickSendScreenState extends State<QuickSendScreen> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  Timer? _debounce;
  List<AppUser> _searchResults = [];
  bool _isSearching = false;
  AppUser? _selectedUser;

  String? _selectedWalletId;
  List<_UpiApp> _installedApps = [];
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _detectInstalledUpiApps();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── UPI App Detection ───
  Future<void> _detectInstalledUpiApps() async {
    if (!Platform.isAndroid) {
      setState(() {
        _installedApps = _knownUpiApps;
        _loadingApps = false;
      });
      return;
    }

    final installed = <_UpiApp>[];
    for (final app in _knownUpiApps) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'upi://pay?pa=test@upi',
          package: app.packageName,
        );
        final canResolve = await intent.canResolveActivity() ?? false;
        if (canResolve) {
          installed.add(app);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _installedApps = installed;
        _loadingApps = false;
      });
    }
  }

  // ─── User Search ───
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final provider = context.read<AppProvider>();
      final results = await provider.searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectUser(AppUser user) {
    setState(() {
      _selectedUser = user;
      _searchResults = [];
      _searchCtrl.text = user.name;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  // ─── Launch UPI App ───
  Future<void> _launchUpiApp(_UpiApp app) async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient first')),
      );
      return;
    }

    // Check if recipient has a UPI ID set up
    if (_selectedUser!.upiId == null || _selectedUser!.upiId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedUser!.name} has not set up their UPI ID yet',
          ),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
      return;
    }

    final amountText = _amountCtrl.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select payment source')));
      return;
    }

    // Build UPI URI from recipient's verified UPI ID
    final recipientUpi = _selectedUser!.upiId!;
    final payUri = Uri.parse(
      'upi://pay?pa=$recipientUpi&pn=${Uri.encodeComponent(_selectedUser!.name)}&am=${amount.toStringAsFixed(2)}&cu=INR',
    );

    bool launched = false;

    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: payUri.toString(),
          package: app.packageName,
        );
        await intent.launch();
        launched = true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open ${app.name}')));
        }
        return;
      }
    } else {
      if (await canLaunchUrl(payUri)) {
        await launchUrl(payUri, mode: LaunchMode.externalApplication);
        launched = true;
      }
    }

    if (launched && mounted) {
      final provider = context.read<AppProvider>();
      final wallet = provider.user?.wallets.firstWhere(
        (w) => w.id == _selectedWalletId,
      );

      final pendingData = {
        'amount': amount,
        'appName': app.name,
        'walletId': _selectedWalletId,
        'walletType': wallet?.type,
        'merchantName': _selectedUser!.name,
        'category': 'Transfer',
      };
      provider.setPendingPayment(pendingData);

      _showPaymentConfirmation(
        amount: amount,
        appName: app.name,
        walletId: _selectedWalletId,
        walletType: wallet?.type,
      );
    }
  }

  // ─── Payment Confirmation ───
  void _showPaymentConfirmation({
    required double amount,
    required String appName,
    required String? walletId,
    required String? walletType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                  'Did you complete the\npayment successfully?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${_selectedUser?.name ?? 'Unknown'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Details card
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
                            'Amount',
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
                            'Via',
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
                          Navigator.pop(ctx);
                          context.read<AppProvider>().setPendingPayment(null);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment not recorded. No balance deducted.',
                                ),
                                backgroundColor: Color(0xFFF59E0B),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF43F5E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Failed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF43F5E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _recordTransaction(
                            amount: amount,
                            walletId: walletId,
                            walletType: walletType,
                          );
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
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
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
      },
    );
  }

  // ─── Record transaction ───
  Future<void> _recordTransaction({
    required double amount,
    required String? walletId,
    required String? walletType,
  }) async {
    try {
      final provider = context.read<AppProvider>();
      final wallet =
          provider.user?.wallets.firstWhere((w) => w.id == walletId).name ??
          'Unknown';

      final noteText = _noteCtrl.text.trim();
      final title = noteText.isNotEmpty
          ? noteText
          : 'Sent to ${_selectedUser?.name ?? 'Unknown'}';

      await provider.createBill({
        'title': title,
        'amount': amount,
        'type': 'expense',
        'category': 'Transfer',
        'wallet': wallet,
        'walletType': walletType,
        'paymentMode': 'upi',
        'date': Helpers.todayDate(),
        'time': Helpers.currentTime(),
      });

      provider.setPendingPayment(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded in FinTrack'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final wallets =
        provider.user?.wallets
            .where(
              (w) =>
                  w.type == 'bank' || w.type == 'wallet' || w.type == 'credit',
            )
            .toList() ??
        [];

    if (_selectedWalletId == null && wallets.isNotEmpty) {
      final bank = wallets.where((w) => w.type == 'bank').firstOrNull;
      _selectedWalletId = bank?.id ?? wallets.first.id;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Quick Send',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Recipient Section ──
              _buildSectionLabel('SEND TO', isDark),
              const SizedBox(height: 10),
              _buildRecipientSelector(isDark),
              const SizedBox(height: 28),

              // ── Amount Section ──
              _buildSectionLabel('AMOUNT', isDark),
              const SizedBox(height: 10),
              _buildAmountInput(isDark),
              const SizedBox(height: 28),

              // ── Note Section ──
              _buildSectionLabel('NOTE (OPTIONAL)', isDark),
              const SizedBox(height: 10),
              _buildNoteInput(isDark),
              const SizedBox(height: 28),

              // ── Pay From ──
              _buildSectionLabel('PAY FROM', isDark),
              const SizedBox(height: 12),
              _buildWalletSelector(wallets, isDark),
              const SizedBox(height: 28),

              // ── UPI Apps ──
              _buildSectionLabel('PAY WITH', isDark),
              const SizedBox(height: 16),
              _buildUpiAppsGrid(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }

  // ── Recipient Selector ──
  Widget _buildRecipientSelector(bool isDark) {
    if (_selectedUser != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _selectedUser!.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _selectedUser!.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        Helpers.getInitials(_selectedUser!.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedUser!.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedUser!.username.isNotEmpty
                        ? '@${_selectedUser!.username}'
                        : _selectedUser!.phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _clearSelectedUser,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFF43F5E),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Search field + results
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              hintText: 'Search by username or phone...',
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Search Results Dropdown
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (!_isSearching && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, _a) => Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (ctx, i) {
                  final user = _searchResults[i];
                  return ListTile(
                    onTap: () => _selectUser(user),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: user.avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                user.avatarUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                Helpers.getInitials(user.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      user.username.isNotEmpty
                          ? '@${user.username}  •  ${user.phone}'
                          : user.phone,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
          ),
        if (!_isSearching &&
            _searchResults.isEmpty &&
            _searchCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'No users found',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ── Amount Input ──
  Widget _buildAmountInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _amountCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: const InputDecoration(
          prefixText: '₹ ',
          prefixStyle: TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
          hintText: '0',
          hintStyle: TextStyle(color: Color(0xFFCBD5E1)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── Note Input ──
  Widget _buildNoteInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _noteCtrl,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.sticky_note_2_rounded,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            size: 20,
          ),
          hintText: 'Add a note...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ── Wallet Selector ──
  Widget _buildWalletSelector(List<Wallet> wallets, bool isDark) {
    if (wallets.isEmpty) {
      return Text(
        'No wallets available',
        style: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 13,
        ),
      );
    }
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final w = wallets[i];
          final active = _selectedWalletId == w.id;
          final walletIcon = w.type == 'credit'
              ? Icons.credit_card_rounded
              : w.type == 'bank'
              ? Icons.account_balance_rounded
              : Icons.payments_rounded;
          return GestureDetector(
            onTap: () => setState(() => _selectedWalletId = w.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF2563EB)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: !active
                    ? Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      )
                    : null,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(
                    walletIcon,
                    size: 16,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    w.name,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── UPI Apps Grid ──
  Widget _buildUpiAppsGrid(bool isDark) {
    if (_loadingApps) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_installedApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No UPI apps found',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _installedApps.length,
      itemBuilder: (ctx, i) {
        final app = _installedApps[i];
        return GestureDetector(
          onTap: () => _launchUpiApp(app),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: app.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: app.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(app.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                app.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
