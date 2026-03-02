import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        if (user == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/'),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  const SizedBox(height: 20),

                  // Avatar & Info
                  _ProfileHeader(user: user, isDark: isDark),
                  const SizedBox(height: 16),

                  // UPI ID
                  _UpiSection(user: user, isDark: isDark),
                  const SizedBox(height: 24),

                  // Wallets Section
                  _WalletSection(
                    user: user,
                    isDark: isDark,
                    provider: provider,
                  ),
                  const SizedBox(height: 20),

                  // Settings
                  _SettingsSection(isDark: isDark, provider: provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Profile Header with Avatar Upload ---
class _ProfileHeader extends StatefulWidget {
  final AppUser user;
  final bool isDark;
  const _ProfileHeader({required this.user, required this.isDark});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (file == null) return;

    final bytes = await File(file.path).readAsBytes();
    if (bytes.lengthInBytes > 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image must be under 1 MB'),
            backgroundColor: Color(0xFFF43F5E),
          ),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final base64Str = base64Encode(bytes);
      final provider = context.read<AppProvider>();
      await provider.updateProfile({
        'avatarUrl': 'data:image/jpeg;base64,$base64Str',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar with camera overlay
          GestureDetector(
            onTap: _uploading ? null : _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage:
                      user.avatarUrl != null &&
                          user.avatarUrl!.startsWith('data:')
                      ? MemoryImage(
                          base64Decode(user.avatarUrl!.split(',').last),
                        )
                      : null,
                  child:
                      user.avatarUrl == null ||
                          !user.avatarUrl!.startsWith('data:')
                      ? Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.5,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfile(context),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final provider = context.read<AppProvider>();
    final nameCtrl = TextEditingController(text: widget.user.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  filled: true,
                  fillColor: widget.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await provider.updateProfile({
                    'displayName': nameCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UPI ID Inline Edit Section ---
class _UpiSection extends StatefulWidget {
  final AppUser user;
  final bool isDark;
  const _UpiSection({required this.user, required this.isDark});

  @override
  State<_UpiSection> createState() => _UpiSectionState();
}

class _UpiSectionState extends State<_UpiSection> {
  bool _editing = false;
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.user.upiId ?? '');
  }

  @override
  void didUpdateWidget(_UpiSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _ctrl.text = widget.user.upiId ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.updateProfile({'upiId': _ctrl.text.trim()});
      setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save UPI ID: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final hasUpi = widget.user.upiId != null && widget.user.upiId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _editing
          ? Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'yourname@upi',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  )
                else ...[
                  IconButton(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () {
                      _ctrl.text = widget.user.upiId ?? '';
                      setState(() => _editing = false);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFF43F5E),
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            )
          : InkWell(
              onTap: () => setState(() => _editing = true),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI ID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasUpi ? widget.user.upiId! : 'Tap to add UPI ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasUpi
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: hasUpi
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    hasUpi ? Icons.edit_rounded : Icons.add_rounded,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- Wallet Section ---
class _WalletSection extends StatefulWidget {
  final AppUser user;
  final bool isDark;
  final AppProvider provider;

  const _WalletSection({
    required this.user,
    required this.isDark,
    required this.provider,
  });

  @override
  State<_WalletSection> createState() => _WalletSectionState();
}

class _WalletSectionState extends State<_WalletSection> {
  void _showReconcileDialog(Wallet wallet) {
    final controller = TextEditingController(
      text: wallet.balance.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      wallet.type == 'cash'
                          ? Icons.money_rounded
                          : wallet.type == 'credit'
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_rounded,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fix Balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Current: ₹${wallet.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Actual Balance (₹)',
                  labelStyle: TextStyle(
                    color: widget.isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final newBalance = double.tryParse(controller.text.trim());
                  if (newBalance == null) return;
                  await widget.provider.updateWalletBalance(
                    wallet.id,
                    newBalance,
                    reason: 'Reconciliation',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${wallet.name} balance updated!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Balance',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wallets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/calibration'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.user.wallets.isEmpty)
          GestureDetector(
            onTap: () => context.push('/calibration'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF2563EB),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Set up your wallets',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Track spending across bank, cash & cards',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        for (final w in widget.user.wallets)
          GestureDetector(
            onTap: () => _showReconcileDialog(w),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      w.type == 'cash'
                          ? Icons.money_rounded
                          : w.type == 'credit'
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_rounded,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Tap to reconcile',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.provider.isPrivate
                        ? '•••'
                        : '₹${w.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: w.balance >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: widget.isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- Settings Section ---
class _SettingsSection extends StatelessWidget {
  final bool isDark;
  final AppProvider provider;

  const _SettingsSection({required this.isDark, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: provider.darkMode,
                  onChanged: (v) => provider.darkMode = v,
                  activeTrackColor: const Color(0xFF2563EB),
                ),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _SettingsTile(
                icon: Icons.repeat_rounded,
                title: 'Subscriptions',
                isDark: isDark,
                onTap: () => context.push('/subscriptions'),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: 'Security',
                isDark: isDark,
                onTap: () => context.push('/security'),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _SettingsTile(
                icon: Icons.sync_rounded,
                title: 'Sync Local Data',
                isDark: isDark,
                onTap: () async {
                  await provider.syncLocalData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data synced!')),
                    );
                  }
                },
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                isDark: isDark,
                titleColor: const Color(0xFFF43F5E),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Color(0xFFF43F5E)),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.logout();
                    if (context.mounted) context.go('/auth');
                  }
                },
              ),
              Divider(
                height: 1,
                indent: 56,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                isDark: isDark,
                titleColor: const Color(0xFFF43F5E),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Color(0xFFF43F5E)),
                      ),
                      content: const Text(
                        'This action is permanent and will delete all your data. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFF43F5E)),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await provider.deleteAccount();
                      if (context.mounted) context.go('/auth');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Requires recent login. Logout and login again to delete.',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _showChangePassword removed — now uses dedicated SecurityScreen via /security route
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.isDark,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: titleColor ?? const Color(0xFF2563EB),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color:
              titleColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
    );
  }
}
