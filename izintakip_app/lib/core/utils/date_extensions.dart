extension DateFormatting on DateTime {
  String toTRDate() {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return "$d.$m.$year";
  }
}