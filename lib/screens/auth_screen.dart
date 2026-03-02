import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;
  int _loginStep = 1; // 1 = phone, 2 = password
  int _regStep = 1; // 1 = details, 2 = wallets

  // Wallet selection state
  bool _trackCash = true;
  bool _trackBank = true;
  bool _trackCredit = false;

  // Forgot password state
  bool _showForgot = false;
  bool _resetSent = false;
  String _resetEmail = '';

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _forgotPhoneController = TextEditingController();
  final _creditLimitController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _forgotPhoneController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    return '${parts[0][0]}***@${parts[1]}';
  }

  Future<void> _handleLogin() async {
    if (_loginStep == 1) {
      if (_phoneController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter your phone number');
        return;
      }
      setState(() {
        _loginStep = 2;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();
      final user = await provider.loginWithPhone(
        _phoneController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid phone number or password';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('invalid-credential') ||
            e.toString().contains('user-not-found') ||
            e.toString().contains('wrong-password')) {
          _error = 'Invalid phone number or password';
        } else if (e.toString().contains('too-many-requests')) {
          _error = 'Too many attempts. Try again later.';
        } else if (e.toString().contains('No email linked')) {
          _error = 'Account setup incomplete. Please contact support.';
        } else {
          _error = 'Login failed. Please try again.';
        }
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_regStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter your name');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter your phone number');
        return;
      }
      if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        setState(() => _error = 'Please enter a valid email address');
        return;
      }
      if (_passwordController.text.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters');
        return;
      }

      // Check if phone number is already registered
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final provider = context.read<AppProvider>();
        final phoneExists = await provider.checkPhoneExists(
          _phoneController.text.trim(),
        );
        if (phoneExists) {
          setState(() {
            _isLoading = false;
            _error = 'Phone number already registered';
          });
          return;
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to verify phone number. Please try again.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _regStep = 2;
        _error = null;
      });
      return;
    }

    // Step 2 logic
    final initialWallets = <Map<String, dynamic>>[];
    if (_trackCash) {
      initialWallets.add({
        'id': 'cash',
        'name': 'Physical Cash',
        'balance': 0.0,
        'type': 'cash',
      });
    }
    if (_trackBank) {
      initialWallets.add({
        'id': 'bank',
        'name': 'Bank Account',
        'balance': 0.0,
        'type': 'bank',
      });
    }
    if (_trackCredit) {
      initialWallets.add({
        'id': 'credit',
        'name': 'Credit Card',
        'balance': double.tryParse(_creditLimitController.text) ?? 0.0,
        'type': 'credit',
      });
    }

    if (initialWallets.isEmpty) {
      setState(() => _error = 'Please track at least one payment method');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();
      await provider.register(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        initialWallets: initialWallets,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('email-already-in-use')) {
          _error = 'Email already registered';
        } else if (e.toString().contains('weak-password')) {
          _error = 'Password must be at least 6 characters';
        } else if (e.toString().contains('invalid-email')) {
          _error = 'Please enter a valid email address';
        } else {
          _error = 'Registration failed. Please try again.';
        }
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_forgotPhoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();
      final sentTo = await provider.sendPasswordReset(
        _forgotPhoneController.text.trim(),
      );
      setState(() {
        _isLoading = false;
        _resetSent = true;
        _resetEmail = sentTo;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: screenSize.height * 0.08),
                // Logo & Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FinTrack',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Smart Expense & Split Tracker',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _showForgot
                      ? _buildForgotPasswordForm(isDark)
                      : _buildAuthForm(isDark),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Login',
                  active: _isLogin,
                  onTap: () => setState(() {
                    _isLogin = true;
                    _error = null;
                    _loginStep = 1;
                    _regStep = 1;
                  }),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'Register',
                  active: !_isLogin,
                  onTap: () => setState(() {
                    _isLogin = false;
                    _error = null;
                    _regStep = 1;
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_isLogin) ..._buildLoginForm(isDark),
        if (!_isLogin) ..._buildRegisterForm(isDark),

        if (!_isLogin && _regStep == 2) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _regStep = 1),
            child: const Text(
              '← Back to Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_isLogin ? _handleLogin : _handleRegister),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isLogin
                        ? (_loginStep == 1 ? 'Next' : 'Login')
                        : (_regStep == 1 ? 'Next' : 'Create Account'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_resetSent) ...[
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _showForgot = false;
                  _error = null;
                  _resetSent = false;
                }),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your phone number and we\'ll send a reset link to your registered email.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _forgotPhoneController,
            icon: Icons.phone_rounded,
            hint: 'Phone Number',
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Reset Email Sent!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a password reset link to',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _maskEmail(_resetEmail),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your spam folder if you don\'t see it',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _showForgot = false;
                _resetSent = false;
                _error = null;
                _loginStep = 1;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildLoginForm(bool isDark) {
    if (_loginStep == 1) {
      return [
        _InputField(
          controller: _phoneController,
          icon: Icons.phone_rounded,
          hint: 'Phone Number',
          keyboardType: TextInputType.phone,
          isDark: isDark,
        ),
      ];
    }
    return [
      _InputField(
        controller: _phoneController,
        icon: Icons.phone_rounded,
        hint: 'Phone Number',
        enabled: false,
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _InputField(
        controller: _passwordController,
        icon: Icons.lock_rounded,
        hint: 'Password',
        obscure: !_showPassword,
        isDark: isDark,
        suffix: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF94A3B8),
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => setState(() {
            _showForgot = true;
            _error = null;
            _forgotPhoneController.text = _phoneController.text;
          }),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRegisterForm(bool isDark) {
    if (_regStep == 1) {
      return [
        _InputField(
          controller: _nameController,
          icon: Icons.person_rounded,
          hint: 'Display Name',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: _phoneController,
          icon: Icons.phone_rounded,
          hint: 'Phone Number',
          keyboardType: TextInputType.phone,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: _emailController,
          icon: Icons.email_rounded,
          hint: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 4),
        Text(
          'Email is used for password recovery only',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: _passwordController,
          icon: Icons.lock_rounded,
          hint: 'Create Password (min 6 chars)',
          obscure: !_showPassword,
          isDark: isDark,
          suffix: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ];
    }

    return [
      const Text(
        'Step 2: Track Accounts',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2563EB),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Which payment methods would you like to track?',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 16),
      _buildWalletSwitch(
        label: 'Physical Cash',
        value: _trackCash,
        onChanged: (v) => setState(() => _trackCash = v),
        isDark: isDark,
      ),
      const SizedBox(height: 8),
      _buildWalletSwitch(
        label: 'Bank Account',
        value: _trackBank,
        onChanged: (v) => setState(() => _trackBank = v),
        isDark: isDark,
      ),
      const SizedBox(height: 8),
      _buildWalletSwitch(
        label: 'Credit Card',
        value: _trackCredit,
        onChanged: (v) => setState(() => _trackCredit = v),
        isDark: isDark,
      ),
      if (_trackCredit) ...[
        const SizedBox(height: 16),
        const Text(
          'Available Credit Limit (₹)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 6),
        _InputField(
          controller: _creditLimitController,
          icon: Icons.currency_rupee_rounded,
          hint: 'e.g. 50000',
          keyboardType: TextInputType.number,
          isDark: isDark,
        ),
      ],
    ];
  }

  Widget _buildWalletSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF2563EB).withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF2563EB) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: value
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.enabled = true,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
