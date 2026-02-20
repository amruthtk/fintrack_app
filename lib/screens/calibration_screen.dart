import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final List<_WalletForm> _wallets = [
    _WalletForm(name: 'Bank Account', type: 'bank'),
    _WalletForm(name: 'Cash', type: 'cash'),
  ];
  bool _saving = false;

  void _addWallet() {
    setState(() {
      _wallets.add(
        _WalletForm(name: 'Wallet ${_wallets.length + 1}', type: 'bank'),
      );
    });
  }

  void _removeWallet(int i) {
    if (_wallets.length <= 1) return;
    setState(() => _wallets.removeAt(i));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final wallets = _wallets.map((w) {
      return Wallet(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}_${_wallets.indexOf(w)}',
        name: w.nameCtrl.text.trim().isEmpty ? w.name : w.nameCtrl.text.trim(),
        balance: double.tryParse(w.balanceCtrl.text) ?? 0,
        type: w.type,
      );
    }).toList();

    await provider.saveWallets(wallets);
    if (mounted) {
      context.go('/');
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
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        title: Text(
          'Setup Wallets',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add your wallets and current balances to track spending accurately.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < _wallets.length; i++) ...[
            _WalletFormCard(
              form: _wallets[i],
              index: i,
              isDark: isDark,
              onRemove: () => _removeWallet(i),
              canRemove: _wallets.length > 1,
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _addWallet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Wallet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Wallets', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletForm {
  final String name;
  final String type;
  final nameCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();

  _WalletForm({required this.name, required this.type}) {
    nameCtrl.text = name;
    balanceCtrl.text = '0';
  }
}

class _WalletFormCard extends StatelessWidget {
  final _WalletForm form;
  final int index;
  final bool isDark;
  final VoidCallback onRemove;
  final bool canRemove;

  const _WalletFormCard({
    required this.form,
    required this.index,
    required this.isDark,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: form.nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Wallet Name',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFF43F5E),
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: form.balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current Balance (₹)',
              prefixText: '₹ ',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
