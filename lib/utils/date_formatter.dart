import 'package:intl/intl.dart';

class DateFormatter {
  // Format: Feb 21, 2026
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format: 10:45 AM
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // Format: Feb 21, 2026 • 10:45 AM
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  // Format: Feb 21
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  // Get relative time (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inDays > 365) {
        final years = (absDifference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      } else if (absDifference.inDays > 30) {
        final months = (absDifference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (absDifference.inDays > 0) {
        return '${absDifference.inDays} ${absDifference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (absDifference.inHours > 0) {
        return '${absDifference.inHours} ${absDifference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (absDifference.inMinutes > 0) {
        return '${absDifference.inMinutes} ${absDifference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'just now';
      }
    } else {
      // Future
      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'in $years ${years == 1 ? 'year' : 'years'}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'in $months ${months == 1 ? 'month' : 'months'}';
      } else if (difference.inDays > 0) {
        return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
      } else if (difference.inMinutes > 0) {
        return 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
      } else {
        return 'now';
      }
    }
  }

  // Check if event is upcoming
  static bool isUpcoming(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Check if event is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

