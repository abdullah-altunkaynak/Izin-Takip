import 'package:flutter/material.dart';
import '../../core/auth/auth_state.dart';
import '../dashboard/ui/dashboard_page.dart';
import '../leave/ui/my_leaves_page.dart';
import '../leave/ui/inbox_leaves_page.dart';
import '../employee/ui/employees_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isManager = AuthState.isManager == true;

    // normal kullanıcı
    if (!isManager) {
      final pages = <Widget>[
        const DashboardPage(),
        const MyLeavesPage(),
      ];

      return Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              label: "Taleplerim",
            ),
          ],
        ),
      );
    }

    // yönetici kullanıcı
    final pages = <Widget>[
      const DashboardPage(),
      const MyLeavesPage(),
      const InboxLeavesPage(),
      const EmployeesPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: "Taleplerim",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            label: "Onay Kutusu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: "Personeller",
          ),
        ],
      ),
    );
  }
}
