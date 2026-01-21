import 'package:flutter/material.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animated_status_chip.dart';
import '../../../core/widgets/theme_menu_button.dart';
import '../../auth/data/auth_service.dart';
import '../../calendar/ui/calendar_page.dart';
import '../../leave/ui/inbox_leaves_page.dart';
import '../../leave/ui/leave_detail_page.dart';
import '../data/dashboard_service.dart';
import '../data/models/dashboard_me.dart';
import '../data/models/dashboard_manager.dart';
import '../data/models/dashboard_latest_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = DashboardService();

  late Future<DashboardMe> _meFuture;
  Future<DashboardManager>? _managerFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _logout() {
    AuthService().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.authGate, (r) => false);
  }

  void _refreshAll() {
    _meFuture = _service.getMe();
    if (AuthState.isManager == true) {
      _managerFuture = _service.getManager();
    } else {
      _managerFuture = null;
    }
  }

  Future<void> _onRefresh() async {
    setState(_refreshAll);
    // FutureBuilder kendi kendine yenilenecek
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isManager = AuthState.isManager == true;

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard"),
      actions: [
        ThemeMenuButton(),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarPage()),
            );
          },
        ),
        IconButton(
          tooltip: "Çıkış",
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      ],),
      body: RefreshIndicator(
        onRefresh: () async {
          await Haptics.refresh();
          _onRefresh();
          await Haptics.light();
      },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            FutureBuilder<DashboardMe>(
              future: _meFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _MeSkeleton();
                }
                if (snap.hasError) {
                  return _ErrorCard(
                    title: "Özet yüklenemedi",
                    message: snap.error.toString(),
                    onRetry: () => setState(_refreshAll),
                  );
                }

                final me = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${me.year} • İzin Özeti",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _MeCards(me: me),
                    const SizedBox(height: 14),

                    // mini progress
                    _ProgressCard(
                      total: me.totalDays,
                      used: me.usedDays,
                      remaining: me.remainingDays,
                    ),

                    if (!isManager) ...[
                      const SizedBox(height: 16),
                      _HintCard(
                        icon: Icons.info_outline,
                        title: "İpucu",
                        message: "Yeni izin talebi oluştururken Pazar günleri izin hesabına dahil edilmez.",
                      ),
                    ],
                  ],
                );
              },
            ),

            if (isManager) ...[
              const SizedBox(height: 18),
              Text(
                "Yönetici Paneli",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              FutureBuilder<DashboardManager>(
                future: _managerFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _ManagerSkeleton();
                  }
                  if (snap.hasError) {
                    final msg = snap.error.toString();
                    final forbidden = msg.contains('403') || msg.toLowerCase().contains('forbid') || msg.toLowerCase().contains('forbidden');
                    return _ErrorCard(
                      title: forbidden ? "Yetkiniz yok" : "Yönetici verisi yüklenemedi",
                      message: forbidden ? "Bu alanı sadece yöneticiler görebilir." : msg,
                      onRetry: () => setState(_refreshAll),
                    );
                  }

                  final mgr = snap.data!;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: "Bekleyen Onay",
                              value: mgr.pendingApprovalCount.toString(),
                              icon: Icons.mark_email_unread_outlined,
                              tone: _Tone.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: "Bugün İzinde",
                              value: mgr.onLeaveTodayCount.toString(),
                              icon: Icons.beach_access_outlined,
                              tone: _Tone.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LatestListCard(
                        items: mgr.latest5,
                        onTapItem: (it) async {
                          final isManager = AuthState.isManager == true;

                          // yönetici ve Bekleyen: Onay Kutusu'na git
                          if (isManager && it.statusId == 1 && it.isCancelled == false) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InboxLeavesPage(initialTabIndex: 0,
                                    focusLeaveRequestId: it.leaveRequestId),
                              ),
                            );
                            return;
                          }

                          // Diğer durumlar: Detail göster (sadece görüntüleme)
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => LeaveDetailPage(
                                leaveRequestId: it.leaveRequestId,
                                isDashboard: true,
                              ),
                            ),
                          );

                          if (changed == true) setState(_refreshAll);
                        },
                      ),
                      const SizedBox(height: 8),
                      _HintCard(
                        icon: Icons.lightbulb_outline,
                        title: "Not",
                        message: "Onay kutusundan talepleri onaylayıp reddedebilirsiniz. Onaylanan talepler yıllık izinden düşer.",
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 10),
            Text(
              "Aşağı kaydırarak yenileyebilirsiniz.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _MeCards extends StatelessWidget {
  final DashboardMe me;
  const _MeCards({required this.me});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Toplam İzin",
                value: "${me.totalDays}",
                icon: Icons.event_available_outlined,
                tone: _Tone.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: "Kalan",
                value: "${me.remainingDays}",
                icon: Icons.timelapse_outlined,
                tone: _Tone.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Bekleyen",
                value: "${me.pendingCount}",
                icon: Icons.hourglass_bottom_outlined,
                tone: _Tone.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: "Onaylanan",
                value: "${me.approvedCount}",
                icon: Icons.verified_outlined,
                tone: _Tone.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int total;
  final int used;
  final int remaining;

  const _ProgressCard({
    required this.total,
    required this.used,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Yıllık İzin Kullanımı", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(minHeight: 10, value: progress),
            ),
            const SizedBox(height: 10),
            Text(
              "Kullanılan: $used • Kalan: $remaining",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestListCard extends StatelessWidget {
  final List<DashboardLatestItem> items;
  final void Function(DashboardLatestItem item)? onTapItem;

  const _LatestListCard({required this.items, this.onTapItem});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Son Talepler",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text("Henüz talep yok.", style: TextStyle(color: cs.onSurfaceVariant))
            else
              Column(
                children: items
                    .map((x) => _LatestRow(
                  item: x,
                  onTap: onTapItem == null ? null : () => onTapItem!(x),
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}


class _LatestRow extends StatelessWidget {
  final DashboardLatestItem item;
  final VoidCallback? onTap;
  const _LatestRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isPending = item.statusId == 1 && !item.isCancelled;
    final isApproved = item.statusId == 2 && !item.isCancelled;
    final isRejected = item.statusId == 3;
    final isCancelled = item.isCancelled == true;

    Color bg;
    Color fg;
    String label;

    if (isCancelled) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
      label = "İptal";
    } else if (isPending) {
      bg = cs.tertiaryContainer;
      fg = cs.onTertiaryContainer;
      label = "Bekleyen";
    } else if (isApproved) {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
      label = "Onay";
    } else if (isRejected) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
      label = "Red";
    } else {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
      label = item.status;
    }

    final kind = AnimatedStatusChip.fromApi(
      statusId: item.statusId,
      isCancelled: item.isCancelled,
    );

    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.employeeName, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                "${item.leaveTypeName} • ${_fmt(item.startDate)} → ${_fmt(item.endDate)}",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedStatusChip(
          kind: kind,
          label: label,
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ]
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? content
          : InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: content,
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final _Tone tone;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (tone) {
      case _Tone.primary:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case _Tone.success:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        break;
      case _Tone.warning:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case _Tone.danger:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HintCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(Icons.warning_amber_outlined, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar Dene"),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeSkeleton extends StatelessWidget {
  const _MeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkCard(),
        SizedBox(height: 10),
        _SkCard(),
      ],
    );
  }
}

class _ManagerSkeleton extends StatelessWidget {
  const _ManagerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkCard(),
        SizedBox(height: 10),
        _SkCard(),
      ],
    );
  }
}

class _SkCard extends StatelessWidget {
  const _SkCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),
            Container(height: 12, width: 220, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
          ],
        ),
      ),
    );
  }
}

enum _Tone { primary, success, warning, danger }
