import 'package:flutter/material.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_MachineJob> _machines = [
    _MachineJob(
      machine: 'M-18',
      floor: 'First Floor',
      jobNo: 'BBJO-00128',
      party: 'Sandhir Textiles',
      fabric: 'Single Jersey 180 GSM',
      status: 'Running',
      todayKg: 86,
      totalProduced: 276,
      targetKg: 420,
      rpm: 24,
      counter: 120,
      rolls: 4,
      operator: 'Ankur',
    ),
    _MachineJob(
      machine: 'M-24',
      floor: 'Second Floor',
      jobNo: 'BBJO-00127',
      party: 'ABC Fabrics',
      fabric: 'Interlock 220 GSM',
      status: 'Running',
      todayKg: 112,
      totalProduced: 510,
      targetKg: 680,
      rpm: 22,
      counter: 110,
      rolls: 5,
      operator: 'Govind',
    ),
    _MachineJob(
      machine: 'M-12',
      floor: 'Second Floor',
      jobNo: 'BBJO-00126',
      party: 'Modern Knits',
      fabric: '2-Way Stretch 180 GSM',
      status: 'Yarn Needed',
      todayKg: 0,
      totalProduced: 0,
      targetKg: 310,
      rpm: 20,
      counter: 100,
      rolls: 0,
      operator: '—',
    ),
    _MachineJob(
      machine: 'M-07',
      floor: 'Ground Floor',
      jobNo: 'BBJO-00125',
      party: 'ST Traders',
      fabric: 'Cotton Lycra 200 GSM',
      status: 'Paused',
      todayKg: 34,
      totalProduced: 190,
      targetKg: 520,
      rpm: 18,
      counter: 100,
      rolls: 2,
      operator: 'Jashan',
    ),
    _MachineJob(
      machine: 'M-21',
      floor: 'Second Floor',
      jobNo: 'BBJO-00124',
      party: 'Fashion Mills',
      fabric: 'Polyester Rib 160 GSM',
      status: 'Stopped',
      todayKg: 0,
      totalProduced: 780,
      targetKg: 780,
      rpm: 0,
      counter: 100,
      rolls: 8,
      operator: '—',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MachineJob> get _filteredMachines {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _machines;

    return _machines.where((machine) {
      return machine.machine.toLowerCase().contains(query) ||
          machine.jobNo.toLowerCase().contains(query) ||
          machine.party.toLowerCase().contains(query) ||
          machine.fabric.toLowerCase().contains(query) ||
          machine.status.toLowerCase().contains(query);
    }).toList();
  }

  void _openProductionEntry() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ProductionEntryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machines = _filteredMachines;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Live machine status, jobs and production entries',
                      style: TextStyle(
                        color: Color(0xFF84919D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openProductionEntry,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Production Entry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _ProductionSummary(),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Machine Production',
            child: Column(
              children: [
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search machine, job, party or fabric...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          ),
                    filled: true,
                    fillColor: const Color(0xFF0F171E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFF25313B),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFF25313B),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFF00BFA6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (machines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 42,
                          color: Color(0xFF53616D),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No machines found',
                          style: TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _MachineProductionList(
                    machines: machines,
                    onEntry: _openProductionEntry,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _ProductionHistoryCard(),
        ],
      ),
    );
  }
}

class _ProductionSummary extends StatelessWidget {
  const _ProductionSummary();

