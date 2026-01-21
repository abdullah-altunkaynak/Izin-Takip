import 'package:flutter/material.dart';
import 'package:izintakip_app/core/utils/date_extensions.dart';
import '../../../core/utils/haptics.dart';
import '../data/leave_service.dart';
import '../data/models/my_leave_request.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/routing/app_routes.dart';
import 'leave_create_page.dart';
import 'leave_detail_page.dart';

class MyLeavesPage extends StatefulWidget {
  const MyLeavesPage({super.key});

  @override
  State<MyLeavesPage> createState() => _MyLeavesPageState();
}

class _MyLeavesPageState extends State<MyLeavesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = LeaveService();

  Future<List<MyLeaveRequest>>? _futureAll;
  Future<List<MyLeaveRequest>>? _futurePending;
  Future<List<MyLeaveRequest>>? _futureHistory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _futureAll = _service.getMyLeaves(filter: LeaveFilter.all);
      _futurePending = _service.getMyLeaves(filter: LeaveFilter.pending);
      _futureHistory = _service.getMyLeaves(filter: LeaveFilter.history);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    AuthService().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.authGate, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İzin Taleplerim"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tümü"),
            Tab(text: "Bekleyen"),
            Tab(text: "Geçmiş"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Yenile",
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Çıkış",
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        color: cs.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            _LeavesList(future: _futureAll, onRefresh: _refreshAll),
            _LeavesList(future: _futurePending, onRefresh: _refreshAll),
            _LeavesList(future: _futureHistory, onRefresh: _refreshAll),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LeaveCreatePage()),
          );
          if (created == true) _refreshAll();
        },
        icon: const Icon(Icons.add),
        label: const Text("Yeni Talep"),
      ),
    );
  }
}

class _LeavesList extends StatelessWidget {
  final Future<List<MyLeaveRequest>>? future;
  final VoidCallback onRefresh;

  const _LeavesList({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Haptics.refresh();
        onRefresh();
        await Haptics.light();
      },
      child: FutureBuilder<List<MyLeaveRequest>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: onRefresh,
            );
          }

          final items = snapshot.data ?? const <MyLeaveRequest>[];

          if (items.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return InkWell(
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LeaveDetailPage(leaveRequestId: item.leaveRequestId),
                    ),
                  );

                  if (changed == true) {
                    onRefresh();
                  }
                },
                child: _LeaveCard(item: items[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final MyLeaveRequest item;
  const _LeaveCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateRange = "${item.startDate.toTRDate()} → ${item.endDate.toTRDate()}";
    final subtitle = (item.description == null || item.description!.trim().isEmpty)
        ? "Açıklama yok"
        : item.description!.trim();
    final cancelled = item.isCancelled;

    return Opacity(opacity: cancelled ? 0.6 : 1.0,child: Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.leaveTypeName ?? "İzin",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: item.status, isCancelled: item.isCancelled),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(dateRange, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (item.rejectionReason != null && item.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.block_outlined, color: cs.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Red nedeni: ${item.rejectionReason!.trim()}",
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),);
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  final bool isCancelled;
  const _StatusBadge({required this.status, required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = (status ?? "").trim().toLowerCase();

    final (bg, fg, text, icon) = switch (s) {
      'Beklemede' => (cs.tertiaryContainer, cs.onTertiaryContainer, 'Beklemede', Icons.hourglass_top),
      'Onaylandı' => (cs.primaryContainer, cs.onPrimaryContainer, 'Onaylandı', Icons.check_circle_outline),
      'Reddedildi' => (cs.errorContainer, cs.onErrorContainer, 'Reddedildi', Icons.highlight_off),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant, status ?? 'Durum', Icons.info_outline),
    };
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              "İptal Edildi",
              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _sk(cs, h: 16, w: double.infinity),
            const SizedBox(height: 10),
            _sk(cs, h: 12, w: 220),
            const SizedBox(height: 10),
            _sk(cs, h: 12, w: double.infinity),
            const SizedBox(height: 6),
            _sk(cs, h: 12, w: 280),
          ],
        ),
      ),
    );
  }

  Widget _sk(ColorScheme cs, {required double h, required double w}) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.inbox_outlined, size: 56, color: cs.onSurfaceVariant),
        const SizedBox(height: 14),
        Text(
          "Kayıt bulunamadı",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          "Henüz bir izin talebiniz yok ya da seçtiğiniz filtreye uygun kayıt yok.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.wifi_off_outlined, size: 56, color: cs.onSurfaceVariant),
        const SizedBox(height: 14),
        Text(
          "Bir hata oluştu",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
          ),
        ),
      ],
    );
  }
}
