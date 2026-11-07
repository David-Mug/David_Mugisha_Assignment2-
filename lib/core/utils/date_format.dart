import 'package:intl/intl.dart';

/// Date helpers so every screen formats dates the same way.
abstract final class AppDateFormat {
  /// "2 hours ago", "1 day ago", or a full date for anything older than a week.
  static String relative(DateTime? date, {DateTime? now}) {
    if (date == null) return 'Just now';
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return _plural(diff.inMinutes, 'minute');
    if (diff.inDays < 1) return _plural(diff.inHours, 'hour');
    if (diff.inDays < 7) return _plural(diff.inDays, 'day');
    return short(date);
  }

  /// "Oct 15, 2026"
  static String short(DateTime? date) =>
      date == null ? '—' : DateFormat.yMMMd().format(date);

  /// "Oct 15, 2026 at 10:24 AM"
  static String full(DateTime? date) => date == null
      ? '—'
      : '${DateFormat.yMMMd().format(date)} at ${DateFormat.jm().format(date)}';

  /// "Oct 15, 10:24 AM" — compact, for the timeline.
  static String compact(DateTime? date) =>
      date == null ? '—' : DateFormat('MMM d, h:mm a').format(date);

  static String _plural(int n, String unit) =>
      '$n $unit${n == 1 ? '' : 's'} ago';
}
