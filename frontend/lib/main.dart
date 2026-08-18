import 'package:flutter/material.dart';

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
      title: 'BBJOMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
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
    _NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Parties',
    ),
    _NavigationItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Yarn',
    ),
    _NavigationItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      label: 'Job Orders',
    ),
    _NavigationItem(
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      label: 'Production',
    ),
    _NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Machines',
    ),
    _NavigationItem(
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers,
      label: 'Fabric',
    ),
    _NavigationItem(
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse,
      label: 'Inventory',
    ),
    _NavigationItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(compact),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool compact) {
    return Container(
      width: compact ? 76 : 235,
      decoration: const BoxDecoration(
        color: Color(0xFF101820),
        border: Border(
          right: BorderSide(
            color: Color(0xFF1D2933),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.factory,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'BBJOMS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final selected = index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarItem(
                    item: item,
                    selected: selected,
                    compact: compact,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF151F28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF00BFA6),
                  child: const Text(
                    'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            color: Color(0xFF84919D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF84919D),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0F171E),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1D2933),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _navigationItems[_selectedIndex].label,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: 220,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF151F28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF25313B),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF71808D),
                ),
                SizedBox(width: 8),
                Text(
                  'Search...',
                  style: TextStyle(
                    color: Color(0xFF71808D),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFF25313B),
          ),
          const SizedBox(width: 16),
          const Text(
            'B&B KnitFab',
            style: TextStyle(
              color: Color(0xFF9BA7B2),
              fontSize: 13,
            ),
          ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00BFA6).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected
                    ? const Color(0xFF00BFA6)
                    : const Color(0xFF7C8995),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFE8F2F0)
                        : const Color(0xFF9BA7B2),
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
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