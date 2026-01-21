import 'package:flutter/material.dart';
import 'package:izintakip_app/core/utils/date_extensions.dart';
import 'package:izintakip_app/core/utils/leave_days.dart';
import '../../../core/network/api_client.dart';
import '../data/leave_service.dart';
import '../data/models/leave_type.dart';

class LeaveCreatePage extends StatefulWidget {
  const LeaveCreatePage({super.key});

  @override
  State<LeaveCreatePage> createState() => _LeaveCreatePageState();
}

class _LeaveCreatePageState extends State<LeaveCreatePage> {
  final _service = LeaveService();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  late Future<List<LeaveType>> _typesFuture;
  LeaveType? _selectedType;

  DateTimeRange? _range;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _typesFuture = _service.getLeaveTypes();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: todayLocal(),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 1),
          ),
    );
    if (picked == null) return;

    setState(() => _range = picked);
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      setState(() => _error = "Lütfen izin türü seçin.");
      return;
    }
    if (_range == null) {
      setState(() => _error = "Lütfen tarih aralığı seçin.");
      return;
    }
    if (_range?.start == null || _range?.end == null) {
      setState(() => _error = "Başlangıç ve bitiş tarihini seçmelisiniz.");
      return;
    }
    if (_range!.end.isBefore(_range!.start)) {
      setState(() => _error = "Bitiş tarihi başlangıçtan önce olamaz.");
      return;
    }
    final today = todayLocal();

    if (_range!.start.isBefore(today)) {
    setState(() => _error = "Geçmiş tarih için izin talebi oluşturulamaz.");
    return;
    }

    setState(() => _saving = true);
    try {
      await _service.createLeave(
        leaveTypeId: _selectedType!.leaveTypeId,
        startDate: _range!.start,
        endDate: _range!.end,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Talep oluşturuldu")),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 400 && e.body is Map) {
        final map = e.body as Map;
        final msg = map['message']?.toString() ?? "İşlem başarısız";
        final remaining = map['remainingDays'];
        final requested = map['requestedDays'];
        setState(() => _error = "$msg (Kalan: $remaining, İstenen: $requested)");
        return;
      }
      setState(() => _error = "Hata: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;

    final rangeText = _range == null
        ? "Tarih seçin"
        : "${_range!.start.toTRDate()} → ${_range!.end.toTRDate()}";
    final leaveDays = (_range != null && _range != null)
        ? countLeaveDaysExcludingSundays(_range!.start, _range!.end)
        : 0;
    final hasSunday = (_range != null && _range != null)
        ? hasSundayBetween(_range!.start, _range!.end)
        : false;



    return Scaffold(
      appBar: AppBar(title: const Text("Yeni İzin Talebi")),
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
                            return DropdownButtonFormField<LeaveType>(
                              value: _selectedType,
                              items: types
                                  .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.leaveTypeName),
                              ))
                                  .toList(),
                              onChanged: _saving ? null : (v) => setState(() => _selectedType = v),
                              decoration: const InputDecoration(
                                labelText: "İzin Türü",
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (_) => _selectedType == null ? "İzin türü seçin" : null,
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Tarih Aralığı"),
                          subtitle: Text(rangeText, style: TextStyle(color: cs.onSurfaceVariant)),
                          trailing: const Icon(Icons.date_range_outlined),
                          onTap: _saving ? null : _pickRange,
                        ),

                        if (_range != null && _range != null) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: Text("İzin süresi: $leaveDays gün"),
                            avatar: const Icon(Icons.timelapse),
                          ),
                        ],

                        if (hasSunday) ...[
                          const SizedBox(height: 6),
                          Text("Not: Pazar günleri izin hesabına dahil edilmez.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _descCtrl,
                          enabled: !_saving,
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
                            child: Text(
                              _error!,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: const Icon(Icons.send_outlined),
                            label: const Text("Talep Oluştur"),
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


