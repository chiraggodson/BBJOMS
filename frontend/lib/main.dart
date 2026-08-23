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

// ============================================================
// RESPONSIVE BREAKPOINTS
// ============================================================
//
// < 600       Phone
// 600 - 899   Tablet / iPad
// 900 - 1199  Small desktop
// 1200 - 1599 Desktop
// 1600 - 2399 Large desktop
// 2400+       TV / very large display
//
// ============================================================

class BBJOMSBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
  static const double tv = 2400;
}

class BBJOMSResponsive {
  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isPhone(BuildContext context) {
    return width(context) < BBJOMSBreakpoints.phone;
  }

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= BBJOMSBreakpoints.phone &&
        w < BBJOMSBreakpoints.tablet;
  }

  static bool isSmallDesktop(BuildContext context) {
    final w = width(context);
    return w >= BBJOMSBreakpoints.tablet &&
        w < BBJOMSBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    final w = width(context);
    return w >= BBJOMSBreakpoints.desktop &&
        w < BBJOMSBreakpoints.largeDesktop;
  }

  static bool isLargeDesktop(BuildContext context) {
    final w = width(context);
    return w >= BBJOMSBreakpoints.largeDesktop &&
        w < BBJOMSBreakpoints.tv;
  }

  static bool isTv(BuildContext context) {
    return width(context) >= BBJOMSBreakpoints.tv;
  }

  static bool useMobileNavigation(BuildContext context) {
    return isPhone(context);
  }

  static bool useCompactSidebar(BuildContext context) {
    final w = width(context);

    return w >= BBJOMSBreakpoints.phone &&
        w < BBJOMSBreakpoints.desktop;
  }

  static bool useFullSidebar(BuildContext context) {
    return width(context) >= BBJOMSBreakpoints.desktop;
  }

  static double sidebarWidth(BuildContext context) {
    if (isPhone(context)) {
      return 0;
    }

    if (useCompactSidebar(context)) {
      return 76;
    }

    if (isTv(context)) {
      return 260;
    }

    if (isLargeDesktop(context)) {
      return 245;
    }

    return 235;
  }

  static double contentHorizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 600) {
      return 12;
    }

    if (w < 900) {
      return 16;
    }

    if (w < 1200) {
      return 20;
    }

    if (w < 1600) {
      return 24;
    }

    if (w < 2400) {
      return 32;
    }

    return 48;
  }

  static double topBarHeight(BuildContext context) {
    if (isPhone(context)) {
      return 60;
    }

    if (isTv(context)) {
      return 76;
    }

    return 68;
  }

  static double scale(BuildContext context) {
    final w = width(context);

    if (w < 600) {
      return 0.90;
    }

    if (w < 900) {
      return 0.95;
    }

    if (w < 1200) {
      return 1.0;
    }

    if (w < 1600) {
      return 1.0;
    }

    if (w < 2400) {
      return 1.05;
    }

    return 1.10;
  }
}

