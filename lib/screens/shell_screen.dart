import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/persistent_payment_dialog.dart';
import '../providers/app_provider.dart';
import 'package:provider/provider.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingPayment();
    });
  }

  void _checkPendingPayment() {
    final provider = context.read<AppProvider>();
    if (provider.pendingPayment != null) {
      PersistentPaymentDialog.show(context, provider.pendingPayment!);
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/groups')) return 1;
    return -1;
  }

  void _onTabTap(BuildContext context, int index) {
    final paths = ['/', '/groups'];
    if (_getCurrentIndex(context) == index) return;
    context.go(paths[index]);
  }

  void _showAddOptions(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => _AddOptionsSheet(
        onSelect: (type) {
          Navigator.pop(ctx);
          if (type == 'pool') {
            context.push('/create-pool-bill');
          } else {
            context.push('/add-bill?type=$type&lock=true');
          }
        },
        onSplit: () {
          Navigator.pop(ctx);
          context.push('/split');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Pill-shaped nav bar
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: currentIndex == 0,
                    onTap: () => _onTabTap(context, 0),
                  ),
                  const SizedBox(width: 56), // Space for FAB
                  _NavItem(
                    icon: Icons.groups_rounded,
                    label: 'Groups',
                    active: currentIndex == 1,
                    onTap: () => _onTabTap(context, 1),
                  ),
                ],
              ),
            ),
            // FAB centered above the pill
            Positioned(
              top: -22,
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showAddOptions(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF2563EB)
        : Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  final Function(String) onSelect;
  final VoidCallback onSplit;

  const _AddOptionsSheet({required this.onSelect, required this.onSplit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // X button center position from bottom
    final xButtonBottom = bottomPadding + 38 + 28; // center of the 56px button
    // Radius of the arc around the X button
    const arcRadius = 110.0;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.4),
          child: Stack(
            children: [
              // Tap anywhere to close
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),

              // Expense — directly above X button
              Positioned(
                bottom: xButtonBottom + arcRadius - 28,
                left: (screenWidth - 80) / 2,
                child: _CircleOption(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Expense',
                  color: const Color(0xFF2563EB),
                  filled: true,
                  onTap: () => onSelect('expense'),
                  isDark: isDark,
                ),
              ),

              // Income — upper-left of X button
              Positioned(
                bottom: xButtonBottom + (arcRadius * 0.5) - 28,
                left: (screenWidth / 2) - arcRadius - 10,
                child: _CircleOption(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Income',
                  color: const Color(0xFF10B981),
                  filled: false,
                  onTap: () => onSelect('income'),
                  isDark: isDark,
                ),
              ),

              // Split Bill — upper-right of X button
              Positioned(
                bottom: xButtonBottom + (arcRadius * 0.5) - 28,
                right: (screenWidth / 2) - arcRadius - 10,
                child: _CircleOption(
                  icon: Icons.people_rounded,
                  label: 'Split Bill',
                  color: const Color(0xFF2563EB),
                  filled: false,
                  onTap: onSplit,
                  isDark: isDark,
                ),
              ),

              // X Close button (aligned with FAB)
              Positioned(
                bottom: bottomPadding + 50,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: filled
                  ? color
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(color: color.withValues(alpha: 0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: filled ? 0.3 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: filled ? Colors.white : color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1C3D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
