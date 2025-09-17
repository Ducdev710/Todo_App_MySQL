// lib/utils/date_utils.dart
import 'package:intl/intl.dart';
// ✅ IMPORT để sử dụng Color
import 'package:flutter/material.dart';

class DateTimeUtils {
  // ✅ DATE FORMATTERS
  static final DateFormat _dayMonthYear = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayMonthYearTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _iso8601 = DateFormat("yyyy-MM-ddTHH:mm:ss");
  static final DateFormat _shortDate = DateFormat('dd MMM');
  static final DateFormat _fullDate = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _apiFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");

  // ✅ BASIC DATE FORMATTING
  static String formatDate(DateTime date) {
    return _dayMonthYear.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dayMonthYearTime.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeOnly.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDate.format(date);
  }

  static String formatFullDate(DateTime date) {
    return _fullDate.format(date);
  }

  // ✅ API DATE FORMATTING (for backend communication)
  static String formatForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  static DateTime? parseFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      return null;
    }
  }

  // ✅ RELATIVE DATE FORMATTING (for UI display)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    // Exact time-based differences for same day
    if (difference == 0) {
      final timeDifference = date.difference(now);

      if (timeDifference.inMinutes.abs() < 1) {
        return 'Ngay bây giờ';
      } else if (timeDifference.inMinutes < 0) {
        final minutes = timeDifference.inMinutes.abs();
        if (minutes < 60) {
          return '$minutes phút trước';
        } else {
          final hours = timeDifference.inHours.abs();
          return '$hours giờ trước';
        }
      } else {
        final minutes = timeDifference.inMinutes;
        if (minutes < 60) {
          return 'Còn $minutes phút';
        } else {
          final hours = timeDifference.inHours;
          return 'Còn $hours giờ';
        }
      }
    }

    // Day-based differences
    switch (difference) {
      case -1:
        return 'Hôm qua';
      case 1:
        return 'Ngày mai';
      case -2:
        return '2 ngày trước';
      case 2:
        return 'Послезавтра'; // Fallback to Vietnamese
      default:
        if (difference > 0) {
          if (difference <= 7) {
            return 'Còn $difference ngày';
          } else if (difference <= 30) {
            final weeks = (difference / 7).ceil();
            return 'Còn $weeks tuần';
          } else {
            return formatShortDate(date);
          }
        } else {
          final absDiff = difference.abs();
          if (absDiff <= 7) {
            return '$absDiff ngày trước';
          } else if (absDiff <= 30) {
            final weeks = (absDiff / 7).ceil();
            return '$weeks tuần trước';
          } else {
            return formatShortDate(date);
          }
        }
    }
  }

  // ✅ DUE DATE SPECIFIC FORMATTING
  static String formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = targetDate.difference(today).inDays;

    if (difference < 0) {
      return 'Quá hạn ${difference.abs()} ngày';
    } else if (difference == 0) {
      final timeDiff = dueDate.difference(now);
      if (timeDiff.inHours > 0) {
        return 'Còn ${timeDiff.inHours} giờ';
      } else if (timeDiff.inMinutes > 0) {
        return 'Còn ${timeDiff.inMinutes} phút';
      } else {
        return 'Đã hết hạn';
      }
    } else if (difference == 1) {
      return 'Ngày mai lúc ${formatTime(dueDate)}';
    } else if (difference <= 7) {
      return 'Còn $difference ngày';
    } else {
      return formatDate(dueDate);
    }
  }

  // ✅ COLOR CODING for DUE DATES
  static DueDateColor getDueDateColor(DateTime dueDate, bool isCompleted) {
    if (isCompleted) {
      return DueDateColor.completed;
    }

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return DueDateColor.overdue;
    } else if (difference.inDays == 0) {
      return difference.inHours <= 2 ? DueDateColor.urgent : DueDateColor.today;
    } else if (difference.inDays == 1) {
      return DueDateColor.tomorrow;
    } else if (difference.inDays <= 3) {
      return DueDateColor.soon;
    } else {
      return DueDateColor.future;
    }
  }

  // ✅ DATE VALIDATION
  static bool isValidDate(DateTime? date) {
    return date != null;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  static bool isDueSoon(DateTime dueDate, {int daysThreshold = 3}) {
    final difference = dueDate.difference(DateTime.now()).inDays;
    return difference >= 0 && difference <= daysThreshold;
  }

  // ✅ DATE CALCULATIONS
  static int daysBetween(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays;
  }

  static int daysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  static int daysOverdue(DateTime dueDate) {
    final days = daysUntilDue(dueDate);
    return days < 0 ? days.abs() : 0;
  }

  // ✅ DATE RANGES
  static bool isDateInRange(
      DateTime date, DateTime startDate, DateTime endDate) {
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endDate.add(const Duration(seconds: 1)));
  }

  static List<DateTime> getWeekDates(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  static List<DateTime> getMonthDates(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final days = lastDay.day;

    return List.generate(
        days, (index) => DateTime(date.year, date.month, index + 1));
  }

  // ✅ TIME ZONE HANDLING
  static DateTime toLocal(DateTime utcDate) {
    return utcDate.toLocal();
  }

  static DateTime toUtc(DateTime localDate) {
    return localDate.toUtc();
  }

  // ✅ BUSINESS LOGIC HELPERS
  static bool isWorkingDay(DateTime date) {
    return date.weekday >= 1 && date.weekday <= 5; // Monday to Friday
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == 6 || date.weekday == 7; // Saturday and Sunday
  }

  static DateTime getNextWorkingDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (!isWorkingDay(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  static DateTime getPreviousWorkingDay(DateTime date) {
    DateTime prevDay = date.subtract(const Duration(days: 1));
    while (!isWorkingDay(prevDay)) {
      prevDay = prevDay.subtract(const Duration(days: 1));
    }
    return prevDay;
  }

  // ✅ QUICK DATE CREATORS
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date)
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // ✅ PARSING HELPERS
  static DateTime? tryParseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Try different formats
      final formats = [
        _dayMonthYear,
        _dayMonthYearTime,
        _iso8601,
        _apiFormat,
      ];

      for (final format in formats) {
        try {
          return format.parse(dateString);
        } catch (e) {
          continue;
        }
      }

      // Fallback to DateTime.parse
      return DateTime.parse(dateString);
    } catch (e) {
      print('Failed to parse date: $dateString - $e');
      return null;
    }
  }

  // ✅ FORMATTING OPTIONS
  static String formatWithCustomPattern(DateTime date, String pattern) {
    try {
      final formatter = DateFormat(pattern);
      return formatter.format(date);
    } catch (e) {
      print('Invalid date pattern: $pattern - $e');
      return formatDate(date);
    }
  }

  // ✅ AGE CALCULATION
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // ✅ DURATION FORMATTING
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} phút';
    } else {
      return '${duration.inSeconds} giây';
    }
  }

  // ✅ COMPARISON HELPERS
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isSameWeek(DateTime date1, DateTime date2) {
    final start1 = startOfWeek(date1);
    final start2 = startOfWeek(date2);
    return isSameDay(start1, start2);
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  // ✅ CONSTANTS
  static DateTime get now => DateTime.now();
  static DateTime get today => startOfDay(DateTime.now());
  static DateTime get tomorrow => today.add(const Duration(days: 1));
  static DateTime get yesterday => today.subtract(const Duration(days: 1));
}