// ============================================================
// APP SHELL
// ============================================================

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

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile =
        BBJOMSResponsive.useMobileNavigation(context);

    if (mobile) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildMobileTopBar(),
                    Expanded(
                      child: _buildPage(),
                    ),
                  ],
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
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

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    final bool compact =
        BBJOMSResponsive.useCompactSidebar(context);

    final double sidebarWidth =
        BBJOMSResponsive.sidebarWidth(context);

    return Container(
      width: sidebarWidth,
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
          SizedBox(
            height:
                BBJOMSResponsive.isTv(context) ? 28 : 22,
          ),

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
                  Text(
                    'BBJOMS',
                    style: TextStyle(
                      fontSize:
                          BBJOMSResponsive.isTv(context)
                              ? 21
                              : 20,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final selected =
                    index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 4,
                  ),
                  child: _SidebarItem(
                    item: item,
                    selected: selected,
                    compact: compact,
                    onTap: () {
                      _selectPage(index);
                    },
                  ),
                );
              },
            ),
          ),

          _buildUserPanel(compact),
        ],
      ),
    );
  }

  Widget _buildUserPanel(bool compact) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.all(
        compact ? 8 : 12,
      ),
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
            backgroundColor:
                const Color(0xFF00BFA6),
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
    );
  }

  // ============================================================
  // DESKTOP TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final bool compact =
        BBJOMSResponsive.useCompactSidebar(context);

    final bool smallWidth =
        MediaQuery.sizeOf(context).width < 1100;

    return Container(
      height:
          BBJOMSResponsive.topBarHeight(context),
      padding: EdgeInsets.symmetric(
        horizontal:
            BBJOMSResponsive.contentHorizontalPadding(
          context,
        ),
      ),
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
            style: TextStyle(
              fontSize:
                  BBJOMSResponsive.isTv(context)
                      ? 23
                      : 21,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          if (!smallWidth)
            _buildSearchBox(),

          if (!smallWidth)
            const SizedBox(width: 16),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
            ),
            tooltip: 'Notifications',
          ),

          if (!compact) ...[
            const SizedBox(width: 8),

            Container(
              width: 1,
              height: 28,
              color: const Color(0xFF25313B),
            ),

            const SizedBox(width: 16),

            if (!BBJOMSResponsive.isTablet(context))
              const Text(
                'B&B KnitFab',
                style: TextStyle(
                  color: Color(0xFF9BA7B2),
                  fontSize: 13,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    final double width =
        BBJOMSResponsive.isTv(context)
            ? 300
            : BBJOMSResponsive.isLargeDesktop(context)
                ? 260
                : 220;

    return Container(
      width: width,
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
    );
  }

  // ============================================================
  // MOBILE TOP BAR
  // ============================================================

  Widget _buildMobileTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.factory,
              color: Colors.white,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _navigationItems[_selectedIndex].label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              size: 21,
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF101820),
        border: Border(
          top: BorderSide(
            color: Color(0xFF1D2933),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _MobileNavButton(
              item: _navigationItems[0],
              selected: _selectedIndex == 0,
              onTap: () => _selectPage(0),
            ),

            _MobileNavButton(
              item: _navigationItems[1],
              selected: _selectedIndex == 1,
              onTap: () => _selectPage(1),
            ),

            _MobileNavButton(
              item: _navigationItems[2],
              selected: _selectedIndex == 2,
              onTap: () => _selectPage(2),
            ),

            _MobileNavButton(
              item: _navigationItems[3],
              selected: _selectedIndex == 3,
              onTap: () => _selectPage(3),
            ),

            PopupMenuButton<int>(
              icon: const Icon(
                Icons.more_horiz,
                color: Color(0xFF7C8995),
              ),
              onSelected: _selectPage,
              itemBuilder: (context) {
                return List.generate(
                  _navigationItems.length - 4,
                  (index) {
                    final actualIndex = index + 4;
                    final item =
                        _navigationItems[actualIndex];

                    return PopupMenuItem<int>(
                      value: actualIndex,
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(item.label),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAGE CONTENT
  // ============================================================

  Widget _buildPage() {
    return ClipRect(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              BBJOMSResponsive
                  .contentHorizontalPadding(context),
        ),
        child: _buildSelectedPage(),
      ),
    );
  }

  Widget _buildSelectedPage() {
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

// ============================================================
// SIDEBAR ITEM
// ============================================================

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
                ? const Color(0xFF00BFA6)
                    .withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? item.selectedIcon
                    : item.icon,
                size: 20,
                color: selected
                    ? const Color(0xFF00BFA6)
                    : const Color(0xFF7C8995),
              ),

              if (!compact) ...[
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFE8F2F0)
                          : const Color(0xFF9BA7B2),
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
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

// ============================================================
// MOBILE NAV BUTTON
// ============================================================

class _MobileNavButton extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? item.selectedIcon
                  : item.icon,
              size: 21,
              color: selected
                  ? const Color(0xFF00BFA6)
                  : const Color(0xFF7C8995),
            ),

            const SizedBox(height: 3),

            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: selected
                    ? const Color(0xFF00BFA6)
                    : const Color(0xFF7C8995),
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION MODEL
// ============================================================

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