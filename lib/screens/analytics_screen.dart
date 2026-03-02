import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../models/transaction.dart' as tx;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'month'; // 'week', 'month', 'year'

  List<tx.Transaction> _filterByPeriod(List<tx.Transaction> all) {
    final now = DateTime.now();
    return all.where((t) {
      if (t.type != 'expense') return false;
      try {
        final d = DateTime.parse(t.date);
        switch (_period) {
          case 'week':
            return now.difference(d).inDays <= 7;
          case 'month':
            return d.month == now.month && d.year == now.year;
          case 'year':
            return d.year == now.year;
          default:
            return true;
        }
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Map<String, double> _categoryBreakdown(List<tx.Transaction> filtered) {
    final map = <String, double>{};
    for (final t in filtered) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final filtered = _filterByPeriod(provider.transactions);
        final categoryData = _categoryBreakdown(filtered);
        final totalSpent = categoryData.values.fold(0.0, (s, v) => s + v);

        final sortedEntries = categoryData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ['week', 'month', 'year'].map((p) {
                        final active = _period == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p[0].toUpperCase() + p.substring(1),
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Spending',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.formatCurrency(totalSpent),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${filtered.length} transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pie Chart
                  if (sortedEntries.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: sortedEntries.asMap().entries.map((
                                  e,
                                ) {
                                  final idx = e.key;
                                  final entry = e.value;
                                  final pct = (entry.value / totalSpent * 100);
                                  final colors = [
                                    const Color(0xFF2563EB),
                                    const Color(0xFFF43F5E),
                                    const Color(0xFF10B981),
                                    const Color(0xFFF59E0B),
                                    const Color(0xFF06B6D4),
                                    const Color(0xFF1E40AF),
                                    const Color(0xFFF97316),
                                    const Color(0xFFEC4899),
                                  ];
                                  return PieChartSectionData(
                                    value: entry.value,
                                    title: pct >= 8
                                        ? '${pct.toStringAsFixed(0)}%'
                                        : '',
                                    color: colors[idx % colors.length],
                                    radius: 32,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: sortedEntries.asMap().entries.map((e) {
                              final idx = e.key;
                              final entry = e.value;
                              final colors = [
                                const Color(0xFF2563EB),
                                const Color(0xFFF43F5E),
                                const Color(0xFF10B981),
                                const Color(0xFFF59E0B),
                                const Color(0xFF06B6D4),
                                const Color(0xFF1E40AF),
                                const Color(0xFFF97316),
                                const Color(0xFFEC4899),
                              ];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colors[idx % colors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category List
                    ...sortedEntries.map((entry) {
                      final pct = totalSpent > 0
                          ? (entry.value / totalSpent * 100)
                          : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      backgroundColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      color: const Color(0xFF2563EB),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Helpers.formatCurrency(entry.value),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  if (sortedEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 48,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No spending data\nfor this period',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
