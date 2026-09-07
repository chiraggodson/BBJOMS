
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/api_service.dart';
import 'services/production_service.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  final ApiService _api = ApiService();
  final ProductionService _productionApi = ProductionService();
  final TextEditingController _searchController = TextEditingController();

  List<Machine> _machines = [];
  List<JobOrder> _jobs = [];
  final Map<int, JobDetails> _details = {};
  final Map<int, double> _todayProduction = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getMachines(),
        _api.getJobs(),
      ]);

      final machines = results[0] as List<Machine>;
      final jobs = results[1] as List<JobOrder>;

      final details = <int, JobDetails>{};
      final today = <int, double>{};

      await Future.wait(
        jobs.map((job) async {
          try {
            final detail = await _api.getJobDetails(job.id);
            details[job.id] = detail;

            try {
              final history =
                  await _api.getJobProductionHistory(job.jobNo);
              final now = DateTime.now();

              today[job.id] = history
                  .where((entry) {
                    final date = DateTime.tryParse(entry.createdAt);
                    return date != null &&
                        date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                  })
                  .fold<double>(
                    0,
                    (sum, entry) => sum + entry.quantity,
                  );
            } catch (_) {
              today[job.id] = 0;
            }
          } catch (_) {
            // Keep the register usable even if one job's detail request fails.
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        _machines = machines;
        _jobs = jobs;
        _details
          ..clear()
          ..addAll(details);
        _todayProduction
          ..clear()
          ..addAll(today);
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

  List<_LiveMachineRow> get _rows {
    final query = _searchController.text.trim().toLowerCase();

    final rows = <_LiveMachineRow>[];

    for (final machine in _machines) {
      final assigned = _jobs.where((job) {
        final detail = _details[job.id];
        return detail?.machineIds.contains(machine.id) ?? false;
      }).toList();

      final activeJobs = assigned.where(
        (job) => job.status.toLowerCase() != 'closed',
      ).toList();

      final job = activeJobs.isNotEmpty
          ? activeJobs.first
          : assigned.isNotEmpty
              ? assigned.first
              : null;

      final todayKg = job == null ? 0.0 : (_todayProduction[job.id] ?? 0);
      final totalKg = job?.actualProduction ?? 0.0;
      final targetKg = job?.orderQuantity ?? 0.0;

      final row = _LiveMachineRow(
        machine: machine,
        job: job,
        todayKg: todayKg,
        totalKg: totalKg,
        targetKg: targetKg,
      );

      if (query.isEmpty || row.searchText.contains(query)) {
        rows.add(row);
      }
    }

    return rows;
  }

  double get _todayTotal =>
      _todayProduction.values.fold(0, (sum, value) => sum + value);

  int get _runningMachines => _machines.where(
        (m) => m.status.toLowerCase() == 'running',
      ).length;

  int get _activeJobs => _jobs.where(
        (j) => j.status.toLowerCase() != 'closed',
      ).length;

  Future<void> _openProductionEntry() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductionEntryDialog(
        machines: _machines,
        jobs: _jobs,
        details: _details,
        productionApi: _productionApi,
      ),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return RefreshIndicator(
      onRefresh: _load,
      color: BBTheme.red,
      backgroundColor: BBTheme.panel,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: BBTheme.text,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Live machine status, jobs and production',
                        style: TextStyle(
                          color: BBTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loading ? null : _openProductionEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Production Entry'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _SummaryCard(
                    title: 'Machines',
                    value: _machines.length.toString(),
                    subtitle: 'Active machines',
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                  _SummaryCard(
                    title: 'Running',
                    value: _runningMachines.toString(),
                    subtitle: 'Currently running',
                    icon: Icons.play_circle_outline,
                  ),
                  _SummaryCard(
                    title: 'Today',
                    value: '${_formatNumber(_todayTotal)} kg',
                    subtitle: 'Production recorded today',
                    icon: Icons.today_outlined,
                  ),
                  _SummaryCard(
                    title: 'Active Jobs',
                    value: _activeJobs.toString(),
                    subtitle: 'Open job orders',
                    icon: Icons.assignment_outlined,
                  ),
                ];

                final width = constraints.maxWidth < 760
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: width,
                          child: card,
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            _Panel(
              title: 'LIVE MACHINE PRODUCTION',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'Search machine, job, party, fabric or status...',
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(55),
                      child: CircularProgressIndicator(
                        color: BBTheme.red,
                      ),
                    )
                  else if (_error != null)
                    _ErrorState(
                      message: _error!,
                      onRetry: _load,
                    )
                  else if (rows.isEmpty)
                    const _EmptyState(
                      message: 'No machines or assigned jobs found.',
                    )
                  else
                    _MachineTable(rows: rows),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMachineRow {
  final Machine machine;
  final JobOrder? job;
  final double todayKg;
  final double totalKg;
  final double targetKg;

  const _LiveMachineRow({
    required this.machine,
    required this.job,
    required this.todayKg,
    required this.totalKg,
    required this.targetKg,
  });

  String get searchText => [
        machine.machineNo,
        machine.status,
        job?.jobNo ?? '',
        job?.partyName ?? '',
        job?.fabricName ?? '',
      ].join(' ').toLowerCase();

  double get progress {
    if (targetKg <= 0) return 0;
    return (totalKg / targetKg).clamp(0, 1);
  }
}

class _MachineTable extends StatelessWidget {
  final List<_LiveMachineRow> rows;

  const _MachineTable({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: rows.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BBTheme.black3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BBTheme.borderSoft),
                ),
                child: _MobileMachineRow(row: row),
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: BBTheme.black3,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _Header('MACHINE')),
                  Expanded(flex: 3, child: _Header('JOB / PARTY')),
                  Expanded(flex: 3, child: _Header('FABRIC')),
                  Expanded(flex: 2, child: _Header('STATUS')),
                  Expanded(flex: 2, child: _Header('TODAY')),
                  Expanded(flex: 2, child: _Header('TOTAL / TARGET')),
                ],
              ),
            ),
            ...rows.map(
              (row) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: BBTheme.borderSoft),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          _StatusDot(row.machine.status),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.machine.machineNo.isEmpty
                                      ? '—'
                                      : row.machine.machineNo,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  row.machine.status.isEmpty
                                      ? 'Unknown'
                                      : row.machine.status,
                                  style: const TextStyle(
                                    color: BBTheme.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _JobCell(row.job),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.job?.fabricName.isNotEmpty == true
                            ? row.job!.fabricName
                            : 'No job assigned',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BBTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _StatusPill(row.machine.status),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_formatNumber(row.todayKg)} kg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatNumber(row.totalKg)} / ${_formatNumber(row.targetKg)} kg',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: row.progress,
                              minHeight: 5,
                              backgroundColor: BBTheme.black4,
                              color: BBTheme.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileMachineRow extends StatelessWidget {
  final _LiveMachineRow row;

  const _MobileMachineRow({
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusDot(row.machine.status),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                row.machine.machineNo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _StatusPill(row.machine.status),
          ],
        ),
        const SizedBox(height: 12),
        _InfoLine('Job', row.job?.jobNo ?? 'No job assigned'),
        _InfoLine('Party', row.job?.partyName ?? '—'),
        _InfoLine('Fabric', row.job?.fabricName ?? '—'),
        _InfoLine('Today', '${_formatNumber(row.todayKg)} kg'),
        _InfoLine(
          'Total',
          '${_formatNumber(row.totalKg)} / ${_formatNumber(row.targetKg)} kg',
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: row.progress,
            minHeight: 5,
            backgroundColor: BBTheme.black4,
            color: BBTheme.red,
          ),
        ),
      ],
    );
  }
}

