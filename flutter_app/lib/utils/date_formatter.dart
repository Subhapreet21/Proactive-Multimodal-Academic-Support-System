import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }
  
  static String formatTime(String time) {
    // Convert 24h format to 12h format
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    }
    return time;
  }
  
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return formatDate(date);
    }
  }
  
  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
}
