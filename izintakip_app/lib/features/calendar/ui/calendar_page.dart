import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/calendar_service.dart';
import '../data/models/calendar_leave_event.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _service = CalendarService();

  late Future<Map<DateTime, List<CalendarLeaveEvent>>> _future;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _k(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _future = _service.loadCalendar();
    _selectedDay = _k(DateTime.now());
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.loadCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Takvim"),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<DateTime, List<CalendarLeaveEvent>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Hata: ${snap.error}"),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Tekrar dene"),
                  )
                ],
              );
            }

            final map = snap.data ?? const <DateTime, List<CalendarLeaveEvent>>{};
            final selectedKey = _k(_selectedDay ?? DateTime.now());
            final dayEvents = map[selectedKey] ?? const <CalendarLeaveEvent>[];

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar<CalendarLeaveEvent>(
                      firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                      lastDay: DateTime(DateTime.now().year + 2, 12, 31),
                      focusedDay: _focusedDay,
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) => map[_k(day)] ?? const [],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = _k(selectedDay);
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return const SizedBox.shrink();

                          final hasMine = events.any((e) => e.kind == CalendarEventKind.mine);
                          final hasDept = events.any((e) => e.kind == CalendarEventKind.dept);

                          final dots = <Color>[];
                          if (hasMine) dots.add(cs.primary);
                          if (hasDept) dots.add(cs.secondary);

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: dots
                                    .map((c) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                ))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Seçili gün: ${selectedKey.day.toString().padLeft(2, '0')}.${selectedKey.month.toString().padLeft(2, '0')}.${selectedKey.year}",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                if (dayEvents.isEmpty)
                  Text("Bu gün için izin yok.", style: TextStyle(color: cs.onSurfaceVariant))
                else
                  ...dayEvents.map((e) => _EventTile(e)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarLeaveEvent e;
  const _EventTile(this.e);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isPending = e.statusId == 1 && !e.isCancelled;
    final isApproved = e.statusId == 2 && !e.isCancelled;
    final isRejected = e.statusId == 3;
    final isCancelled = e.isCancelled;

    Color bg;
    Color fg;
    String label;

    if (isCancelled) {
      bg = cs.surfaceContainerHighest; fg = cs.onSurfaceVariant; label = "İptal";
    } else if (isPending) {
      bg = cs.tertiaryContainer; fg = cs.onTertiaryContainer; label = "Bekleyen";
    } else if (isApproved) {
      bg = cs.secondaryContainer; fg = cs.onSecondaryContainer; label = "Onay";
    } else if (isRejected) {
      bg = cs.errorContainer; fg = cs.onErrorContainer; label = "Red";
    } else {
      bg = cs.surfaceContainerHighest; fg = cs.onSurfaceVariant; label = e.status;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text("${_fmt(e.startDate)} → ${_fmt(e.endDate)}"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
}
