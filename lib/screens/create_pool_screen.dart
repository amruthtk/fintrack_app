import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class CreatePoolScreen extends StatefulWidget {
  const CreatePoolScreen({super.key});

  @override
  State<CreatePoolScreen> createState() => _CreatePoolScreenState();
}

class _CreatePoolScreenState extends State<CreatePoolScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _myShareCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<_PoolMember> _members = [];
  List<AppUser> _searchResults = [];
  bool _isSubmitting = false;
  String? _wallet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _addCurrentUser());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _myShareCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addCurrentUser() {
    final user = context.read<AppProvider>().user;
    if (user != null && !_members.any((m) => m.userId == user.id)) {
      setState(() {
        _members.add(
          _PoolMember(userId: user.id, name: user.name, isPayer: true),
        );
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await context.read<AppProvider>().searchUsers(query);
    setState(() => _searchResults = results);
  }

  void _addMember(AppUser user) {
    if (_members.any((m) => m.userId == user.id)) return;
    setState(() {
      _members.add(_PoolMember(userId: user.id, name: user.name));
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  void _removeMember(int index) {
    setState(() => _members.removeAt(index));
  }

  Future<void> _submit() async {
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    final myShare = double.tryParse(_myShareCtrl.text) ?? 0;

    if (total <= 0) {
      _showError('Enter a valid total amount');
      return;
    }
    if (myShare <= 0) {
      _showError('Enter your share amount');
      return;
    }
    if (myShare >= total) {
      _showError('Your share must be less than the total');
      return;
    }
    if (_members.length < 2) {
      _showError('Add at least 2 people');
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<AppProvider>();
    final payerId = provider.user?.id ?? '';

    try {
      final members = _members
          .map(
            (m) => {
              'id': m.userId,
              'name': m.name,
              'amount': m.isPayer ? myShare : 0.0,
              'status': m.isPayer ? 'paid' : 'pending',
            },
          )
          .toList();

      await provider.createPool({
        'title': _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : 'Pool',
        'amount': total,
        'payerId': payerId,
        'payerShare': myShare,
        'wallet': _wallet,
        'members': members,
        'date': Helpers.todayDate(),
        'time': Helpers.currentTime(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pool created! Members will be notified.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    final myShare = double.tryParse(_myShareCtrl.text) ?? 0;
    final poolTarget = total - myShare;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
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
              'Create Pool',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'What is this pool for?',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Total Amount
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.currency_rupee_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'Total Pool Amount',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // My Share
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF1E293B)]
                          : [const Color(0xFFFFF7ED), const Color(0xFFFFF1E6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFFED7AA),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings_rounded,
                            color: isDark
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'My Share (What YOU contribute)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _myShareCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.currency_rupee_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          hintText: 'Your contribution',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (poolTarget > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.track_changes_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pool Target: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                Helpers.formatCurrency(poolTarget),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search & Add People
                Text(
                  'Add People',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'Search by name, phone or username',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: _searchResults
                          .take(5)
                          .map(
                            (u) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB),
                                radius: 18,
                                child: Text(
                                  u.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(u.name),
                              subtitle: Text(
                                u.phone,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () => _addMember(u),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Members List
                for (int i = 0; i < _members.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                          radius: 18,
                          child: Text(
                            _members[i].name.isNotEmpty
                                ? _members[i].name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _members[i].name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (_members[i].isPayer)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                _members[i].isPayer
                                    ? (myShare > 0
                                          ? '₹${myShare.toStringAsFixed(0)}'
                                          : 'Set your share above')
                                    : 'Will declare their share',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _members[i].isPayer
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_members[i].isPayer)
                          IconButton(
                            onPressed: () => _removeMember(i),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFF43F5E),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Wallet selector
                if (provider.user != null &&
                    provider.user!.wallets.isNotEmpty) ...[
                  Text(
                    'Paying From',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.user!.wallets.map((w) {
                      final active = _wallet == w.name;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _wallet = active ? null : w.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2563EB)
                                : isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
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
                                w.type == 'cash'
                                    ? Icons.money_rounded
                                    : Icons.account_balance_rounded,
                                size: 16,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                w.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Submit Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Open Pool',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PoolMember {
  String userId;
  String name;
  bool isPayer;

  _PoolMember({required this.userId, required this.name, this.isPayer = false});
}