class _JobCell extends StatelessWidget {
  final JobOrder? job;

  const _JobCell(this.job);

  @override
  Widget build(BuildContext context) {
    if (job == null) {
      return const Text(
        'No job assigned',
        style: TextStyle(
          color: BBTheme.subtle,
          fontSize: 11,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job!.jobNo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          job!.partyName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: BBTheme.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ProductionEntryDialog extends StatefulWidget {
  final List<Machine> machines;
  final List<JobOrder> jobs;
  final Map<int, JobDetails> details;
  final ProductionService productionApi;

  const _ProductionEntryDialog({
    required this.machines,
    required this.jobs,
    required this.details,
    required this.productionApi,
  });

  @override
  State<_ProductionEntryDialog> createState() =>
      _ProductionEntryDialogState();
}

class _ProductionEntryDialogState extends State<_ProductionEntryDialog> {
  final Map<int, List<_ProductionRoll>> _jobGroups = {};
  DateTime _productionDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.jobs.isNotEmpty) {
      _addJobGroup(widget.jobs.first);
    }
  }

  @override
  void dispose() {
    for (final rolls in _jobGroups.values) {
      for (final roll in rolls) {
        roll.dispose();
      }
    }
    super.dispose();
  }

  List<JobOrder> get _availableJobs => widget.jobs.where((job) {
        return job.status.trim().toLowerCase() != 'closed';
      }).toList();

  List<Machine> _machinesForJob(JobOrder job) {
    final detail = widget.details[job.id];
    if (detail == null || detail.machineIds.isEmpty) {
      return widget.machines;
    }

    final ids = detail.machineIds.toSet();
    final assigned = widget.machines
        .where((machine) => ids.contains(machine.id))
        .toList();

    return assigned.isEmpty ? widget.machines : assigned;
  }

  void _addJobGroup([JobOrder? job]) {
    final selected = job ?? _availableJobs.firstWhere(
      (candidate) => !_jobGroups.containsKey(candidate.id),
      orElse: () => _availableJobs.first,
    );

    if (_jobGroups.containsKey(selected.id)) {
      _addRoll(selected.id);
      return;
    }

    final machines = _machinesForJob(selected);
    _jobGroups[selected.id] = [
      _ProductionRoll(
        machineId: machines.isEmpty ? null : machines.first.id,
        rollNo: _generateRollNo(),
      ),
    ];
    setState(() {});
  }

  String _generateRollNo() {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}'
        '-${now.millisecond.toString().padLeft(3, '0')}';
    return 'R-$stamp';
  }

  void _removeJobGroup(int jobId) {
    final rolls = _jobGroups.remove(jobId);
    for (final roll in rolls ?? const <_ProductionRoll>[]) {
      roll.dispose();
    }
    setState(() {});
  }

  void _addRoll(int jobId) {
    final rolls = _jobGroups[jobId];
    if (rolls == null) return;

    final job = widget.jobs.firstWhere((item) => item.id == jobId);
    final machines = _machinesForJob(job);

    setState(() {
      rolls.add(
        _ProductionRoll(
          machineId: machines.isEmpty ? null : machines.first.id,
          rollNo: _generateRollNo(),
        ),
      );
    });
  }

  void _removeRoll(int jobId, int index) {
    final rolls = _jobGroups[jobId];
    if (rolls == null || rolls.length <= 1) return;

    final roll = rolls.removeAt(index);
    roll.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (_jobGroups.isEmpty) {
      _showError('Add at least one job.');
      return;
    }

    final entries = <Map<String, dynamic>>[];

    for (final group in _jobGroups.entries) {
      final job = widget.jobs.firstWhere((item) => item.id == group.key);

      for (var index = 0; index < group.value.length; index++) {
        final roll = group.value[index];
        final weight = double.tryParse(roll.weight.text.trim());

        if (roll.machineId == null) {
          _showError('${job.jobNo}: select a machine for Roll ${index + 1}.');
          return;
        }

        if (weight == null || weight <= 0) {
          _showError('${job.jobNo}: enter a valid weight for Roll ${index + 1}.');
          return;
        }

        entries.add({
          'job_id': job.id,
          'machine_id': roll.machineId,
          'production_date': _dateOnly(_productionDate),
          'roll_no': roll.rollNo.text.trim(),
          'quantity_kg': weight,
          'remarks': roll.remarks.text.trim(),
        });
      }
    }

    setState(() => _saving = true);

    try {
      await widget.productionApi.addProductionBatch(entries: entries);

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entries.length} production roll${entries.length == 1 ? '' : 's'} saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BBTheme.redDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BBTheme.panel,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1180,
          maxHeight: 900,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter multiple jobs and multiple rolls in one posting',
                          style: TextStyle(
                            color: BBTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: BBTheme.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            title: 'Production Date',
                            icon: Icons.event_outlined,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(_displayDate(_productionDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_jobGroups.isEmpty)
                      const _EmptyState(
                        message: 'No jobs added. Add a job to begin.',
                      )
                    else
                      ..._jobGroups.entries.map((entry) {
                        final job = widget.jobs.firstWhere(
                          (item) => item.id == entry.key,
                        );
                        return _JobProductionGroup(
                          job: job,
                          rolls: entry.value,
                          machines: _machinesForJob(job),
                          saving: _saving,
                          canRemoveJob: _jobGroups.length > 1,
                          onRemoveJob: () => _removeJobGroup(job.id),
                          onAddRoll: () => _addRoll(job.id),
                          onRemoveRoll: (index) =>
                              _removeRoll(job.id, index),
                        );
                      }),
                    const SizedBox(height: 16),
                    if (_availableJobs.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _chooseJob(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Another Job'),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: BBTheme.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_jobGroups.values.fold<int>(0, (sum, rolls) => sum + rolls.length)} rolls',
                    style: const TextStyle(
                      color: BBTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Posting...' : 'Post Production'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseJob() async {
    final available = _availableJobs
        .where((job) => !_jobGroups.containsKey(job.id))
        .toList();

    if (available.isEmpty) {
      _showError('All available jobs have already been added.');
      return;
    }

    final selected = await showDialog<JobOrder>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BBTheme.panel,
          title: const Text('Add Job'),
          content: SizedBox(
            width: 520,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: available.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: BBTheme.borderSoft),
              itemBuilder: (_, index) {
                final job = available[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    job.jobNo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${job.partyName} • ${job.fabricName}',
                    style: const TextStyle(color: BBTheme.muted),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    color: BBTheme.red,
                  ),
                  onTap: () => Navigator.pop(context, job),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      _addJobGroup(selected);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: BBTheme.red,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _productionDate = selected);
    }
  }
}

class _JobProductionGroup extends StatelessWidget {
  final JobOrder job;
  final List<_ProductionRoll> rolls;
  final List<Machine> machines;
  final bool saving;
  final bool canRemoveJob;
  final VoidCallback onRemoveJob;
  final VoidCallback onAddRoll;
  final ValueChanged<int> onRemoveRoll;

  const _JobProductionGroup({
    required this.job,
    required this.rolls,
    required this.machines,
    required this.saving,
    required this.canRemoveJob,
    required this.onRemoveJob,
    required this.onAddRoll,
    required this.onRemoveRoll,
  });

  @override
  Widget build(BuildContext context) {
    final produced = job.actualProduction;
    final target = job.orderQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BBTheme.black3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BBTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BBTheme.red.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: BBTheme.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobNo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.partyName} • ${job.fabricName} • ${_formatNumber(produced)} / ${_formatNumber(target)} kg',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BBTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (canRemoveJob)
                IconButton(
                  tooltip: 'Remove job',
                  onPressed: saving ? null : onRemoveJob,
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return const SizedBox.shrink();
              }
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: BBTheme.black4,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BBTheme.borderSoft),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 48, child: Text('#', style: TextStyle(color: BBTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 10),
                    SizedBox(width: 180, child: Text('Machine', style: TextStyle(color: BBTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 10),
                    SizedBox(width: 120, child: Text('Roll No.', style: TextStyle(color: BBTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 10),
                    SizedBox(width: 155, child: Text('Weight (kg) *', style: TextStyle(color: BBTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 10),
                    Expanded(child: Text('Remarks', style: TextStyle(color: BBTheme.muted, fontWeight: FontWeight.w900))),
                    SizedBox(width: 50),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ...rolls.asMap().entries.map(
                (entry) => _RollEntryRow(
                  index: entry.key,
                  roll: entry.value,
                  machines: machines,
                  saving: saving,
                  canRemove: rolls.length > 1,
                  onRemove: () => onRemoveRoll(entry.key),
                ),
              ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: saving ? null : onAddRoll,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Roll'),
          ),
        ],
      ),
    );
  }
}

class _RollEntryRow extends StatefulWidget {
  final int index;
  final _ProductionRoll roll;
  final List<Machine> machines;
  final bool saving;
  final bool canRemove;
  final VoidCallback onRemove;

  const _RollEntryRow({
    required this.index,
    required this.roll,
    required this.machines,
    required this.saving,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_RollEntryRow> createState() => _RollEntryRowState();
}

class _RollEntryRowState extends State<_RollEntryRow> {
  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: BBTheme.black2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BBTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BBTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: BBTheme.red, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        final machineField = DropdownButtonFormField<int>(
          value: widget.roll.machineId,
          isExpanded: true,
          decoration: _fieldDecoration(label: 'Machine *'),
          items: widget.machines.map((machine) {
            return DropdownMenuItem<int>(
              value: machine.id,
              child: Text(
                machine.machineNo,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.saving
              ? null
              : (value) => setState(() => widget.roll.machineId = value),
        );

        // The operator sees a simple sequential roll number (1, 2, 3...).
        // The actual long internal reference remains in roll.rollNo and is
        // posted to the backend for ledger traceability.
        final rollField = Container(
          height: 50,
          decoration: BoxDecoration(
            color: BBTheme.black2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: BBTheme.border),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            '${widget.index + 1}',
            style: const TextStyle(
              color: BBTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        final weightField = TextField(
          controller: widget.roll.weight,
          enabled: !widget.saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            label: 'Weight (kg) *',
            hint: 'e.g. 22.36',
          ),
        );

        final remarksField = TextField(
          controller: widget.roll.remarks,
          enabled: !widget.saving,
          maxLines: 1,
          decoration: _fieldDecoration(
            label: 'Remarks',
            hint: 'Optional',
          ),
        );

        final removeButton = widget.canRemove
            ? SizedBox(
                width: 44,
                height: 50,
                child: IconButton(
                  tooltip: 'Remove roll',
                  onPressed: widget.saving ? null : widget.onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: BBTheme.text,
                    size: 19,
                  ),
                ),
              )
            : const SizedBox(width: 44, height: 50);

        if (compact) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BBTheme.panel,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: BBTheme.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BBTheme.red.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: BBTheme.redLight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Production Roll',
                        style: TextStyle(
                          color: BBTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    removeButton,
                  ],
                ),
                const SizedBox(height: 10),
                machineField,
                const SizedBox(height: 10),
                weightField,
                const SizedBox(height: 10),
                remarksField,
              ],
            ),
          );
        }

        // Desktop: fixed, aligned columns. Remarks consumes every remaining
        // pixel so it always reaches the end of the entry panel.
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: BBTheme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 180, child: machineField),
              const SizedBox(width: 10),
              SizedBox(width: 120, child: rollField),
              const SizedBox(width: 10),
              SizedBox(width: 155, child: weightField),
              const SizedBox(width: 10),
              Expanded(child: remarksField),
              const SizedBox(width: 6),
              removeButton,
            ],
          ),
        );
      },
    );
  }
}

class _ProductionRoll {
  int? machineId;
  final TextEditingController rollNo;
  final TextEditingController weight = TextEditingController();
  final TextEditingController remarks = TextEditingController();

  _ProductionRoll({this.machineId, String? rollNo})
      : rollNo = TextEditingController(text: rollNo ?? '');

  void dispose() {
    rollNo.dispose();
    weight.dispose();
    remarks.dispose();
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: BBTheme.panel,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: BBTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BBTheme.red.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: BBTheme.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: BBTheme.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BBTheme.subtle,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BBTheme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BBTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: BBTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
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
        const Icon(
          Icons.circle,
          color: BBTheme.red,
          size: 7,
        ),
        const SizedBox(width: 8),
        Icon(icon, color: BBTheme.red, size: 17),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BBTheme.muted,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: .25),
        ),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: BBTheme.muted,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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
      padding: const EdgeInsets.all(45),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: BBTheme.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load production data',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BBTheme.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(45),
      child: Column(
        children: [
          const Icon(
            Icons.precision_manufacturing_outlined,
            size: 42,
            color: BBTheme.subtle,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: BBTheme.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'running':
      return BBTheme.green;
    case 'idle':
    case 'available':
      return BBTheme.amber;
    case 'maintenance':
      return BBTheme.red;
    case 'stopped':
    case 'paused':
      return BBTheme.redLight;
    default:
      return BBTheme.muted;
  }
}

String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _displayDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}
