import 'package:flutter/material.dart';
import 'package:izintakip_app/core/utils/date_extensions.dart';
import 'package:izintakip_app/core/utils/leave_days.dart';

import '../../../core/network/api_client.dart';
import '../data/leave_service.dart';
import '../data/models/my_leave_request.dart';
import '../data/models/leave_type.dart';
import 'edit_result.dart';

class LeaveEditPage extends StatefulWidget {
  final MyLeaveRequest initial;
  const LeaveEditPage({super.key, required this.initial});

  @override
  State<LeaveEditPage> createState() => _LeaveEditPageState();
}

class _LeaveEditPageState extends State<LeaveEditPage> {
  final _service = LeaveService();
  final _formKey = GlobalKey<FormState>();

  final _desc = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  late Future<List<LeaveType>> _typesFuture;
  int? _selectedLeaveTypeId;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _start = widget.initial.startDate;
    _end = widget.initial.endDate;
    _desc.text = widget.initial.description ?? '';

    // initial.leaveTypeId null/0 gelebilir
    final initTypeId = widget.initial.leaveTypeId;
    _selectedLeaveTypeId = (initTypeId == null || initTypeId == 0) ? null : initTypeId;

    _typesFuture = _service.getLeaveTypes();
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final start0 = _start ?? todayLocal();
    final end0 = _end ?? start0;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: todayLocal(),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: start0, end: end0),
    );

    if (picked == null) return;

    setState(() {
      _start = picked.start;
      _end = picked.end;
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveTypeId == null) {
      setState(() => _error = "Lütfen izin türü seçin.");
      return;
    }

    if (_start == null || _end == null) {
      setState(() => _error = "Başlangıç ve bitiş tarihini seçmelisiniz.");
      return;
    }

    if (_end!.isBefore(_start!)) {
      setState(() => _error = "Bitiş tarihi başlangıçtan önce olamaz.");
      return;
    }

    final today = todayLocal();
    if (_start!.isBefore(today)) {
      setState(() => _error = "Geçmiş tarihli izin güncellenemez.");
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateMyLeave(
        id: widget.initial.leaveRequestId,
        leaveTypeId: _selectedLeaveTypeId!,
        startDate: _start!,
        endDate: _end!,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(EditResult.success("Güncelleme başarılı"));
    } catch (e) {
      if (!mounted) return;

      if (e is ApiException && e.statusCode == 400 && e.body is Map) {
        final map = e.body as Map;
        final msg = map['message']?.toString() ?? "İşlem başarısız";
        final remaining = map['remainingDays'];
        final requested = map['requestedDays'];

        if (remaining != null && requested != null) {
          setState(() => _error = "$msg (Kalan: $remaining, İstenen: $requested)");
        } else {
          setState(() => _error = msg);
        }
        return;
      }

      setState(() => _error = "Güncelleme başarısız: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusText = (widget.initial.status ?? '').toLowerCase();
    final isPending = !widget.initial.isCancelled && (statusText.contains('bek') || statusText.contains('pending'));
    final canEdit = isPending && !_saving;


    final rangeText = (_start == null || _end == null)
        ? "Seçiniz"
        : "${_start!.toTRDate()} → ${_end!.toTRDate()}";

    final leaveDays = (_start == null || _end == null)
        ? 0
        : countLeaveDaysExcludingSundays(_start!, _end!);

    final hasSunday = (_start == null || _end == null)
        ? false
        : hasSundayBetween(_start!, _end!);

    return Scaffold(
      appBar: AppBar(title: const Text("Talebi Güncelle")),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!isPending) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              "Sadece bekleyen izin talepleri güncellenebilir.",
                              style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        FutureBuilder<List<LeaveType>>(
                          future: _typesFuture,
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (snap.hasError) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("İzin türleri yüklenemedi: ${snap.error}"),
                                  const SizedBox(height: 10),
                                  FilledButton.icon(
                                    onPressed: () => setState(() {
                                      _typesFuture = _service.getLeaveTypes();
                                    }),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Tekrar Dene"),
                                  ),
                                ],
                              );
                            }

                            final types = snap.data ?? const <LeaveType>[];
                            final ids = types.map((e) => e.leaveTypeId).toSet();

                            final effectiveSelectedId =
                            (_selectedLeaveTypeId != null && ids.contains(_selectedLeaveTypeId))
                                ? _selectedLeaveTypeId
                                : (types.isNotEmpty ? types.first.leaveTypeId : null);

                            return DropdownButtonFormField<int>(
                              value: effectiveSelectedId,
                              items: types
                                  .map((t) => DropdownMenuItem<int>(
                                value: t.leaveTypeId,
                                child: Text(t.leaveTypeName),
                              ))
                                  .toList(),
                              onChanged: canEdit ? _saving
                                  ? null
                                  : (v) => setState(() => _selectedLeaveTypeId = v) : null,
                              decoration: const InputDecoration(
                                labelText: "İzin Türü",
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null ? "İzin türü seçin" : null,
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Tarih Aralığı"),
                          subtitle: Text(rangeText, style: TextStyle(color: cs.onSurfaceVariant)),
                          trailing: const Icon(Icons.edit_calendar_outlined),
                          onTap: canEdit ? _saving ? null : _pickRange : null,
                        ),

                        if (_start != null && _end != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("İzin süresi: $leaveDays gün (Pazar hariç)"),
                          ),
                          if (hasSunday) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Not: Pazar günleri izin hesabına dahil edilmez.",
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _desc,
                          enabled: canEdit,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: "Açıklama",
                            prefixIcon: Icon(Icons.notes_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
                          ),
                        ],

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: canEdit ? _saving ? null : _save : null,
                            child: const Text("Kaydet"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.12),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