// ✅ ENUM for DUE DATE COLORS
enum DueDateColor {
  completed,
  overdue,
  urgent,
  today,
  tomorrow,
  soon,
  future,
}

// ✅ EXTENSION for DueDateColor
extension DueDateColorExtension on DueDateColor {
  Color get color {
    switch (this) {
      case DueDateColor.completed:
        return const Color(0xFFE0E0E0); // Grey
      case DueDateColor.overdue:
        return const Color(0xFFFFCDD2); // Light Red
      case DueDateColor.urgent:
        return const Color(0xFFFF5722); // Deep Orange
      case DueDateColor.today:
        return const Color(0xFFFFE0B2); // Light Orange
      case DueDateColor.tomorrow:
        return const Color(0xFFFFF3E0); // Very Light Orange
      case DueDateColor.soon:
        return const Color(0xFFE1F5FE); // Light Blue
      case DueDateColor.future:
        return const Color(0xFFE8F5E8); // Light Green
    }
  }

  String get description {
    switch (this) {
      case DueDateColor.completed:
        return 'Đã hoàn thành';
      case DueDateColor.overdue:
        return 'Quá hạn';
      case DueDateColor.urgent:
        return 'Khẩn cấp';
      case DueDateColor.today:
        return 'Hôm nay';
      case DueDateColor.tomorrow:
        return 'Ngày mai';
      case DueDateColor.soon:
        return 'Sắp đến hạn';
      case DueDateColor.future:
        return 'Tương lai';
    }
  }
}

// ✅ DATE PICKER HELPERS
class DatePickerUtils {
  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      // Sử dụng locale hiện tại của app thay vì force vi_VN
    );
  }

  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    final date = await pickDate(context, initialDate: initialDate);
    if (date == null) return null;

    final time = await pickTime(context);
    if (time == null) return date;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

// ✅ DATE RANGE CLASS
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return DateTimeUtils.isDateInRange(date, start, end);
  }

  Duration get duration => end.difference(start);

  int get daysCount => DateTimeUtils.daysBetween(start, end) + 1;

  bool get isValid => start.isBefore(end) || start.isAtSameMomentAs(end);

  @override
  String toString() {
    return '${DateTimeUtils.formatDate(start)} - ${DateTimeUtils.formatDate(end)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
