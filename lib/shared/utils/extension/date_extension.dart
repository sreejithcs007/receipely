import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  String get toWeekdayName {
    return DateFormat('EEEE').format(this);
  }

  String get toShortWeekdayName {
    return DateFormat('E').format(this);
  }

  String get toMonthDayString {
    return DateFormat('MMMM d').format(this);
  }

  String get toFullDateString {
    return DateFormat('yMMMMd').format(this);
  }

  String get toDatabaseString {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}
