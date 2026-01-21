import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../data/employee_service.dart';
import '../data/models/manager_employee.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _service = EmployeeService();
  late Future<List<ManagerEmployee>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = _service.getMyEmployees();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getMyEmployees());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personeller")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "İsim / e-posta ara",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Haptics.refresh();
                await _refresh();
                await Haptics.light();
              },
              child: FutureBuilder<List<ManagerEmployee>>(
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

                  final items = (snap.data ?? const <ManagerEmployee>[])
                      .where((e) {
                    if (_q.isEmpty) return true;
                    return e.fullName.toLowerCase().contains(_q) ||
                        e.email.toLowerCase().contains(_q);
                  })
                      .toList();

                  if (items.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 30),
                        Icon(Icons.group_outlined, size: 54),
                        SizedBox(height: 12),
                        Center(child: Text("Personel bulunamadı")),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _EmployeeTile(item: items[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final ManagerEmployee item;
  const _EmployeeTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : '?',
          ),
        ),
        title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(item.email),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (item.isDepartmentManager)
              _Chip(text: "Manager", bg: cs.secondaryContainer, fg: cs.onSecondaryContainer),
            _Chip(
              text: item.isActive ? "Aktif" : "Pasif",
              bg: item.isActive ? cs.tertiaryContainer : cs.errorContainer,
              fg: item.isActive ? cs.onTertiaryContainer : cs.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