  @override
  Widget build(BuildContext context) {
    const cards = [
      ('Today', '1,284 kg', Icons.trending_up),
      ('Running', '27 / 31', Icons.play_circle_outline),
      ('Rolls Today', '42', Icons.layers_outlined),
      ('Efficiency', '87%', Icons.speed_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((card) {
              return SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _StatCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                ),
              );
            }).toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _StatCard(
                      title: card.$1,
                      value: card.$2,
                      icon: card.$3,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2A34)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00BFA6),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF84919D),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MachineProductionList extends StatelessWidget {
  final List<_MachineJob> machines;
  final VoidCallback onEntry;

  const _MachineProductionList({
    required this.machines,
    required this.onEntry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: machines
                .map(
                  (machine) => _MobileMachineCard(
                    machine: machine,
                    onEntry: onEntry,
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: machines
              .map(
                (machine) => _MachineProductionRow(
                  machine: machine,
                  onEntry: onEntry,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MachineProductionRow extends StatelessWidget {
  final _MachineJob machine;
  final VoidCallback onEntry;

  const _MachineProductionRow({
    required this.machine,
    required this.onEntry,
  });

  @override
  Widget build(BuildContext context) {
    final balance = machine.targetKg - machine.totalProduced;
    final progress = machine.targetKg <= 0
        ? 0.0
        : (machine.totalProduced / machine.targetKg).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1D2933)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.machine,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  machine.floor,
                  style: const TextStyle(
                    color: Color(0xFF687783),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.jobNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  machine.party,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9BA7B2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              machine.fabric,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9BA7B2),
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${machine.totalProduced.toStringAsFixed(0)} / ${machine.targetKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF25313B),
                    color: const Color(0xFF00BFA6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 72,
            child: Text(
              '${machine.todayKg.toStringAsFixed(0)} kg',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 76,
            child: Text(
              '${balance.toStringAsFixed(0)} kg left',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF71808D),
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _MachineStatusChip(status: machine.status),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onEntry,
            tooltip: 'Production entry',
            icon: const Icon(
              Icons.add_circle_outline,
              size: 19,
              color: Color(0xFF00BFA6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMachineCard extends StatelessWidget {
  final _MachineJob machine;
  final VoidCallback onEntry;

  const _MobileMachineCard({
    required this.machine,
    required this.onEntry,
  });

  @override
  Widget build(BuildContext context) {
    final progress = machine.targetKg <= 0
        ? 0.0
        : (machine.totalProduced / machine.targetKg).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2A34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF153A38),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: Color(0xFF00BFA6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.machine,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${machine.floor} • ${machine.jobNo}',
                      style: const TextStyle(
                        color: Color(0xFF71808D),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              _MachineStatusChip(status: machine.status),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              machine.party,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              machine.fabric,
              style: const TextStyle(
                color: Color(0xFF84919D),
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Today',
                  value: '${machine.todayKg.toStringAsFixed(0)} kg',
                ),
              ),
              Expanded(
                child: _MiniValue(
                  label: 'Produced',
                  value: '${machine.totalProduced.toStringAsFixed(0)} kg',
                ),
              ),
              Expanded(
                child: _MiniValue(
                  label: 'Rolls',
                  value: '${machine.rolls}',
                ),
              ),
              Expanded(
                child: _MiniValue(
                  label: 'RPM',
                  value: '${machine.rpm}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF25313B),
                    color: const Color(0xFF00BFA6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF9BA7B2),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onEntry,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Color(0xFF00BFA6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MachineStatusChip extends StatelessWidget {
  final String status;

  const _MachineStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;

    switch (status) {
      case 'Running':
        color = const Color(0xFF2DD4BF);
        break;
      case 'Paused':
        color = const Color(0xFFFBBF24);
        break;
      case 'Yarn Needed':
        color = const Color(0xFFF87171);
        break;
      default:
        color = const Color(0xFF84919D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF687783),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFB7C1C9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProductionHistoryCard extends StatelessWidget {
  const _ProductionHistoryCard();

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('Roll #0042', 'M-24', '112 kg', 'Today 14:20', 'Good'),
      ('Roll #0041', 'M-18', '21 kg', 'Today 13:55', 'Good'),
      ('Roll #0040', 'M-18', '23 kg', 'Today 12:40', 'Good'),
      ('Roll #0039', 'M-07', '18 kg', 'Today 11:35', 'Good'),
      ('Roll #0038', 'M-24', '24 kg', 'Today 10:50', 'Good'),
    ];

    return _DashboardCard(
      title: 'Recent Production',
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1D2933)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Color(0xFF53616D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.$2,
                      style: const TextStyle(
                        color: Color(0xFF9BA7B2),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      entry.$3,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.$4,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF71808D),
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF2DD4BF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.child,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MachineJob {
  final String machine;
  final String floor;
  final String jobNo;
  final String party;
  final String fabric;
  final String status;
  final double todayKg;
  final double totalProduced;
  final double targetKg;
  final int rpm;
  final int counter;
  final int rolls;
  final String operator;

  const _MachineJob({
    required this.machine,
    required this.floor,
    required this.jobNo,
    required this.party,
    required this.fabric,
    required this.status,
    required this.todayKg,
    required this.totalProduced,
    required this.targetKg,
    required this.rpm,
    required this.counter,
    required this.rolls,
    required this.operator,
  });
}

class _ProductionEntryDialog extends StatefulWidget {
  const _ProductionEntryDialog();

  @override
  State<_ProductionEntryDialog> createState() => _ProductionEntryDialogState();
}

class _ProductionEntryDialogState extends State<_ProductionEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  final _rollController = TextEditingController();
  final _grossController = TextEditingController();
  final _tareController = TextEditingController();
  final _wasteController = TextEditingController();
  final _remarksController = TextEditingController();

  String _machine = 'M-18';
  String _job = 'BBJO-00128';
  String _operator = 'Ankur';

  @override
  void dispose() {
    _rollController.dispose();
    _grossController.dispose();
    _tareController.dispose();
    _wasteController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double get _netKg {
    final gross = double.tryParse(_grossController.text) ?? 0;
    final tare = double.tryParse(_tareController.text) ?? 0;
    return (gross - tare).clamp(0, double.infinity);
  }

  double get _usableKg {
    final waste = double.tryParse(_wasteController.text) ?? 0;
    return (_netKg - waste).clamp(0, double.infinity);
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF0F171E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF25313B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF25313B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00BFA6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111A22),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 760,
          maxHeight: 760,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Production Entry',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Record a completed roll from the knitting machine',
                          style: TextStyle(
                            color: Color(0xFF71808D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF25313B)),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        title: 'Machine & Job',
                        icon: Icons.precision_manufacturing_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns = constraints.maxWidth > 560;
                          final width = twoColumns
                              ? (constraints.maxWidth - 14) / 2
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: width,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _machine,
                                  decoration: _decoration('Machine'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'M-07',
                                      child: Text('M-07'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M-12',
                                      child: Text('M-12'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M-18',
                                      child: Text('M-18'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M-21',
                                      child: Text('M-21'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'M-24',
                                      child: Text('M-24'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _machine = value);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _job,
                                  decoration: _decoration('Job Order'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'BBJO-00128',
                                      child: Text('BBJO-00128'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'BBJO-00127',
                                      child: Text('BBJO-00127'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'BBJO-00125',
                                      child: Text('BBJO-00125'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _job = value);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _rollController,
                                  decoration: _decoration(
                                    'Roll Number *',
                                    hint: 'e.g. 43',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Roll number is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _operator,
                                  decoration: _decoration('Operator'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Ankur',
                                      child: Text('Ankur'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Govind',
                                      child: Text('Govind'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Jashan',
                                      child: Text('Jashan'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _operator = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Weight',
                        icon: Icons.scale_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final threeColumns = constraints.maxWidth > 650;
                          final width = threeColumns
                              ? (constraints.maxWidth - 28) / 3
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _grossController,
                                  decoration: _decoration(
                                    'Gross Weight (kg) *',
                                    hint: 'e.g. 24.80',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    final number =
                                        double.tryParse(value ?? '');
                                    if (number == null || number <= 0) {
                                      return 'Enter weight';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _tareController,
                                  decoration: _decoration(
                                    'Tare (kg)',
                                    hint: 'e.g. 0.80',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _wasteController,
                                  decoration: _decoration(
                                    'Waste (kg)',
                                    hint: 'e.g. 0.20',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF153A38),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00BFA6)
                                .withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _WeightResult(
                                label: 'Net Weight',
                                value: '${_netKg.toStringAsFixed(2)} kg',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: const Color(0xFF2B5652),
                            ),
                            Expanded(
                              child: _WeightResult(
                                label: 'Usable Production',
                                value: '${_usableKg.toStringAsFixed(2)} kg',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Remarks',
                        icon: Icons.notes_outlined,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _decoration(
                          'Remarks',
                          hint: 'Quality notes, defects, machine remarks...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFF25313B)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Production entry saved locally: '
                            '${_usableKg.toStringAsFixed(2)} kg on $_machine.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 17),
                    label: const Text('Save Production'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightResult extends StatelessWidget {
  final String label;
  final String value;

  const _WeightResult({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8ECBC3),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF00BFA6),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

