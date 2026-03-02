import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _emoji = '👥';
  final List<AppUser> _members = [];
  List<AppUser> _searchResults = [];
  bool _saving = false;

  static const emojis = [
    '👥',
    '🏠',
    '✈️',
    '🎉',
    '🍕',
    '🎬',
    '💼',
    '⚽',
    '🎸',
    '🏋️',
    '📚',
    '🍽️',
    '🚗',
    '🎮',
    '🛒',
    '💰',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppProvider>().user;
      if (user != null) _members.add(user);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await context.read<AppProvider>().searchUsers(q);
    setState(() => _searchResults = results);
  }

  void _addMember(AppUser user) {
    if (_members.any((m) => m.id == user.id)) return;
    setState(() {
      _members.add(user);
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_members.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least 2 members')));
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    await provider.createGroup({
      'name': _nameCtrl.text.trim(),
      'emoji': _emoji,
      'memberIds': _members.map((m) => m.id).toList(),
      'createdBy': provider.user?.id ?? '',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.pop();
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
          'Create Group',
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
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.group_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                hintText: 'Group Name',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text(
              'Icon',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emojis.map((e) {
                final active = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                          : isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: active
                          ? Border.all(color: const Color(0xFF2563EB), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Search
            TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                hintText: 'Search people to add',
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
                          subtitle: Text(u.phone),
                          onTap: () => _addMember(u),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),
            Text(
              'Members (${_members.length})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _members
                  .map(
                    (m) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          m.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      label: Text(m.name),
                      deleteIcon: m.id == context.read<AppProvider>().user?.id
                          ? null
                          : const Icon(Icons.close, size: 16),
                      onDeleted: m.id == context.read<AppProvider>().user?.id
                          ? null
                          : () {
                              setState(
                                () => _members.removeWhere((u) => u.id == m.id),
                              );
                            },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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
                    : const Text(
                        'Create Group',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
