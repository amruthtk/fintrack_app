import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class SplitFriendsScreen extends StatefulWidget {
  const SplitFriendsScreen({super.key});

  @override
  State<SplitFriendsScreen> createState() => _SplitFriendsScreenState();
}

class _SplitFriendsScreenState extends State<SplitFriendsScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final String _splitType = 'equal'; // 'equal' or 'custom'
  final List<_SplitMember> _members = [];
  List<AppUser> _searchResults = [];
  bool _isSubmitting = false;
  String? _wallet;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addCurrentUser() {
    final user = context.read<AppProvider>().user;
    if (user != null && !_members.any((m) => m.userId == user.id)) {
      setState(() {
        _members.add(
          _SplitMember(userId: user.id, name: user.name, isPayer: true),
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
      _members.add(_SplitMember(userId: user.id, name: user.name));
      _searchCtrl.clear();
      _searchResults = [];
      _recalculate();
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
      _recalculate();
    });
  }

  void _recalculate() {
    if (_splitType != 'equal') return;
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    if (_members.isEmpty || total <= 0) return;
    final share = total / _members.length;
    for (final m in _members) {
      m.amount = share;
    }
  }

  Future<void> _submit() async {
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_members.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least 2 people')));
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
              'amount': m.amount,
              'status': m.isPayer ? 'paid' : 'pending',
            },
          )
          .toList();

      final payerMember = _members.firstWhere((m) => m.isPayer);

      await provider.createBill({
        'title': _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : 'Split Bill',
        'amount': total,
        'type': 'split',
        'splitType': _splitType,
        'category': 'Split',
        'wallet': _wallet,
        'payerId': payerId,
        'payerShare': payerMember.amount,
        'members': members,
        'memberIds': members.map((m) => m['id']).toList(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'time': DateTime.now().toIso8601String().substring(11, 19),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split created!'),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _addCurrentUser());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Split Bill',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title & Amount
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'What was it for?',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.currency_rupee_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    hintText: 'Total Amount',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Search & Add Friends
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
                                backgroundColor: const Color(0xFF6366F1),
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

                // Members
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
                            0xFF6366F1,
                          ).withValues(alpha: 0.15),
                          radius: 18,
                          child: Text(
                            _members[i].name.isNotEmpty
                                ? _members[i].name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
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
                                        'Payer',
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
                                '₹${_members[i].amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
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
                if (provider.user?.wallets.isNotEmpty == true) ...[
                  Text(
                    'Paid From',
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
                                ? const Color(0xFF6366F1)
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
                          child: Text(
                            w.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
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
                            'Create Split',
                            style: TextStyle(fontSize: 16),
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

class _SplitMember {
  String userId;
  String name;
  double amount = 0;
  bool isPayer;

  _SplitMember({
    required this.userId,
    required this.name,
    this.isPayer = false,
  });
}
