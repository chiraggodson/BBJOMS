import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'add_machine_page.dart';

const _bg = Color(0xFF0B1117);
const _panel = Color(0xFF111A22);
const _panel2 = Color(0xFF0F171E);
const _border = Color(0xFF1E2A34);
const _muted = Color(0xFF84919D);
const _teal = Color(0xFF00BFA6);

class _Card extends StatelessWidget {
  final String title;
  final String? action;
  final Widget child;

  const _Card({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
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
                    color: _teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _teal,
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
                  color: _muted,
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

class _Status extends StatelessWidget {
  final String text;

  const _Status(this.text);

  @override
  Widget build(BuildContext context) {
    final normalized = text.trim().toLowerCase();

    Color c = _muted;

    if (normalized == 'running' ||
        normalized == 'open' ||
        normalized == 'available') {
      c = const Color(0xFF2DD4BF);
    } else if (normalized == 'yarn needed' ||
        normalized == 'low stock' ||
        normalized == 'error') {
      c = const Color(0xFFF87171);
    } else if (normalized == 'paused' ||
        normalized == 'pending' ||
        normalized == 'stopped' ||
        normalized == 'idle' ||
        normalized == 'maintenance') {
      c = const Color(0xFFFBBF24);
    } else if (normalized == 'closed' ||
        normalized == 'complete' ||
        normalized == 'completed') {
      c = const Color(0xFFA78BFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.trim().isEmpty ? 'Unknown' : text,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

InputBorder _inputBorder({
  Color color = const Color(0xFF25313B),
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide(color: color),
  );
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

class MachinesPage extends StatefulWidget {
  const MachinesPage({super.key});

  @override
  State<MachinesPage> createState() => _MachinesPageState();
}

class _MachinesPageState extends State<MachinesPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController =
      TextEditingController();

  List<Machine> _machines = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMachines() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final machines = await _apiService.getMachines();

      if (!mounted) return;

      setState(() {
        _machines = machines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Machine> get _filteredMachines {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _machines;
    }

    return _machines.where((machine) {
      return machine.machineNo.toLowerCase().contains(query) ||
          machine.status.toLowerCase().contains(query) ||
          machine.rpm.toString().contains(query) ||
          machine.counter.toString().contains(query) ||
          machine.rollSize.toString().contains(query) ||
          machine.kgPerHour.toString().contains(query);
    }).toList();
  }

  int _statusCount(String status) {
    final target = status.toLowerCase();

    return _machines.where((machine) {
      return machine.status.trim().toLowerCase() == target;
    }).length;
  }

  int get _idleCount {
    return _machines.where((machine) {
      final status = machine.status.trim().toLowerCase();

      return status == 'idle' ||
          status == 'stopped' ||
          status == 'paused';
    }).length;
  }

  void _showMachineDetails(Machine machine) {
    showDialog<void>(
      context: context,
      builder: (_) => _MachineDetails(machine: machine),
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
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machines',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Machine master, status and production information',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMachinePage(),
                          ),
                        );

                        if (result != null && mounted) {
                          await _loadMachines();
                        }
                      },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Machine'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  side: const BorderSide(color: _teal),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loadMachines,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (_, constraints) {
              final stats = [
                _Stat(
                  'Total',
                  _machines.length.toString(),
                  Icons.precision_manufacturing_outlined,
                ),
                _Stat(
                  'Running',
                  _statusCount('running').toString(),
                  Icons.play_circle_outline,
                ),
                _Stat(
                  'Idle',
                  _idleCount.toString(),
                  Icons.pause_circle_outline,
                ),
                _Stat(
                  'Maintenance',
                  _statusCount('maintenance').toString(),
                  Icons.build_outlined,
                ),
              ];

              if (constraints.maxWidth < 760) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: stats
                      .map(
                        (stat) => SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: stat,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < stats.length; i++) ...[
                    Expanded(child: stats[i]),
                    if (i != stats.length - 1)
                      const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Machine Register',
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        'Search machine, status, RPM or roll size...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                            ),
                          ),
                    filled: true,
                    fillColor: _panel2,
                    border: _inputBorder(),
                    enabledBorder: _inputBorder(),
                    focusedBorder: _inputBorder(
                      color: _teal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(
                      color: _teal,
                    ),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _loadMachines,
                  )
                else if (machines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'No machines found.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  _MachineRegister(
                    machines: machines,
                    onOpen: _showMachineDetails,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineRegister extends StatelessWidget {
  final List<Machine> machines;
  final void Function(Machine machine) onOpen;

  const _MachineRegister({
    required this.machines,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: machines.map((machine) {
              return InkWell(
                onTap: () => onOpen(machine),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF1D2933),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFF153A38),
                        child: Icon(
                          Icons.precision_manufacturing_outlined,
                          color: _teal,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              machine.machineNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatNumber(machine.rpm)} RPM • '
                              '${_formatNumber(machine.kgPerHour)} kg/hr',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Status(machine.status),
                      const Icon(
                        Icons.chevron_right,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _panel2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Machine',
                      style: _Header.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: _Header.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'RPM',
                      style: _Header.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Kg / Hour',
                      style: _Header.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '24h Est.',
                      style: _Header.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Roll Size',
                      style: _Header.style,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            ...machines.map(
              (machine) => InkWell(
                onTap: () => onOpen(machine),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF1D2933),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          machine.machineNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Status(machine.status),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatNumber(machine.rpm),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_formatNumber(machine.kgPerHour)} kg',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_formatNumber(machine.kg24h)} kg',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_formatNumber(machine.rollSize)} kg',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onOpen(machine),
                        tooltip: 'Open machine',
                        icon: const Icon(
                          Icons.chevron_right,
                          color: _muted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MachineDetails extends StatelessWidget {
  final Machine machine;

  const _MachineDetails({
    required this.machine,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _panel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 600,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                16,
                18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      machine.machineNo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Status(machine.status),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: _border,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _Detail(
                      'Machine ID',
                      machine.id.toString(),
                    ),
                    _Detail(
                      'Machine No.',
                      machine.machineNo,
                    ),
                    _Detail(
                      'Status',
                      machine.status.isEmpty
                          ? 'Unknown'
                          : machine.status,
                    ),
                    _Detail(
                      'RPM',
                      _formatNumber(machine.rpm),
                    ),
                    _Detail(
                      'Counter',
                      _formatNumber(machine.counter),
                    ),
                    _Detail(
                      'Roll Size',
                      '${_formatNumber(machine.rollSize)} kg',
                    ),
                    _Detail(
                      'Production / Hour',
                      '${_formatNumber(machine.kgPerHour)} kg',
                    ),
                    _Detail(
                      'Estimated / 24h',
                      '${_formatNumber(machine.kg24h)} kg',
                    ),
                    _Detail(
                      'Estimated Rolls / 24h',
                      machine.estimatedRolls24h.toString(),
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
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFFB66A6A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load machines',
            style: TextStyle(
              color: Color(0xFFE0A0A0),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Header {
  static const style = TextStyle(
    color: _muted,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}
