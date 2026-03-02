import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      final group = provider.groups
          .where((g) => g.id == widget.groupId)
          .firstOrNull;
      if (group != null) {
        provider.fetchUsersByIds(group.memberIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final group = provider.groups
            .where((g) => g.id == widget.groupId)
            .firstOrNull;

        if (group == null) {
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
            ),
            body: const Center(child: Text('Group not found')),
          );
        }

        final userId = provider.user?.id ?? '';

        // Get group split transactions — match by groupId or member overlap
        final groupSplits = provider.transactions
            .where((t) => t.type == 'split' && t.splitType != 'pool')
            .where((t) {
              // Primary: exact groupId match
              if (t.groupId == widget.groupId) return true;
              // Fallback: member overlap for older bills without groupId
              if (t.groupId == null) {
                final memberIds = t.members.map((m) => m.id).toSet();
                return group.memberIds.toSet().containsAll(memberIds) &&
                    memberIds.length > 1;
              }
              return false;
            })
            .toList();
        groupSplits.sort((a, b) => b.date.compareTo(a.date));

        // Compute group totals
        double totalGroupSpent = 0;
        double myShare = 0;
        for (final t in groupSplits) {
          totalGroupSpent += t.amount;
          if (t.payerId == userId) {
            myShare += t.payerShare ?? 0;
          } else {
            final myEntry = t.members.where((m) => m.id == userId).firstOrNull;
            if (myEntry != null) myShare += myEntry.amount;
          }
        }

        // Compute group-specific settlements
        double groupReceivables = 0;
        int receivableCount = 0;
        double groupPayables = 0;
        int payableCount = 0;
        for (final t in groupSplits) {
          if (t.payerId == userId) {
            // I paid — others owe me
            for (final m in t.members) {
              if (m.id != userId && m.status != 'paid') {
                groupReceivables += m.amount;
                receivableCount++;
              }
            }
          } else {
            // Someone else paid — I owe them
            final myEntry = t.members.where((m) => m.id == userId).firstOrNull;
            if (myEntry != null && myEntry.status != 'paid') {
              groupPayables += myEntry.amount;
              payableCount++;
            }
          }
        }

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              // ── Pinned Header ──
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                backgroundColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF2563EB),
                elevation: 0,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  // Roulette Action
                  IconButton(
                    onPressed: () {
                      final memberNames = group.memberIds.map((id) {
                        if (id == userId) return 'You';
                        final member = provider.getCachedUser(id);
                        return member?.name.split(' ').first ?? 'User';
                      }).toList();

                      if (memberNames.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Need at least 2 members to spin!'),
                            backgroundColor: Color(0xFFF59E0B),
                          ),
                        );
                        return;
                      }

                      context.push(
                        '/spin-wheel',
                        extra: {
                          'memberNames': memberNames,
                          'groupName': group.name,
                        },
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎰', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(context, provider, group);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Color(0xFFF43F5E),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Group',
                              style: TextStyle(color: Color(0xFFF43F5E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFF2563EB),
                                const Color(0xFF1E40AF),
                              ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                group.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            )
                            .animate()
                            .scale(curve: Curves.easeOutBack, duration: 400.ms)
                            .fadeIn(),
                        const SizedBox(height: 12),
                        Text(
                          group.name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        Text(
                          '${group.memberIds.length} members',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stats Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _InfoCard(
                                  title: 'Total Spent',
                                  value: Helpers.formatCurrency(
                                    totalGroupSpent,
                                  ),
                                  icon: Icons.receipt_long_rounded,
                                  color: const Color(0xFF2563EB),
                                  isDark: isDark,
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutBack,
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _InfoCard(
                                  title: 'My Share',
                                  value: Helpers.formatCurrency(myShare),
                                  icon: Icons.person_rounded,
                                  color: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                )
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutBack,
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Settlements Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/settlements'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                          width: 1,
                        ),
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.handshake_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Settlements',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          if (groupReceivables > 0 || groupPayables > 0) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (groupReceivables > 0)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_downward_rounded,
                                            color: Color(0xFF10B981),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'To Receive',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(
                                                      0xFF10B981,
                                                    ).withValues(alpha: 0.8),
                                                  ),
                                                ),
                                                Text(
                                                  Helpers.formatCurrency(
                                                    groupReceivables,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$receivableCount',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (groupReceivables > 0 && groupPayables > 0)
                                  const SizedBox(width: 10),
                                if (groupPayables > 0)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'To Pay',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(
                                                      0xFFF59E0B,
                                                    ).withValues(alpha: 0.8),
                                                  ),
                                                ),
                                                Text(
                                                  Helpers.formatCurrency(
                                                    groupPayables,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFF59E0B,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$payableCount',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'All settled up! 🎉',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
                ),
              ),

              // ── Members Section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: group.memberIds.length + 1, // +1 for Add button
                    itemBuilder: (context, index) {
                      // Last item = Add Member button
                      if (index == group.memberIds.length) {
                        return Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showAddMemberSheet(
                                      context,
                                      provider,
                                      group,
                                    ),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.4),
                                          width: 1.5,
                                          strokeAlign:
                                              BorderSide.strokeAlignOutside,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person_add_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: (640 + index * 60).ms)
                            .scale(begin: const Offset(0.5, 0.5));
                      }

                      final memberId = group.memberIds[index];
                      final member = provider.getCachedUser(memberId);
                      final isMe = memberId == userId;

                      return Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isMe
                                          ? [
                                              const Color(0xFF2563EB),
                                              const Color(0xFF1E40AF),
                                            ]
                                          : [
                                              const Color(0xFF334155),
                                              const Color(0xFF475569),
                                            ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: isMe
                                        ? Border.all(
                                            color: const Color(0xFF2563EB),
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    member?.initials ?? '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isMe
                                      ? 'You'
                                      : (member?.name.split(' ').first ??
                                            'User'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isMe
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (640 + index * 60).ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            curve: Curves.easeOutBack,
                          );
                    },
                  ),
                ),
              ),

              // ── Recent Transactions ──
              if (groupSplits.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Bills',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(
                            '/group-bills/${widget.groupId}?name=${Uri.encodeComponent(group.name)}',
                          ),
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final t = groupSplits[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Helpers.getCategoryIcon(t.category),
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
                                      t.title.isNotEmpty ? t.title : t.category,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      t.date,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Helpers.formatCurrency(t.amount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: groupSplits.length > 5
                          ? 5
                          : groupSplits.length,
                    ),
                  ),
                ),
              ],
              // Bottom padding
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/split?groupId=${widget.groupId}'),
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.call_split_rounded, color: Colors.white),
            label: const Text(
              'Split Bill',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddMemberSheet(
    BuildContext context,
    AppProvider provider,
    Group group,
  ) {
    final searchCtrl = TextEditingController();
    List<AppUser> searchResults = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> search(String q) async {
            if (q.isEmpty) {
              setState(() => searchResults = []);
              return;
            }
            final results = await provider.searchUsers(q);
            // Exclude existing members
            setState(() {
              searchResults = results
                  .where((u) => !group.memberIds.contains(u.id))
                  .toList();
            });
          }

          Future<void> addMember(AppUser user) async {
            final updatedIds = [...group.memberIds, user.id];
            await provider.updateGroup(group.id, {'memberIds': updatedIds});
            await provider.fetchUsersByIds([user.id]);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} added to the group'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'Add Member',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      hintText: 'Search by name, phone or username',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchCtrl.text.isEmpty
                                ? 'Search for people to add'
                                : 'No users found',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: searchResults.length,
                          itemBuilder: (ctx, i) {
                            final u = searchResults[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB),
                                radius: 20,
                                child: Text(
                                  u.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                u.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Text(
                                u.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => addMember(u),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Group group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Group?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete "${group.name}". Bills won\'t be affected.',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteGroup(group.id);
              if (context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
