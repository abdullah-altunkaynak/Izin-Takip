int countLeaveDaysExcludingSundays(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  if (e.isBefore(s)) return 0;

  var days = 0;
  for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
    if (d.weekday != DateTime.sunday) days++;
  }
  return days;
}

DateTime todayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool isPastDay(DateTime d) => DateTime(d.year, d.month, d.day).isBefore(todayLocal());

bool hasSundayBetween(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
    if (d.weekday == DateTime.sunday) return true;
  }
  return false;
}
