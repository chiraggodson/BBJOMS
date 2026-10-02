import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/api_service.dart';
import 'services/yarn_receipt_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _api = ApiService();
  final YarnReceiptApi _yarnApi = YarnReceiptApi();

  List<JobOrder> _jobs = [];
  List<Machine> _machines = [];
  List<Map<String, dynamic>> _yarnStock = [];

  final Map<int, double> _todayProduction = {};

  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();

    // Keep the command center live while the app is open.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _api.getJobs(),
        _api.getMachines(),
        _yarnApi.getYarnStock(),
      ]);

      final jobs = results[0] as List<JobOrder>;
      final machines = results[1] as List<Machine>;
      final yarnStock = results[2] as List<Map<String, dynamic>>;

      final today = <int, double>{};

      // Production history is currently exposed job-by-job by the API.
      // Fetch it in parallel so the dashboard remains responsive.
      await Future.wait(
        jobs.map((job) async {
          try {
            final history = await _api.getJobProductionHistory(job.jobNo);
            final now = DateTime.now();

            today[job.id] = history
                .where((entry) {
                  final date = DateTime.tryParse(entry.createdAt);
                  if (date == null) return false;

                  final local = date.toLocal();

                  return local.year == now.year &&
                      local.month == now.month &&
                      local.day == now.day;
                })
                .fold<double>(
                  0,
                  (sum, entry) => sum + entry.quantity,
                );
          } catch (_) {
            today[job.id] = 0;
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _machines = machines;
        _yarnStock = yarnStock;
        _todayProduction
          ..clear()
          ..addAll(today);
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _activeJobs => _jobs.where(
        (job) => job.status.trim().toLowerCase() != 'closed',
      ).length;

  int get _attentionJobs => _jobs.where((job) {
        final status = job.status.trim().toLowerCase();
        return status.contains('yarn') ||
            status.contains('pause') ||
            status.contains('hold') ||
            status.contains('pending');
      }).length;

  int get _runningMachines => _machines.where(
        (machine) => machine.status.trim().toLowerCase() == 'running',
      ).length;

  int get _idleMachines => _machines.where(
        (machine) => machine.status.trim().toLowerCase() == 'idle',
      ).length;

  int get _maintenanceMachines => _machines.where(
        (machine) => machine.status.trim().toLowerCase() == 'maintenance',
      ).length;

  int get _stoppedMachines => _machines.where((machine) {
        final status = machine.status.trim().toLowerCase();
        return status == 'stopped' || status == 'stop';
      }).length;

  int get _totalMachines => _machines.length;

  double get _machineAvailability {
    if (_totalMachines == 0) return 0;
    return _runningMachines / _totalMachines * 100;
  }

  double get _todayTotal =>
      _todayProduction.values.fold<double>(0, (sum, value) => sum + value);

  double get _yarnTotal => _yarnStock.fold<double>(
        0,
        (sum, row) => sum + _stockQuantity(row),
      );

  int get _yarnLots => _yarnStock.where((row) {
        return _stockQuantity(row) > 0;
      }).length;

  List<_DashboardProductionRow> get _productionRows {
    final rows = <_DashboardProductionRow>[];

    for (final job in _jobs) {
      final todayKg = _todayProduction[job.id] ?? 0;

      // Show jobs that have production today plus currently open jobs.
      if (todayKg <= 0 && job.status.toLowerCase() == 'closed') {
        continue;
      }

      rows.add(
        _DashboardProductionRow(
          job: job,
          todayKg: todayKg,
        ),
      );
    }

    rows.sort((a, b) {
      final productionCompare = b.todayKg.compareTo(a.todayKg);
      if (productionCompare != 0) return productionCompare;

      return a.job.jobNo.compareTo(b.job.jobNo);
    });

    return rows.take(6).toList();
  }

  List<_AttentionItem> get _attentionItems {
    final items = <_AttentionItem>[];

    final yarnJobs = _jobs.where((job) {
      final status = job.status.trim().toLowerCase();
      return status.contains('yarn');
    }).toList();

    for (final job in yarnJobs.take(2)) {
      items.add(
        _AttentionItem(
          type: 'YARN',
          text: '${job.jobNo} requires yarn before production can start.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    if (_maintenanceMachines > 0) {
      items.add(
        _AttentionItem(
          type: 'MAINTENANCE',
          text:
              '$_maintenanceMachines machine${_maintenanceMachines == 1 ? '' : 's'} currently under maintenance.',
          icon: Icons.build_outlined,
        ),
      );
    }

    final noProductionToday = _jobs.where((job) {
      final active = job.status.trim().toLowerCase() != 'closed';
      return active && (_todayProduction[job.id] ?? 0) <= 0;
    }).length;

    if (noProductionToday > 0) {
      items.add(
        _AttentionItem(
          type: 'PRODUCTION',
          text:
              '$noProductionToday active job${noProductionToday == 1 ? '' : 's'} have no production recorded today.',
          icon: Icons.trending_down,
        ),
      );
    }

    if (_stoppedMachines > 0) {
      items.add(
        _AttentionItem(
          type: 'MACHINE',
          text:
              '$_stoppedMachines machine${_stoppedMachines == 1 ? '' : 's'} currently stopped.',
          icon: Icons.stop_circle_outlined,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _AttentionItem(
          type: 'STATUS',
          text: 'No operational attention items detected from the live data.',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    return items.take(6).toList();
  }

  double _stockQuantity(Map<String, dynamic> row) {
    const keys = [
      'balance_kg',
      'available_kg',
      'current_balance',
      'balance',
      'quantity_kg',
      'quantity',
      'stock_kg',
    ];

    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();

      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }

    return 0;
  }

  String _formatKg(double value) {
    if (value.abs() >= 1000) {
      return _formatNumber(value);
    }

    return value.toStringAsFixed(0);
  }

  String _formatNumber(double value) {
    final rounded = value.round().toString();
    final chars = rounded.split('');
    var result = '';
    var count = 0;

    for (var i = chars.length - 1; i >= 0; i--) {
      result = chars[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = ',$result';
        count = 0;
      }
    }

    return result;
  }

  String get _lastUpdatedText {
    final value = _lastUpdated;
    if (value == null) return 'UPDATING...';

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return 'UPDATED $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(),
      color: BBTheme.red,
      backgroundColor: BBTheme.panel,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(
              loading: _loading,
              lastUpdated: _lastUpdatedText,
              onRefresh: _loading ? null : () => _load(),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              _ErrorBanner(
                message: _error!,
                onRetry: () => _load(),
              ),
              const SizedBox(height: 14),
            ],
            _Kpis(
              activeJobs: _activeJobs,
              attentionJobs: _attentionJobs,
              todayProduction: _todayTotal,
              yarnStock: _yarnTotal,
              yarnLots: _yarnLots,
              runningMachines: _runningMachines,
              totalMachines: _totalMachines,
              availability: _machineAvailability,
              formatKg: _formatKg,
              formatNumber: _formatNumber,
            ),
            const SizedBox(height: 20),
            _OperationsGrid(
              productionRows: _productionRows,
              runningMachines: _runningMachines,
              idleMachines: _idleMachines,
              maintenanceMachines: _maintenanceMachines,
              stoppedMachines: _stoppedMachines,
              totalMachines: _totalMachines,
              availability: _machineAvailability,
              formatNumber: _formatNumber,
            ),
            const SizedBox(height: 20),
            _Attention(items: _attentionItems),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool loading;
  final String lastUpdated;
  final VoidCallback? onRefresh;

  const _Hero({
    required this.loading,
    required this.lastUpdated,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: BBTheme.panel,
        border: Border.all(color: BBTheme.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 64,
            color: BBTheme.red,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B&B KNITFAB',
                  style: TextStyle(
                    color: BBTheme.redLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'FACTORY COMMAND CENTER',
                  style: TextStyle(
                    color: BBTheme.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Live operational view of jobs, production, machines and material.',
                  style: TextStyle(
                    color: BBTheme.muted,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: BBTheme.black3,
                  border: Border.all(color: BBTheme.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: loading ? BBTheme.amber : BBTheme.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loading ? 'UPDATING' : 'SYSTEM ONLINE',
                      style: TextStyle(
                        color: loading ? BBTheme.amber : BBTheme.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    lastUpdated,
                    style: const TextStyle(
                      color: BBTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    color: BBTheme.muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BBTheme.panel,
        border: Border.all(color: BBTheme.red),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: BBTheme.redLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dashboard could not load live data.\n$message',
              style: const TextStyle(
                color: BBTheme.text,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  final int activeJobs;
  final int attentionJobs;
  final double todayProduction;
  final double yarnStock;
  final int yarnLots;
  final int runningMachines;
  final int totalMachines;
  final double availability;
  final String Function(double) formatKg;
  final String Function(double) formatNumber;

  const _Kpis({
    required this.activeJobs,
    required this.attentionJobs,
    required this.todayProduction,
    required this.yarnStock,
    required this.yarnLots,
    required this.runningMachines,
    required this.totalMachines,
    required this.availability,
    required this.formatKg,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      (
        'ACTIVE JOBS',
        activeJobs.toString(),
        attentionJobs == 0
            ? 'NO ATTENTION FLAGS'
            : '$attentionJobs NEED ATTENTION',
        Icons.assignment_outlined,
        BBTheme.red
      ),
      (
        'PRODUCTION TODAY',
        '${formatKg(todayProduction)} KG',
        'LIVE PRODUCTION RECORDS',
        Icons.trending_up,
        BBTheme.green
      ),
      (
        'YARN STOCK',
        '${formatKg(yarnStock)} KG',
        '$yarnLots LOTS AVAILABLE',
        Icons.inventory_2_outlined,
        BBTheme.red
      ),
      (
        'MACHINES RUNNING',
        '$runningMachines / $totalMachines',
        '${availability.toStringAsFixed(0)}% AVAILABILITY',
        Icons.precision_manufacturing_outlined,
        BBTheme.green
      ),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final n = c.maxWidth < 760 ? 2 : 4;
        final gap = 12.0;
        final w = (c.maxWidth - gap * (n - 1)) / n;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data
              .map(
                (d) => SizedBox(
                  width: w,
                  child: _Kpi(
                    title: d.$1,
                    value: d.$2,
                    sub: d.$3,
                    icon: d.$4,
                    accent: d.$5,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color accent;

  const _Kpi({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: BBTheme.panel,
          border: Border.all(color: BBTheme.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 3,
                  color: accent,
                ),
                const Spacer(),
                Icon(
                  icon,
                  size: 19,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 17),
            Text(
              title,
              style: const TextStyle(
                color: BBTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: BBTheme.text,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              sub,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      );
}

class _OperationsGrid extends StatelessWidget {
  final List<_DashboardProductionRow> productionRows;
  final int runningMachines;
  final int idleMachines;
  final int maintenanceMachines;
  final int stoppedMachines;
  final int totalMachines;
  final double availability;
  final String Function(double) formatNumber;

  const _OperationsGrid({
    required this.productionRows,
    required this.runningMachines,
    required this.idleMachines,
    required this.maintenanceMachines,
    required this.stoppedMachines,
    required this.totalMachines,
    required this.availability,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) {
          if (c.maxWidth < 1000) {
            return Column(
              children: [
                _Production(rows: productionRows),
                const SizedBox(height: 14),
                _Machines(
                  running: runningMachines,
                  idle: idleMachines,
                  maintenance: maintenanceMachines,
                  stopped: stoppedMachines,
                  total: totalMachines,
                  availability: availability,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _Production(rows: productionRows),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _Machines(
                  running: runningMachines,
                  idle: idleMachines,
                  maintenance: maintenanceMachines,
                  stopped: stoppedMachines,
                  total: totalMachines,
                  availability: availability,
                ),
              ),
            ],
          );
        },
      );
}

class _Panel extends StatelessWidget {
  final String title;
  final String action;
  final Widget child;

  const _Panel({
    required this.title,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: BBTheme.panel,
          border: Border.all(color: BBTheme.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: BBTheme.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const Spacer(),
                Text(
                  action,
                  style: const TextStyle(
                    color: BBTheme.redLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      );
}

class _Production extends StatelessWidget {
  final List<_DashboardProductionRow> rows;

  const _Production({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: "TODAY'S PRODUCTION",
      action: 'LIVE',
      child: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No production recorded today.',
                  style: TextStyle(
                    color: BBTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Column(
              children: rows.map((row) => _ProdRow(row)).toList(),
            ),
    );
  }
}

class _ProdRow extends StatelessWidget {
  final _DashboardProductionRow row;

  const _ProdRow(this.row);

  @override
  Widget build(BuildContext context) {
    final job = row.job;
    final target = job.orderQuantity;
    final progress =
        target <= 0 ? 0.0 : (row.todayKg / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BBTheme.borderSoft,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  job.jobNo,
                  style: const TextStyle(
                    color: BBTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.partyName.isEmpty ? 'Unknown Party' : job.partyName,
                      style: const TextStyle(
                        color: BBTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.fabricName.isEmpty ? 'Fabric' : job.fabricName}'
                      '${job.machineNo.isEmpty ? '' : '  •  M${job.machineNo}'}',
                      style: const TextStyle(
                        color: BBTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${row.todayKg.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} KG',
                style: const TextStyle(
                  color: BBTheme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: BBTheme.black4,
              color: progress == 0 ? BBTheme.subtle : BBTheme.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _Machines extends StatelessWidget {
  final int running;
  final int idle;
  final int maintenance;
  final int stopped;
  final int total;
  final double availability;

  const _Machines({
    required this.running,
    required this.idle,
    required this.maintenance,
    required this.stopped,
    required this.total,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'MACHINE STATUS',
        action: 'LIVE',
        child: Column(
          children: [
            _Machine(
              'RUNNING',
              running.toString(),
              BBTheme.green,
              Icons.play_circle_outline,
            ),
            _Machine(
              'IDLE',
              idle.toString(),
              BBTheme.amber,
              Icons.pause_circle_outline,
            ),
            _Machine(
              'MAINTENANCE',
              maintenance.toString(),
              BBTheme.red,
              Icons.build_outlined,
            ),
            _Machine(
              'STOPPED',
              stopped.toString(),
              BBTheme.red,
              Icons.stop_circle_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : running / total,
                      minHeight: 7,
                      backgroundColor: BBTheme.black4,
                      color: BBTheme.red,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${availability.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: BBTheme.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Machine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Machine(
    this.label,
    this.value,
    this.color,
    this.icon,
  );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: BBTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _Attention extends StatelessWidget {
  final List<_AttentionItem> items;

  const _Attention({
    required this.items,
  });

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'MANAGEMENT ATTENTION',
        action: '${items.length} OPEN ITEMS',
        child: LayoutBuilder(
          builder: (_, c) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: c.maxWidth < 700
                          ? c.maxWidth
                          : (c.maxWidth - 10) / 2,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: BBTheme.black2,
                          border: Border.all(
                            color: BBTheme.borderSoft,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0x22E53935),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(
                                item.icon,
                                color: BBTheme.redLight,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.type,
                                    style: const TextStyle(
                                      color: BBTheme.redLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.text,
                                    style: const TextStyle(
                                      color: BBTheme.text,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      );
}

class _DashboardProductionRow {
  final JobOrder job;
  final double todayKg;

  const _DashboardProductionRow({
    required this.job,
    required this.todayKg,
  });
}

class _AttentionItem {
  final String type;
  final String text;
  final IconData icon;

  const _AttentionItem({
    required this.type,
    required this.text,
    required this.icon,
  });
}
