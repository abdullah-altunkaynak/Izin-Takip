import 'package:flutter/material.dart';
import 'package:izintakip_app/core/utils/date_extensions.dart';
import '../../../core/auth/auth_state.dart';
import '../data/leave_service.dart';
import '../data/models/my_leave_request.dart';
import 'edit_result.dart';
import 'leave_edit_page.dart';

class LeaveDetailPage extends StatefulWidget {
  final int leaveRequestId;
  final bool isDashboard;
  const LeaveDetailPage({super.key, required this.leaveRequestId, this.isDashboard = false});

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  final _service = LeaveService();
  late Future<MyLeaveRequest> _future;
  bool _working = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyLeaveDetail(widget.leaveRequestId);
  }

  bool _isPending(MyLeaveRequest r) {
    final s = (r.status ?? '').toLowerCase();
    return s == 'pending' || s == 'beklemede';
  }

  Future<void> _cancel(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Talebi iptal et"),
        content: const Text("Bu izin talebini iptal etmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("İptal Et")),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _working = true);
    try {
      await _service.cancelMyLeave(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(_changed);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("Talep Detayı")),
          body: Stack(
            children: [
              FutureBuilder<MyLeaveRequest>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text("Hata: ${snap.error}"));
                  }
                  final r = snap.data!;
                  final canEdit = _isPending(r) && !r.isCancelled && !widget.isDashboard;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (AuthState.isManager == true && (r.employeeName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          child: Text(
                            "Personel: ${r.employeeName}",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _kv("İzin Türü", r.leaveTypeName ?? "-"),
                      _kv("Tarih", "${r.startDate.toTRDate()} → ${r.endDate.toTRDate()}"),
                      _kv("Durum", r.status ?? "-"),
                      _kv("Açıklama", (r.description ?? "").trim().isEmpty ? "-" : r.description!.trim()),
                      if ((r.rejectionReason ?? "").trim().isNotEmpty)
                        _kv("Red Nedeni", r.rejectionReason!.trim()),

                      const SizedBox(height: 18),

                      if (canEdit) ...[
                        FilledButton.icon(
                          onPressed: () async {
                            // dönen veri EditResult türündedir
                            final result = await Navigator.of(context).push<EditResult>(
                              MaterialPageRoute(builder: (_) => LeaveEditPage(initial: r)),
                            );
                            if (result == null) return;
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                            if (result.success) {
                              setState(() {
                                _changed = true;
                                _future = _service.getMyLeaveDetail(widget.leaveRequestId);
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text("Güncelle"),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _cancel(r.leaveRequestId),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("İptal Et"),
                        ),
                      ] else ...[
                        const Text(
                          "Bu talep güncellenemez/iptal edilemez. Sadece bekleyen talepler düzenlenebilir.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                },
              ),
              if (_working)
                Container(
                  color: Colors.black.withOpacity(0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ));
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
