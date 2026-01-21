enum CalendarEventKind { mine, dept }

class CalendarLeaveEvent {
  final int leaveRequestId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int statusId;
  final bool isCancelled;
  final CalendarEventKind kind;

  const CalendarLeaveEvent({
    required this.leaveRequestId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.statusId,
    required this.isCancelled,
    required this.kind,
  });
}
