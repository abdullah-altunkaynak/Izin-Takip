import 'package:flutter/material.dart';
import '../../../core/utils/date_extensions.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animated_status_chip.dart';
import '../data/leave_service.dart';
import '../data/models/leave_decision.dart';
import '../data/models/manager_leave_history.dart';
import '../data/models/pending_leave_request.dart';

class InboxLeavesPage extends StatefulWidget {
  final int initialTabIndex; // 0=Bekleyen, 1=Geçmiş
  final int? focusLeaveRequestId;

  const InboxLeavesPage({
    super.key,
    this.initialTabIndex = 0,
    this.focusLeaveRequestId,
  });


  @override
  State<InboxLeavesPage> createState() => _InboxLeavesPageState();
}

class _InboxLeavesPageState extends State<InboxLeavesPage> with SingleTickerProviderStateMixin {
  final _service = LeaveService();
  bool _working = false;
  late TabController _tab;
  late Future<List<PendingLeaveRequest>> _pendingFuture;
  late Future<List<ManagerLeaveHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    _refreshAll();

    // Dashboard'tan focus id ile gelindiyse: sayfa açılır açılmaz refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrent(); // setState içinde future yeniliyor zaten
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
  void _refreshAll() {
    _pendingFuture = _service.getPendingInbox();
    _historyFuture = _service.getManagerHistory();
  }
  Future<void> _refreshCurrent() async {
    setState(() {
      if (_tab.index == 0) {
        _pendingFuture = _service.getPendingInbox();
      } else {
        _historyFuture = _service.getManagerHistory();
      }
    });
  }
  void _afterDecisionRefresh() {
    setState(() {
      _pendingFuture = _service.getPendingInbox();
      _historyFuture = _service.getManagerHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _approve(PendingLeaveRequest item) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("İzni onayla"),
          content: Text("${item.employeeName} için bu izin talebini onaylamak istiyor musunuz?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Onayla")),
          ],
        ),
      );

      if (ok != true) return;

      setState(() => _working = true);
      try {
        final msg = await _service.decideLeaveRequest(
          id: item.leaveRequestId,
          decision: LeaveDecision(isApproved: true),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _afterDecisionRefresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }

    Future<void> _reject(PendingLeaveRequest item) async {
      final reason = await showDialog<String?>(
        context: context,
        builder: (dialogContext) {
          final ctrl = TextEditingController();

          return AlertDialog(
            title: const Text("İzni reddet"),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Red nedeni (zorunlu)",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, null);
                },
                child: const Text("Vazgeç"),
              ),
              FilledButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(dialogContext, text);
                },
                child: const Text("Reddet"),
              ),
            ],
          );
        },
      );

      if (reason == null) return;

      setState(() => _working = true);
      try {
        final msg = await _service.decideLeaveRequest(
          id: item.leaveRequestId,
          decision: LeaveDecision(isApproved: false, rejectionReason: reason),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        _afterDecisionRefresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }




    return Scaffold(
      appBar: AppBar(
        title: const Text("Onay Kutusu"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Bekleyen"),
            Tab(text: "Geçmiş"),
          ],
        ),

      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: [
              _PendingTab(
                future: _pendingFuture,
                onRefresh: _refreshCurrent,
                working: _working,
                onApprove: _approve,
                onReject: _reject,
                focusLeaveRequestId: widget.focusLeaveRequestId
              ),
              _HistoryTab(
                future: _historyFuture,
                onRefresh: _refreshCurrent,
              ),
            ],
          ),
          if (_working)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
  }


class _PendingTab extends StatelessWidget {
  final Future<List<PendingLeaveRequest>> future;
  final Future<void> Function() onRefresh;
  final bool working;
  final Future<void> Function(PendingLeaveRequest item) onApprove;
  final Future<void> Function(PendingLeaveRequest item) onReject;
  final int? focusLeaveRequestId;

  const _PendingTab({
    required this.future,
    required this.onRefresh,
    required this.working,
    required this.onApprove,
    required this.onReject,
    required this.focusLeaveRequestId
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Haptics.refresh();
        await onRefresh();
        await Haptics.light();
      },
      child: FutureBuilder<List<PendingLeaveRequest>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            return _ErrorState(title: "Bir hata oluştu", message: msg, onRetry: onRefresh);
          }
          final items0 = snapshot.data ?? const <PendingLeaveRequest>[];
          final items = items0.toList();
          final focusId = focusLeaveRequestId;
          final idx = focusId == null ? -1 : items.indexWhere((x) => x.leaveRequestId == focusId);

          if (focusId != null && idx == -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Seçilen talep artık bekleyen listesinde değil.")),
                );
              }
            });
          }
          if (items.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final it = items[i];
              final isFocus = focusLeaveRequestId != null && it.leaveRequestId == focusLeaveRequestId;

              return _PendingCard(
                item: it,
                highlight: isFocus,
                onApprove: working ? null : () => onApprove(it),
                onReject: working ? null : () => onReject(it),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final Future<List<ManagerLeaveHistory>> future;
  final Future<void> Function() onRefresh;

  const _HistoryTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Haptics.refresh();
        await onRefresh();
        await Haptics.light();
      },
      child: FutureBuilder<List<ManagerLeaveHistory>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              title: "Bir hata oluştu",
              message: snapshot.error.toString(),
              onRetry: onRefresh,
            );
          }

          final items = snapshot.data ?? const <ManagerLeaveHistory>[];
          if (items.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _HistoryCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ManagerLeaveHistory item;
  const _HistoryCard({required this.item});


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kind = item.status.toLowerCase().contains('red')
        ? LeaveStatusKind.rejected
        : LeaveStatusKind.approved; // history zaten pending değil

    final isRejected = item.status.toLowerCase().contains('red') || item.status.toLowerCase().contains('rejected');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
          Text(
              "${item.leaveTypeName} • ${item.startDate.toTRDate()} → ${item.endDate.toTRDate()}",
                style: TextStyle(color: cs.onSurfaceVariant)),

            const SizedBox(height: 10),

            Row(
              children: [
                AnimatedStatusChip(
                  kind: kind,
                  label: item.status,
                ),
                const Spacer(),
                if (item.approvedAt != null)
                  Text(item.approvedAt!.toTRDate(), style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),

            if (isRejected && (item.rejectionReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text("Red: ${item.rejectionReason}", style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}



class _PendingCard extends StatelessWidget {
  final PendingLeaveRequest item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool highlight;

  const _PendingCard({required this.item,
    required this.onApprove,
    required this.onReject,
    this.highlight = false,});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateRange = "${item.startDate.toTRDate()} → ${item.endDate.toTRDate()}";
    final desc = (item.description ?? '').trim();

    return Card(
      elevation: highlight ? 6 : 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
      side: highlight
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6)
        : BorderSide(color: Colors.transparent, width: 0)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.employeeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedStatusChip(
                  kind: LeaveStatusKind.pending,
                  label: "Bekleyen",
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              item.leaveTypeName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(dateRange, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),

            if (desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text("Reddet"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text("Onayla"),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _sk(cs, h: 40, w: double.infinity)),
                const SizedBox(width: 10),
                Expanded(child: _sk(cs, h: 40, w: double.infinity)),
              ],
            ),
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
          "Bekleyen talep yok",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          "Departmanınızda şu an onay bekleyen izin talebi bulunmuyor.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.warning_amber_outlined, size: 56, color: cs.onSurfaceVariant),
        const SizedBox(height: 14),
        Text(
          title,
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
