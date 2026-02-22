import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format currency with $ symbol
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format currency without decimals if whole number
  static String formatCompact(double amount) {
    if (amount % 1 == 0) {
      return '\$${amount.toInt()}';
    }
    return format(amount);
  }

  // Format large numbers (e.g., 1.2K, 1.5M)
  static String formatLarge(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCompact(amount);
  }
}

