import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'parties_screen.dart';
import 'yarn_screen.dart';
import 'job_orders_screen.dart';
import 'production_screen.dart';
import 'machines_screen.dart';
import 'fabric_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';

void main() {
  runApp(const BBJOMSApp());
}

class BBJOMSApp extends StatelessWidget {
  const BBJOMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBJOMS — B&B KnitFab',
      debugShowCheckedModeBanner: false,
      theme: BBTheme.dark(),
      home: const BBJOMSShell(),
    );
  }
}

class BBJOMSShell extends StatefulWidget {
  const BBJOMSShell({super.key});

  @override
  State<BBJOMSShell> createState() => _BBJOMSShellState();
}

class _BBJOMSShellState extends State<BBJOMSShell> {
  int _selectedIndex = 0;

  final List<_NavigationItem> _navigationItems = const [
    _NavigationItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _NavigationItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Parties'),
    _NavigationItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'Yarn'),
    _NavigationItem(icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: 'Job Orders'),
    _NavigationItem(icon: Icons.precision_manufacturing_outlined, selectedIcon: Icons.precision_manufacturing, label: 'Production'),
    _NavigationItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Machines'),
    _NavigationItem(icon: Icons.layers_outlined, selectedIcon: Icons.layers, label: 'Fabric'),
    _NavigationItem(icon: Icons.warehouse_outlined, selectedIcon: Icons.warehouse, label: 'Inventory'),
    _NavigationItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 600) {
      return Scaffold(
        backgroundColor: BBTheme.canvas,
        appBar: _buildMobileAppBar(),
        drawer: _buildMobileDrawer(),
        body: _buildPage(),
      );
    }

    if (width < 1200) {
      final compact = width < 900;
      return Scaffold(
        backgroundColor: BBTheme.canvas,
        body: SafeArea(
          child: Row(
            children: [
              _buildTabletRail(compact),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(compact: compact),
                    Expanded(child: _buildPage()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BBTheme.canvas,
      body: Row(
        children: [
          _buildSidebar(false),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      titleSpacing: 12,
      backgroundColor: BBTheme.black2,
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.factory, color: BBTheme.red),
          ),
          const SizedBox(width: 10),
          const Text(
            'B&B KnitFab',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }

  Widget _buildTabletRail(bool compact) {
    return Container(
      width: compact ? 76 : 104,
      color: BBTheme.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Image.asset(
              'assets/logo.png',
              width: compact ? 44 : 56,
              height: compact ? 44 : 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.factory, color: BBTheme.redLight, size: 32),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: BBTheme.black3,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final selected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tooltip(
                      message: item.label,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () => setState(() => _selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 54,
                            decoration: BoxDecoration(
                              color: selected ? BBTheme.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: compact
                                ? Center(
                                    child: Icon(
                                      selected ? item.selectedIcon : item.icon,
                                      size: 22,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF9A9A9A),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        selected ? item.selectedIcon : item.icon,
                                        size: 21,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF9A9A9A),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFFB5B5B5),
                                          fontSize: 10,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool compact) {
    return Container(
      width: compact ? 88 : 260,
      color: BBTheme.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
              child: compact
                  ? Image.asset(
                      'assets/logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.factory,
                        color: BBTheme.redLight,
                        size: 32,
                      ),
                    )
                  : Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 58,
                          height: 58,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.factory,
                            color: BBTheme.redLight,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'B&B KnitFab',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ERP SYSTEM',
                                style: TextStyle(
                                  color: Color(0xFFB8B8B8),
                                  fontSize: 10,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: BBTheme.black3,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _SidebarItem(
                      item: item,
                      selected: index == _selectedIndex,
                      compact: compact,
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Container(
                padding: EdgeInsets.all(compact ? 8 : 11),
                decoration: BoxDecoration(
                  color: BBTheme.black2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: BBTheme.black3),
                ),
                child: compact
                    ? const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 21,
                      )
                    : const Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: BBTheme.red,
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Administrator',
                                  style: TextStyle(
                                    color: Color(0xFF929292),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.more_vert,
                            color: Color(0xFF858585),
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: BBTheme.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Image.asset(
              'assets/logo.png',
              width: 82,
              height: 82,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.factory, color: BBTheme.redLight, size: 48),
            ),
            const SizedBox(height: 8),
            const Text(
              'B&B KnitFab',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ERP SYSTEM',
              style: TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _navigationItems.length,
                itemBuilder: (_, index) {
                  final item = _navigationItems[index];
                  final selected = index == _selectedIndex;
                  return ListTile(
                    minVerticalPadding: 8,
                    leading: Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: selected ? BBTheme.redLight : Colors.white60,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: const Color(0x24C62828),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Global application bar.
  //
  // Page titles belong to the individual module screens. Keeping the shell
  // responsible only for global controls prevents duplicated headers such as
  // "Reports" / "Inventory" / "Fabric" appearing twice on every page.
  Widget _buildTopBar({bool compact = false}) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      decoration: const BoxDecoration(
        color: BBTheme.black2,
        border: Border(bottom: BorderSide(color: BBTheme.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (!compact)
            Container(
              width: 250,
              height: 38,
              decoration: BoxDecoration(
                color: BBTheme.black3,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: BBTheme.border),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: BBTheme.subtle),
                  SizedBox(width: 8),
                  Text(
                    'SEARCH...',
                    style: TextStyle(
                      color: BBTheme.subtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none, color: BBTheme.muted),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Container(width: 1, height: 28, color: BBTheme.border),
            const SizedBox(width: 16),
            const Text(
              'B&B KnitFab',
              style: TextStyle(
                color: BBTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const PartiesPage();
      case 2:
        return const YarnPage();
      case 3:
        return const JobOrdersPage();
      case 4:
        return const ProductionPage();
      case 5:
        return const MachinesPage();
      case 6:
        return const FabricPage();
      case 7:
        return const InventoryPage();
      case 8:
        return const ReportsPage();
      default:
        return const DashboardPage();
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: compact ? item.label : '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 50,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? BBTheme.red : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: selected ? null : null,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFF9A9A9A),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFB5B5B5),
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: .15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
