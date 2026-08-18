import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Good afternoon',
            style: TextStyle(
              color: Color(0xFF8B98A5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Factory Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 28),

          // KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width < 750) {
                return const Column(
                  children: [
                    _KpiCard(
                      title: 'Active Jobs',
                      value: '12',
                      subtitle: '3 need attention',
                      icon: Icons.assignment_outlined,
                    ),
                    SizedBox(height: 12),
                    _KpiCard(
                      title: 'Production Today',
                      value: '1,284 kg',
                      subtitle: '+8.4% vs yesterday',
                      icon: Icons.trending_up,
                    ),
                    SizedBox(height: 12),
                    _KpiCard(
                      title: 'Yarn Stock',
                      value: '8,462 kg',
                      subtitle: '24 lots available',
                      icon: Icons.inventory_2_outlined,
                    ),
                    SizedBox(height: 12),
                    _KpiCard(
                      title: 'Machines Running',
                      value: '27 / 31',
                      subtitle: '87% utilisation',
                      icon: Icons.precision_manufacturing_outlined,
                    ),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Active Jobs',
                      value: '12',
                      subtitle: '3 need attention',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _KpiCard(
                      title: 'Production Today',
                      value: '1,284 kg',
                      subtitle: '+8.4% vs yesterday',
                      icon: Icons.trending_up,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _KpiCard(
                      title: 'Yarn Stock',
                      value: '8,462 kg',
                      subtitle: '24 lots available',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _KpiCard(
                      title: 'Machines Running',
                      value: '27 / 31',
                      subtitle: '87% utilisation',
                      icon: Icons.precision_manufacturing_outlined,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Main content
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1000) {
                return const Column(
                  children: [
                    _RecentJobsCard(),
                    SizedBox(height: 20),
                    _MachineStatusCard(),
                  ],
                );
              }

              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _RecentJobsCard(),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _MachineStatusCard(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Quick actions
          const _QuickActionsCard(),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E2A34),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF00BFA6),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF84919D),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF687783),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: const Color(0xFF53616D),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RecentJobsCard extends StatelessWidget {
  const _RecentJobsCard();

  @override
  Widget build(BuildContext context) {
    const jobs = [
      ('BBJO-00128', 'Sandhir Textiles', 'Running', '420 kg'),
      ('BBJO-00127', 'ABC Fabrics', 'Running', '680 kg'),
      ('BBJO-00126', 'Modern Knits', 'Yarn Needed', '310 kg'),
      ('BBJO-00125', 'ST Traders', 'Paused', '520 kg'),
      ('BBJO-00124', 'Fashion Mills', 'Closed', '780 kg'),
    ];

    return _DashboardCard(
      title: 'Recent Job Orders',
      action: 'View all',
      child: Column(
        children: [
          const SizedBox(height: 10),
          for (int i = 0; i < jobs.length; i++) ...[
            _JobRow(
              jobNo: jobs[i].$1,
              party: jobs[i].$2,
              status: jobs[i].$3,
              quantity: jobs[i].$4,
            ),
            if (i != jobs.length - 1)
              const Divider(
                height: 1,
                color: Color(0xFF1D2933),
              ),
          ],
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final String jobNo;
  final String party;
  final String status;
  final String quantity;

  const _JobRow({
    required this.jobNo,
    required this.party,
    required this.status,
    required this.quantity,
  });

  Color _statusColor() {
    switch (status) {
      case 'Running':
        return const Color(0xFF2DD4BF);
      case 'Yarn Needed':
        return const Color(0xFFF87171);
      case 'Paused':
        return const Color(0xFFFBBF24);
      case 'Closed':
        return const Color(0xFFA78BFA);
      default:
        return const Color(0xFF84919D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              jobNo,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              party,
              style: const TextStyle(
                color: Color(0xFFB7C1C9),
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 65,
            child: Text(
              quantity,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF9BA7B2),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineStatusCard extends StatelessWidget {
  const _MachineStatusCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Machine Status',
      action: 'View machines',
      child: Column(
        children: [
          const SizedBox(height: 14),
          _MachineStatusRow(
            label: 'Running',
            value: '27',
            icon: Icons.play_circle_outline,
          ),
          _MachineStatusRow(
            label: 'Idle',
            value: '2',
            icon: Icons.pause_circle_outline,
          ),
          _MachineStatusRow(
            label: 'Maintenance',
            value: '1',
            icon: Icons.build_outlined,
          ),
          _MachineStatusRow(
            label: 'Stopped',
            value: '1',
            icon: Icons.stop_circle_outlined,
          ),
          const SizedBox(height: 15),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF25313B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 27 / 31,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisation',
                style: TextStyle(
                  color: Color(0xFF71808D),
                  fontSize: 11,
                ),
              ),
              Text(
                '87%',
                style: TextStyle(
                  color: Color(0xFFB7C1C9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MachineStatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MachineStatusRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6F7D88),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9BA7B2),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Quick Actions',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _QuickAction(
            icon: Icons.add_task,
            label: 'New Job Order',
          ),
          _QuickAction(
            icon: Icons.local_shipping_outlined,
            label: 'Receive Yarn',
          ),
          _QuickAction(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Production Entry',
          ),
          _QuickAction(
            icon: Icons.inventory_outlined,
            label: 'Check Inventory',
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151F28),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF25313B),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add,
            size: 16,
            color: Color(0xFF00BFA6),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? action;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E2A34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    color: Color(0xFF00BFA6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
