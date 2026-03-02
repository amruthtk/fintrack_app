import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPasswords = false;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    setState(() {
      _error = null;
      _success = null;
    });

    if (_currentCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your current password');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();
      await provider.updatePassword(_currentCtrl.text, _newCtrl.text);
      setState(() {
        _success = 'Password updated successfully!';
        _error = null;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _currentCtrl.clear();
          _newCtrl.clear();
          _confirmCtrl.clear();
          setState(() => _success = null);
        }
      });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('wrong-password') ||
          msg.contains('invalid-credential')) {
        setState(() => _error = 'Current password is incorrect');
      } else if (msg.contains('weak-password')) {
        setState(
          () => _error = 'New password is too weak. Use at least 6 characters.',
        );
      } else if (msg.contains('too-many-requests')) {
        setState(() => _error = 'Too many attempts. Please try again later.');
      } else {
        setState(() => _error = 'Failed to update password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text(
          'Security',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          // Password Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
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
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Current Password
                _buildLabel('Current Password', isDark),
                const SizedBox(height: 8),
                _buildPasswordField(
                  _currentCtrl,
                  'Enter current password',
                  isDark,
                ),
                const SizedBox(height: 20),

                // New Password
                _buildLabel('New Password', isDark),
                const SizedBox(height: 8),
                _buildPasswordField(_newCtrl, 'Minimum 6 characters', isDark),
                const SizedBox(height: 20),

                // Confirm New Password
                _buildLabel('Confirm New Password', isDark),
                const SizedBox(height: 8),
                _buildPasswordField(
                  _confirmCtrl,
                  'Verify new password',
                  isDark,
                ),
                const SizedBox(height: 16),

                // Show/Hide toggle
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showPasswords = !_showPasswords),
                    icon: Icon(
                      _showPasswords
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    label: Text(
                      _showPasswords ? 'Hide Passwords' : 'Show Passwords',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ||
                            _currentCtrl.text.isEmpty ||
                            _newCtrl.text.isEmpty ||
                            _confirmCtrl.text.isEmpty
                        ? null
                        : _handleUpdatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: 0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'UPDATE PASSWORD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Color(0xFFF43F5E),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success Message
          if (_success != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _success!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Secured by Firebase Card
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 28,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                Text(
                  'Secured by Firebase',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF10B981)
                        : const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your password is encrypted and securely managed by Firebase Authentication. It is never stored in the database.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.6)
                        : const Color(0xFF065F46).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController ctrl,
    String hint,
    bool isDark,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: !_showPasswords,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
