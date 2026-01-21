import 'package:izintakip_app/core/auth/auth_state.dart';
import 'package:izintakip_app/features/leave/data/leave_service.dart';
import 'models/calendar_leave_event.dart';

class CalendarService {
  final LeaveService _leave = LeaveService();

  DateTime _k(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Map<DateTime, List<CalendarLeaveEvent>>> loadCalendar() async {
    final isManager = AuthState.isManager == true;

    // Normal kullanıcı: sadece kendi izinleri
    if (!isManager) {
      final my = await _leave.getMyLeaves();
      final events = my.map((x) {
        return CalendarLeaveEvent(
          leaveRequestId: x.leaveRequestId,
          title: x.leaveTypeName ?? "İzin",
          startDate: x.startDate,
          endDate: x.endDate,
          status: x.status ?? "",
          statusId: _guessStatusId(x.status),
          isCancelled: x.isCancelled,
          kind: CalendarEventKind.mine,
        );
      }).toList();

      return _toDayMap(events);
    }

    // Manager: kendi + departman (pending + history)
    final res = await Future.wait([
      _leave.getMyLeaves(),
      _leave.getPendingInbox(),
      _leave.getManagerHistory(),
    ]);

    final my = res[0] as List<dynamic>;
    final pending = res[1] as List<dynamic>;
    final history = res[2] as List<dynamic>;

    final events = <CalendarLeaveEvent>[];

    // my leaves
    for (final x in my) {
      events.add(CalendarLeaveEvent(
        leaveRequestId: x.leaveRequestId,
        title: "Ben • ${x.leaveTypeName ?? "İzin"}",
        startDate: x.startDate,
        endDate: x.endDate,
        status: x.status ?? "",
        statusId: _guessStatusId(x.status),
        isCancelled: x.isCancelled,
        kind: CalendarEventKind.mine,
      ));
    }

    for (final x in pending) {
      events.add(CalendarLeaveEvent(
        leaveRequestId: x.leaveRequestId,
        title: "${x.employeeName} • ${x.leaveTypeName}",
        startDate: x.startDate,
        endDate: x.endDate,
        status: "Bekleyen",
        statusId: 1,
        isCancelled: false,
        kind: CalendarEventKind.dept,
      ));
    }
    for (final x in history) {
      events.add(CalendarLeaveEvent(
        leaveRequestId: x.leaveRequestId,
        title: "${x.employeeName} • ${x.leaveTypeName}",
        startDate: x.startDate,
        endDate: x.endDate,
        status: x.status,
        statusId: _guessStatusId(x.status),
        isCancelled: false,
        kind: CalendarEventKind.dept,
      ));
    }

    return _toDayMap(events);
  }

  Map<DateTime, List<CalendarLeaveEvent>> _toDayMap(List<CalendarLeaveEvent> events) {
    final map = <DateTime, List<CalendarLeaveEvent>>{};

    for (final e in events) {
      final s = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
      final end = DateTime(e.endDate.year, e.endDate.month, e.endDate.day);

      for (var d = s; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final key = _k(d);
        map.putIfAbsent(key, () => []);
        map[key]!.add(e);
      }
    }

    for (final k in map.keys) {
      final seen = <int>{};
      map[k] = map[k]!.where((x) => seen.add(x.leaveRequestId)).toList();
    }

    return map;
  }

  int _guessStatusId(String? status) {
    final s = (status ?? "").toLowerCase();
    if (s.contains("bekle")) return 1;
    if (s.contains("onay")) return 2;
    if (s.contains("red")) return 3;
    return 0;
  }
}
