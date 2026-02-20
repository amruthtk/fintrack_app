import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount, {bool decimals = false}) {
    return decimals
        ? _inrFormatDecimal.format(amount)
        : _inrFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .join()
        .toUpperCase()
        .substring(
          0,
          name.split(' ').where((w) => w.isNotEmpty).length > 1 ? 2 : 1,
        );
  }

  static String todayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String currentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  static double calculateEqualSplit(double total, int people) {
    if (people == 0) return 0;
    return total / people;
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static IconData getCategoryIcon(String category) {
    // Returns material icon names — the actual icon mapping is in the UI
    return _categoryIcons[category] ?? _categoryIcons['Other']!;
  }

  static final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Travel': Icons.flight_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Bills': Icons.receipt_rounded,
    'Health': Icons.medical_services_rounded,
    'Education': Icons.school_rounded,
    'Salary': Icons.work_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Other': Icons.category_rounded,
  };
}
