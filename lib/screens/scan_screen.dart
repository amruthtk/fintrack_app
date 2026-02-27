import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

// Known UPI apps with package names, display names, and brand colors
class UpiApp {
  final String name;
  final String packageName;
  final Color color;
  final IconData icon;

  const UpiApp({
    required this.name,
    required this.packageName,
    required this.color,
    required this.icon,
  });
}

const _knownUpiApps = [
  UpiApp(
    name: 'GPay',
    packageName: 'com.google.android.apps.nbu.paisa.user',
    color: Color(0xFF4285F4),
    icon: Icons.g_mobiledata_rounded,
  ),
  UpiApp(
    name: 'PhonePe',
    packageName: 'com.phonepe.app',
    color: Color(0xFF5F259F),
    icon: Icons.phone_android_rounded,
  ),
  UpiApp(
    name: 'Paytm',
    packageName: 'net.one97.paytm',
    color: Color(0xFF00BAF2),
    icon: Icons.account_balance_wallet_rounded,
  ),
  UpiApp(
    name: 'Amazon Pay',
    packageName: 'in.amazon.mShop.android.shopping',
    color: Color(0xFFFF9900),
    icon: Icons.shopping_cart_rounded,
  ),
  UpiApp(
    name: 'WhatsApp',
    packageName: 'com.whatsapp',
    color: Color(0xFF25D366),
    icon: Icons.chat_rounded,
  ),
  UpiApp(
    name: 'CRED',
    packageName: 'com.dreamplug.androidapp',
    color: Color(0xFF1A1A2E),
    icon: Icons.credit_score_rounded,
  ),
  UpiApp(
    name: 'BHIM',
    packageName: 'in.org.npci.upiapp',
    color: Color(0xFF00A651),
    icon: Icons.currency_rupee_rounded,
  ),
  UpiApp(
    name: 'iMobile',
    packageName: 'com.csam.icici.bank.imobile',
    color: Color(0xFFFF6600),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'SBI Pay',
    packageName: 'com.sbi.upi',
    color: Color(0xFF1A4F8C),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'PNB',
    packageName: 'com.fss.pnbpsp',
    color: Color(0xFF8B0000),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'Axis',
    packageName: 'com.axis.mobile',
    color: Color(0xFF800020),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'Kotak',
    packageName: 'com.msf.kbank.mobile',
    color: Color(0xFFED1C24),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'IDFC',
    packageName: 'com.idfc.bankingapp',
    color: Color(0xFF9B1B30),
    icon: Icons.account_balance_rounded,
  ),
  UpiApp(
    name: 'MobiKwik',
    packageName: 'com.mobikwik_new',
    color: Color(0xFF3F51B5),
    icon: Icons.wallet_rounded,
  ),
  UpiApp(
    name: 'super.money',
    packageName: 'money.super.payments',
    color: Color(0xFF00C853),
    icon: Icons.payments_rounded,
  ),
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.displayValue == null) return;

    final rawData = barcode.displayValue!;
    if (rawData.startsWith('upi://pay')) {
      setState(() => _isProcessing = true);
      _showPaymentFlow(rawData);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not a valid UPI QR code')));
    }
  }

  void _showPaymentFlow(String upiUri) {
    final uri = Uri.parse(upiUri);
    final merchantName = uri.queryParameters['pn'] ?? 'Merchant';
    final upiId = uri.queryParameters['pa'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpiPaymentSheet(
        merchantName: merchantName,
        upiId: upiId,
        upiUri: upiUri,
        onComplete: (amount, walletId, walletType, {category, title}) {
          _recordTransaction(
            merchantName,
            amount,
            walletId,
            walletType,
            title: title,
            category: category,
          );
        },
        onCancel: () {
          setState(() => _isProcessing = false);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  Future<void> _recordTransaction(
    String merchant,
    double amount,
    String? walletId,
    String? walletType, {
    String? title,
    String? category,
  }) async {
    try {
      final provider = context.read<AppProvider>();
      final wallet =
          provider.user?.wallets.firstWhere((w) => w.id == walletId).name ??
          'Unknown';

      await provider.createBill({
        'title': title ?? 'Paid to $merchant',
        'amount': amount,
        'type': 'expense',
        'category': category ?? 'Shopping',
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Scan & Pay',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _handleBarcode),
            // HUD Overlay
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF6366F1), width: 3),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Point camera at Merchant QR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiPaymentSheet extends StatefulWidget {
  final String merchantName;
  final String upiId;
  final String upiUri;
  final Function(
    double amount,
    String? walletId,
    String? walletType, {
    String? title,
    String? category,
  })
  onComplete;
  final VoidCallback onCancel;

  const _UpiPaymentSheet({
    required this.merchantName,
    required this.upiId,
    required this.upiUri,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<_UpiPaymentSheet> createState() => _UpiPaymentSheetState();
}

class _UpiPaymentSheetState extends State<_UpiPaymentSheet> {
  final _amountCtrl = TextEditingController();
  String? _selectedWalletId;
  List<UpiApp> _installedApps = [];
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _detectInstalledUpiApps();
  }

  Future<void> _detectInstalledUpiApps() async {
    if (!Platform.isAndroid) {
      setState(() {
        _installedApps = _knownUpiApps;
        _loadingApps = false;
      });
      return;
    }

    final installed = <UpiApp>[];
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
      } catch (_) {
        // skip unresolvable
      }
    }

    if (mounted) {
      setState(() {
        _installedApps = installed;
        _loadingApps = false;
      });
    }
  }

  Future<void> _launchUpiApp(UpiApp app) async {
    final amountText = _amountCtrl.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select payment source')));
      return;
    }

    // Construct the UPI URI with amount
    final payUri = Uri.parse(widget.upiUri).replace(
      queryParameters: {
        ...Uri.parse(widget.upiUri).queryParameters,
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
      },
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
      // Fallback for non-Android
      if (await canLaunchUrl(payUri)) {
        await launchUrl(payUri, mode: LaunchMode.externalApplication);
        launched = true;
      }
    }

    // After returning from UPI app, show confirmation dialog
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
        'merchantName': widget.merchantName,
        'category': 'Shopping', // Default from ScanScreen
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
                // Icon
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

                // Title
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
                Text(
                  'Please confirm the transaction status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Details Card
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
                          Text(
                            'Payment Amount (External)',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
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
                      Divider(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Banking App',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
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

                // Action Buttons
                Row(
                  children: [
                    // Report Failed
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

                    // Confirm Success
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Show expenditure details instead of immediately recording
                          _showExpenditureDetails(
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
                const SizedBox(height: 16),

                // Help hint
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use any UPI app for external transfer. After completing it, click "Success" to record the payment.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpenditureDetails({
    required double amount,
    required String? walletId,
    required String? walletType,
  }) {
    final titleCtrl = TextEditingController(
      text: 'Paid to ${widget.merchantName}',
    );
    String selectedCategory = 'Shopping';
    bool isSplit = false;

    const categories = [
      'Food',
      'Transport',
      'Travel',
      'Shopping',
      'Entertainment',
      'Health',
      'Bills',
      'Education',
      'Home',
      'Subscription',
      'Other',
    ];

    const categoryIcons = {
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
      'Other': Icons.category_rounded,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
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

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title field
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'What was this for?',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category
                      Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final active = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF6366F1)
                                    : (isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: active
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcons[cat] ??
                                        Icons.category_rounded,
                                    size: 14,
                                    color: active
                                        ? Colors.white
                                        : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Self / Split toggle
                      Text(
                        'TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => isSplit = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: !isSplit
                                      ? const Color(0xFF6366F1)
                                      : (isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: !isSplit
                                          ? Colors.white
                                          : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Self',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: !isSplit
                                            ? Colors.white
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => isSplit = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSplit
                                      ? const Color(0xFF6366F1)
                                      : (isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group_rounded,
                                      size: 16,
                                      color: isSplit
                                          ? Colors.white
                                          : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Split',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isSplit
                                            ? Colors.white
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Record button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (isSplit) {
                            // Navigate to split flow with amount
                            context.push(
                              '/split?amount=${amount.toStringAsFixed(2)}&title=${Uri.encodeComponent(titleCtrl.text.trim())}',
                            );
                          } else {
                            widget.onComplete(
                              amount,
                              walletId,
                              walletType,
                              title: titleCtrl.text.trim(),
                              category: selectedCategory,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isSplit ? 'Continue to Split' : 'Record Payment',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            const SizedBox(height: 24),

            // Merchant Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.upiId,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Amount Input
            Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: Color(0xFF6366F1)),
                hintText: '0',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),

            // Pay From (wallet selector)
            Text(
              'Pay From',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
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
                            ? const Color(0xFF6366F1)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
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
            ),
            const SizedBox(height: 28),

            // UPI Apps Grid
            Text(
              'Pay With',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _loadingApps
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _installedApps.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No UPI apps found',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _installedApps.length,
                    itemBuilder: (ctx, i) {
                      final app = _installedApps[i];
                      return _UpiAppButton(
                        app: app,
                        isDark: isDark,
                        onTap: () => _launchUpiApp(app),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UpiAppButton extends StatelessWidget {
  final UpiApp app;
  final bool isDark;
  final VoidCallback onTap;

  const _UpiAppButton({
    required this.app,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
  }
}
