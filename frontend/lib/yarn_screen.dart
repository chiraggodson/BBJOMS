import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/api_service.dart';
import 'services/yarn_receipt_service.dart';

class YarnPage extends StatefulWidget {
  const YarnPage({super.key});

  @override
  State<YarnPage> createState() => _YarnPageState();
}

class _YarnPageState extends State<YarnPage> {
  final ApiService _api = ApiService();
  final YarnReceiptApi _yarnApi = YarnReceiptApi();
  final TextEditingController _searchController = TextEditingController();

  List<YarnMaster> _yarns = [];
  List<Map<String, dynamic>> _stock = [];
  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;
  bool _inventoryLoading = true;
  String? _error;
  String? _inventoryError;

  @override
  void initState() {
    super.initState();
    _loadYarns();
    _loadInventoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadYarns() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final yarns = await _api.getYarns();

      if (!mounted) return;

      setState(() {
        _yarns = yarns;
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


  Future<void> _loadInventoryData() async {
    if (mounted) {
      setState(() {
        _inventoryLoading = true;
        _inventoryError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _yarnApi.getYarnStock(),
        _yarnApi.getYarnMovements(limit: 50),
      ]);

      if (!mounted) return;

      setState(() {
        _stock = results[0] as List<Map<String, dynamic>>;
        _movements = results[1] as List<Map<String, dynamic>>;
        _inventoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _inventoryLoading = false;
        _inventoryError = e.toString();
      });
    }
  }

  Future<void> _openYarnIssue() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _YarnIssueDialog(
        api: _api,
        yarnApi: _yarnApi,
      ),
    );

    if (saved == true && mounted) {
      await _loadInventoryData();
    }
  }

  Future<void> _openAllMovements() async {
    try {
      final movements = await _yarnApi.getYarnMovements(limit: 200);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => _YarnMovementDialog(movements: movements),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  double get _totalStock => _stock.fold<double>(
        0,
        (sum, row) => sum + (double.tryParse('${row['balance'] ?? 0}') ?? 0),
      );

  int get _activeLots => _stock.where((row) {
        return (double.tryParse('${row['balance'] ?? 0}') ?? 0) > 0;
      }).length;

  int get _todayMovements {
    final today = DateTime.now();
    final prefix =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _movements.where((row) {
      return '${row['movement_date'] ?? ''}'.startsWith(prefix);
    }).length;
  }

  List<YarnMaster> get _filteredYarns {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _yarns;
    }

    return _yarns.where((yarn) {
      return yarn.code.toLowerCase().contains(query) ||
          yarn.name.toLowerCase().contains(query) ||
          yarn.count.toLowerCase().contains(query) ||
          yarn.composition.toLowerCase().contains(query);
    }).toList();
  }

  String _nextYarnCode() {
    var highestNumber = 0;

    for (final yarn in _yarns) {
      final match = RegExp(r'(\d+)$').firstMatch(yarn.code.trim());

      if (match != null) {
        final number = int.tryParse(match.group(1)!);

        if (number != null && number > highestNumber) {
          highestNumber = number;
        }
      }
    }

    return 'YRN-${(highestNumber + 1).toString().padLeft(4, '0')}';
  }


  Future<void> _openYarnForm({YarnMaster? yarn}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _YarnFormDialog(
          api: _api,
          yarn: yarn,
          generatedCode: yarn?.code ?? _nextYarnCode(),
        );
      },
    );

    if (saved == true && mounted) {
      await _loadYarns();
    }
  }

  Future<void> _openColorMaster() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ColorMasterDialog(api: _api),
    );
  }

  Future<void> _deactivateYarn(YarnMaster yarn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deactivate Yarn'),
          content: Text(
            'Deactivate "${yarn.name}" (${yarn.code})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deactivateYarn(yarn.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yarn deactivated'),
        ),
      );

      await _loadYarns();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final yarns = _filteredYarns;

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
                      'Yarn',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Generic yarn specifications, stock and movement ledger',
                      style: TextStyle(
                        color: Color(0xFF84919D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading || _inventoryLoading
                    ? null
                    : () {
                        _loadYarns();
                        _loadInventoryData();
                      },
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openColorMaster(),
                icon: const Icon(Icons.palette_outlined, size: 18),
                label: const Text('Colors'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openYarnIssue(),
                icon: const Icon(Icons.north_east, size: 18),
                label: const Text('Issue Yarn'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openYarnForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Yarn'),
                style: FilledButton.styleFrom(
                  backgroundColor: BBTheme.red,
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
          _LiveYarnSummary(
            masterCount: _yarns.length,
            totalStock: _totalStock,
            activeLots: _activeLots,
            todayMovements: _todayMovements,
            loading: _inventoryLoading,
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Yarn Master',
            child: Column(
              children: [
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        'Search yarn number, name, count or composition...',
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
                    fillColor: BBTheme.black3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide:
                          const BorderSide(color: Color(0xFF25313B)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide:
                          const BorderSide(color: Color(0xFF25313B)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide:
                          const BorderSide(color: Color(0xFFB4232C)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(45),
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _loadYarns,
                  )
                else if (yarns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(45),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 42, color: Color(0xFF53616D)),
                        SizedBox(height: 12),
                        Text('No yarn found',
                            style: TextStyle(
                                color: Color(0xFF9BA7B2), fontSize: 14)),
                      ],
                    ),
                  )
                else
                  _YarnTable(
                    yarns: yarns,
                    onEdit: (yarn) => _openYarnForm(yarn: yarn),
                    onDeactivate: _deactivateYarn,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Recent Yarn Movements',
            child: _inventoryLoading
                ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _inventoryError != null
                    ? _ErrorState(
                        message: _inventoryError!,
                        onRetry: _loadInventoryData,
                      )
                    : _YarnMovementList(
                        movements: _movements.take(12).toList(),
                        onViewAll: _openAllMovements,
                      ),
          ),
        ],
      ),
    );
  }
}


class _LiveYarnSummary extends StatelessWidget {
  final int masterCount;
  final double totalStock;
  final int activeLots;
  final int todayMovements;
  final bool loading;

  const _LiveYarnSummary({
    required this.masterCount,
    required this.totalStock,
    required this.activeLots,
    required this.todayMovements,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Active Yarn Masters', '$masterCount', Icons.all_inclusive),
      ('Total Stock', loading ? '—' : '${totalStock.toStringAsFixed(2)} kg', Icons.inventory_2_outlined),
      ('Active Lots', loading ? '—' : '$activeLots', Icons.layers_outlined),
      ('Today\'s Movements', loading ? '—' : '$todayMovements', Icons.swap_vert),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = cards
            .map((card) => _YarnStatCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                ))
            .toList();

        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map((child) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: child,
                    ))
                .toList(),
          );
        }

        return Row(
          children: children
              .map((child) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: child,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _YarnMovementList extends StatelessWidget {
  final List<Map<String, dynamic>> movements;
  final VoidCallback onViewAll;

  const _YarnMovementList({
    required this.movements,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: const [
            Icon(Icons.swap_vert, size: 36, color: Color(0xFF53616D)),
            SizedBox(height: 10),
            Text('No yarn movements recorded yet',
                style: TextStyle(color: Color(0xFF71808D))),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...movements.map((m) => _YarnMovementRowLive(movement: m)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onViewAll,
            icon: const Icon(Icons.list_alt, size: 17),
            label: const Text('View all movements'),
          ),
        ),
      ],
    );
  }
}

class _YarnMovementRowLive extends StatelessWidget {
  final Map<String, dynamic> movement;

  const _YarnMovementRowLive({required this.movement});

  @override
  Widget build(BuildContext context) {
    final type = '${movement['movement_type'] ?? ''}'.toUpperCase();
    final inQty = double.tryParse('${movement['quantity_in'] ?? 0}') ?? 0;
    final outQty = double.tryParse('${movement['quantity_out'] ?? 0}') ?? 0;
    final isIn = inQty > 0 && outQty <= 0;
    final isReturn = type.contains('RETURN');
    final icon = isReturn
        ? Icons.keyboard_return
        : isIn
            ? Icons.south_west
            : Icons.north_east;
    final title = type.isEmpty ? 'Yarn Movement' : type.replaceAll('_', ' ');
    final job = '${movement['job_no'] ?? ''}'.trim();
    final yarn = '${movement['yarn_name'] ?? ''}'.trim();
    final owner = '${movement['owner_name'] ?? ''}'.trim();
    final lot = '${movement['lot_no'] ?? ''}'.trim();
    final location = '${movement['location_name'] ?? ''}'.trim();
    final qty = isIn ? inQty : outQty;
    final timestamp = '${movement['created_at'] ?? movement['createdAt'] ?? movement['movement_date'] ?? ''}';
    final date = _formatMovementDateTime(timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1D2933))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isIn || isReturn
                ? const Color(0x1835A66F)
                : const Color(0x18B4232C),
            child: Icon(
              icon,
              size: 17,
              color: isIn || isReturn
                  ? BBTheme.green
                  : BBTheme.redLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (yarn.isNotEmpty) yarn,
                    if (owner.isNotEmpty) owner,
                    if (lot.isNotEmpty) 'Lot $lot',
                    if (job.isNotEmpty) job,
                    if (location.isNotEmpty) location,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF71808D), fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}${qty.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isIn || isReturn
                      ? BBTheme.green
                      : BBTheme.redLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(date,
                  style: const TextStyle(
                      color: Color(0xFF71808D), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _YarnMovementDialog extends StatefulWidget {
  final List<Map<String, dynamic>> movements;

  const _YarnMovementDialog({required this.movements});

  @override
  State<_YarnMovementDialog> createState() => _YarnMovementDialogState();
}

class _YarnMovementDialogState extends State<_YarnMovementDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _haystack(Map<String, dynamic> m) {
    return [
      m['movement_type'],
      m['yarn_name'],
      m['yarn_code'],
      m['lot_no'],
      m['supplier_lot_no'],
      m['job_no'],
      m['location_name'],
      m['owner_name'],
      m['remarks'],
    ].join(' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final rows = widget.movements.where((m) => q.isEmpty || _haystack(m).contains(q)).toList();

    return Dialog(
      backgroundColor: BBTheme.panel,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
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
                        Text('Yarn Movement Ledger',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Receipts, issues, returns and all stock movements',
                            style: TextStyle(color: Color(0xFFA9ADB3), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF353A40)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search yarn, lot, job, location, owner or movement...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: BBTheme.black,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No movements found'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => _YarnMovementRowLive(movement: rows[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMovementDateTime(String raw) {
  if (raw.trim().isEmpty) return '—';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.length > 19 ? raw.substring(0, 19) : raw;
  }

  final hour24 = parsed.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/'
      '${parsed.year} • '
      '${hour12.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')} $period';
}


class _YarnIssueLine {
  String? stockKey;
  final TextEditingController quantity = TextEditingController();
  final TextEditingController remarks = TextEditingController();

  void dispose() {
    quantity.dispose();
    remarks.dispose();
  }
}

class _YarnIssueJobGroup {
  final JobOrder job;
  Set<String> requiredYarnIds = <String>{};
  final List<_YarnIssueLine> lines = [];

  _YarnIssueJobGroup({required this.job}) {
    lines.add(_YarnIssueLine());
  }

  void dispose() {
    for (final line in lines) {
      line.dispose();
    }
  }
}

class _YarnIssueDialog extends StatefulWidget {
  final ApiService api;
  final YarnReceiptApi yarnApi;

  const _YarnIssueDialog({
    required this.api,
    required this.yarnApi,
  });

  @override
  State<_YarnIssueDialog> createState() => _YarnIssueDialogState();
}

class _YarnIssueDialogState extends State<_YarnIssueDialog> {
  final TextEditingController _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  List<JobOrder> _jobs = [];
  List<Map<String, dynamic>> _stock = [];
  final List<_YarnIssueJobGroup> _groups = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _date.dispose();
    for (final group in _groups) {
      group.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        widget.api.getJobs(),
        widget.yarnApi.getYarnStock(),
      ]);

      final jobs = (results[0] as List<JobOrder>)
          .where((j) => j.status.toLowerCase() != 'closed')
          .toList();
      final stock = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _stock = stock;
        _loading = false;
      });

      if (jobs.isNotEmpty) {
        await _addJob(jobs.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<Set<String>> _requiredYarns(JobOrder job) async {
    try {
      final details = await widget.api.getJobDetails(job.id);
      return details.yarns
          .map((y) => y.yarnId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _addJob(JobOrder job) async {
    if (_groups.any((g) => g.job.id == job.id)) return;

    final group = _YarnIssueJobGroup(job: job);
    setState(() => _groups.add(group));

    final required = await _requiredYarns(job);
    if (!mounted) return;

    setState(() => group.requiredYarnIds = required);
  }

  Future<void> _chooseAnotherJob() async {
    final available = _jobs
        .where((job) => !_groups.any((g) => g.job.id == job.id))
        .toList();
    if (available.isEmpty) {
      _showError('All available jobs have already been added.');
      return;
    }
    final selected = await showDialog<List<JobOrder>>(
      context: context,
      builder: (context) => _JobPickerDialog(jobs: available),
    );
    if (selected != null && mounted) {
      for (final job in selected) {
        await _addJob(job);
      }
    }
  }

  void _addLine(_YarnIssueJobGroup group) {
    setState(() => group.lines.add(_YarnIssueLine()));
  }

  void _removeLine(_YarnIssueJobGroup group, int index) {
    if (group.lines.length == 1) return;
    final line = group.lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  void _removeJob(int index) {
    if (_groups.length == 1) {
      _showError('At least one job is required.');
      return;
    }
    final group = _groups.removeAt(index);
    group.dispose();
    setState(() {});
  }

  List<Map<String, dynamic>> _stockFor(_YarnIssueJobGroup group) {
    if (group.requiredYarnIds.isEmpty) return _stock;
    return _stock
        .where((row) => group.requiredYarnIds.contains('${row['yarn_id'] ?? ''}'))
        .toList();
  }

  String _stockKey(Map<String, dynamic> row) {
    return '${row['yarn_lot_id'] ?? ''}|${row['location_id'] ?? ''}';
  }

  Map<String, dynamic>? _findStock(String? key) {
    if (key == null) return null;
    for (final row in _stock) {
      if (_stockKey(row) == key) return row;
    }
    return null;
  }

  double _qty(String value) => double.tryParse(value.trim()) ?? 0;

  Future<void> _save() async {
    if (_groups.isEmpty) {
      _showError('Add at least one job.');
      return;
    }

    if (_date.text.trim().isEmpty) {
      _showError('Enter issue date.');
      return;
    }

    final entries = <Map<String, dynamic>>[];

    for (var gi = 0; gi < _groups.length; gi++) {
      final group = _groups[gi];

      if (group.lines.isEmpty) {
        _showError('Add at least one yarn line for ${group.job.jobNo}.');
        return;
      }

      for (var li = 0; li < group.lines.length; li++) {
        final line = group.lines[li];
        final stock = _findStock(line.stockKey);

        if (stock == null) {
          _showError('Select yarn stock on ${group.job.jobNo}, line ${li + 1}.');
          return;
        }

        final qty = _qty(line.quantity.text);
        if (qty <= 0) {
          _showError('Enter a quantity greater than zero on ${group.job.jobNo}, line ${li + 1}.');
          return;
        }

        final balance = double.tryParse('${stock['balance'] ?? 0}') ?? 0;
        if (qty > balance + 0.000001) {
          _showError(
            'Insufficient stock for ${stock['yarn_name'] ?? 'yarn'} / ${stock['lot_no'] ?? ''}. Available ${balance.toStringAsFixed(2)} kg.',
          );
          return;
        }

        entries.add({
          'job_id': group.job.id,
          'yarn_lot_id': stock['yarn_lot_id'],
          'location_id': stock['location_id'],
          'quantity': qty,
          'remarks': line.remarks.text.trim(),
        });
      }
    }

    setState(() => _saving = true);

    try {
      await widget.yarnApi.issueYarnBatch(
        issueDate: _date.text.trim(),
        entries: entries,
      );

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yarn issued successfully. ${entries.length} line(s) posted.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: BBTheme.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF353A40)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF353A40)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB4232C)),
      ),
    );
  }

  String _jobSubtitle(JobOrder job) {
    final parts = <String>[];
    if (job.partyName.trim().isNotEmpty) parts.add(job.partyName);
    if (job.fabricName.trim().isNotEmpty) parts.add(job.fabricName);
    parts.add('${job.actualProduction.toStringAsFixed(2)} / ${job.orderQuantity.toStringAsFixed(0)} kg');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final totalLines = _groups.fold<int>(0, (sum, group) => sum + group.lines.length);

    return Dialog(
      backgroundColor: BBTheme.panel,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 850),
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
                        Text('Yarn Issue',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Issue multiple yarns to multiple jobs in one posting',
                            style: TextStyle(color: Color(0xFFA9ADB3), fontSize: 11)),
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
            const Divider(height: 1, color: Color(0xFF353A40)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month, color: Color(0xFFD13A43), size: 20),
                                    SizedBox(width: 10),
                                    Text('Issue Date', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: _date,
                                  decoration: _decoration('Date'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ..._groups.asMap().entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _YarnIssueJobCard(
                                  group: entry.value,
                                  index: entry.key,
                                  stock: _stockFor(entry.value),
                                  allStock: _stock,
                                  saving: _saving,
                                  decoration: _decoration,
                                  stockKey: _stockKey,
                                  onAddLine: () => _addLine(entry.value),
                                  onRemoveLine: (i) => _removeLine(entry.value, i),
                                  onRemoveJob: () => _removeJob(entry.key),
                                  onChanged: () => setState(() {}),
                                ),
                              )),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _chooseAnotherJob,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Jobs'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const Divider(height: 1, color: Color(0xFF353A40)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Text('$totalLines lines • ${_groups.length} jobs',
                      style: const TextStyle(color: Color(0xFFA9ADB3), fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Posting...' : 'Post Yarn Issue'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BBTheme.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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

class _YarnIssueJobCard extends StatelessWidget {
  final _YarnIssueJobGroup group;
  final int index;
  final List<Map<String, dynamic>> stock;
  final List<Map<String, dynamic>> allStock;
  final bool saving;
  final InputDecoration Function(String, {String? hint}) decoration;
  final String Function(Map<String, dynamic>) stockKey;
  final VoidCallback onAddLine;
  final ValueChanged<int> onRemoveLine;
  final VoidCallback onRemoveJob;
  final VoidCallback onChanged;

  const _YarnIssueJobCard({
    required this.group,
    required this.index,
    required this.stock,
    required this.allStock,
    required this.saving,
    required this.decoration,
    required this.stockKey,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onRemoveJob,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BBTheme.black2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BBTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x18B4232C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFFD13A43), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.job.jobNo,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (group.job.partyName.trim().isNotEmpty) group.job.partyName,
                        if (group.job.fabricName.trim().isNotEmpty) group.job.fabricName,
                        '${group.job.actualProduction.toStringAsFixed(2)} / ${group.job.orderQuantity.toStringAsFixed(0)} kg',
                      ].join(' • '),
                      style: const TextStyle(color: Color(0xFFA9ADB3), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: saving ? null : onRemoveJob,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Remove Job'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: group.lines
                      .asMap()
                      .entries
                      .map((entry) => _mobileLine(entry.key, entry.value))
                      .toList(),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: BBTheme.black4,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 36, child: Text('#', style: _IssueHeaderStyle.style)),
                        SizedBox(width: 370, child: Text('Yarn / Lot / Balance', style: _IssueHeaderStyle.style)),
                        SizedBox(width: 150, child: Text('Issue Qty (kg) *', style: _IssueHeaderStyle.style)),
                        Expanded(child: Text('Remarks', style: _IssueHeaderStyle.style)),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...group.lines.asMap().entries.map((entry) => _desktopLine(entry.key, entry.value)),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: saving ? null : onAddLine,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add Yarn'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopLine(int index, _YarnIssueLine line) {
    final current = allStock.where((row) => stockKey(row) == line.stockKey).toList();
    final items = [...stock, ...current.where((row) => !stock.contains(row))];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 56,
            child: Center(
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            width: 370,
            child: DropdownButtonFormField<String>(
              initialValue: items.any((r) => stockKey(r) == line.stockKey) ? line.stockKey : null,
              isExpanded: true,
              decoration: decoration('Select yarn stock'),
              items: items.map((row) {
                final balance = double.tryParse('${row['balance'] ?? 0}') ?? 0;
                final yarn = '${row['yarn_name'] ?? ''}';
                final count = '${row['yarn_count'] ?? ''}';
                final color = '${row['color_name'] ?? ''}';
                final lot = '${row['lot_no'] ?? ''}';
                final location = '${row['location_name'] ?? ''}';
                final owner = '${row['owner_name'] ?? ''}';
                return DropdownMenuItem<String>(
                  value: stockKey(row),
                  child: SizedBox(
                    width: 345,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            yarn,
                            if (count.trim().isNotEmpty) count,
                            if (color.trim().isNotEmpty) color,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 13, color: BBTheme.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                owner.trim().isEmpty ? 'Owner not specified' : owner,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: BBTheme.redLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lot $lot',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${balance.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                color: BBTheme.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (location.trim().isNotEmpty)
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BBTheme.muted,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: saving
                  ? null
                  : (value) {
                      line.stockKey = value;
                      onChanged();
                    },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: TextField(
              controller: line.quantity,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: decoration('Issue Qty (kg) *'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: line.remarks,
              enabled: !saving,
              decoration: decoration('Remarks'),
            ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              onPressed: saving || group.lines.length == 1 ? null : () => onRemoveLine(index),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove line',
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLine(int index, _YarnIssueLine line) {
    final current = allStock.where((row) => stockKey(row) == line.stockKey).toList();
    final items = [...stock, ...current.where((row) => !stock.contains(row))];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BBTheme.black3,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: BBTheme.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: saving || group.lines.length == 1 ? null : () => onRemoveLine(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: items.any((r) => stockKey(r) == line.stockKey) ? line.stockKey : null,
            isExpanded: true,
            decoration: decoration('Select yarn stock'),
            items: items.map((row) {
              final balance = double.tryParse('${row['balance'] ?? 0}') ?? 0;
              return DropdownMenuItem<String>(
                value: stockKey(row),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['yarn_name'] ?? ''} • ${row['yarn_count'] ?? ''} • ${row['color_name'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Owner: ${row['owner_name'] ?? 'Not specified'} • Lot ${row['lot_no'] ?? ''} • ${balance.toStringAsFixed(2)} kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BBTheme.redLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: saving
                ? null
                : (value) {
                    line.stockKey = value;
                    onChanged();
                  },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.quantity,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: decoration('Issue Qty (kg) *'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.remarks,
                  enabled: !saving,
                  decoration: decoration('Remarks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueHeaderStyle {
  static const style = TextStyle(
    color: Color(0xFFA9ADB3),
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

class _JobPickerDialog extends StatefulWidget {
  final List<JobOrder> jobs;
  const _JobPickerDialog({required this.jobs});
  @override
  State<_JobPickerDialog> createState() => _JobPickerDialogState();
}

class _JobPickerDialogState extends State<_JobPickerDialog> {
  final TextEditingController _search = TextEditingController();
  final Set<int> _selectedIds = <int>{};

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final jobs = widget.jobs.where((job) =>
      q.isEmpty || job.jobNo.toLowerCase().contains(q) ||
      job.partyName.toLowerCase().contains(q) ||
      job.fabricName.toLowerCase().contains(q)).toList();

    return AlertDialog(
      title: Row(children: [
        const Expanded(child: Text('Add Jobs to Yarn Issue')),
        Text('${_selectedIds.length} selected', style: const TextStyle(color: BBTheme.muted, fontSize: 12)),
      ]),
      content: SizedBox(
        width: 680,
        height: 520,
        child: Column(children: [
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(
            hintText: 'Search job, party or fabric...', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 10),
          Row(children: [
            TextButton(onPressed: jobs.isEmpty ? null : () => setState(() => _selectedIds.addAll(jobs.map((j) => j.id))), child: const Text('Select visible')),
            TextButton(onPressed: _selectedIds.isEmpty ? null : () => setState(_selectedIds.clear), child: const Text('Clear')),
          ]),
          Expanded(child: jobs.isEmpty
            ? const Center(child: Text('No jobs found'))
            : ListView.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final job = jobs[index];
                  return CheckboxListTile(
                    value: _selectedIds.contains(job.id),
                    onChanged: (value) => setState(() => value == true ? _selectedIds.add(job.id) : _selectedIds.remove(job.id)),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: const Icon(Icons.description_outlined),
                    title: Text(job.jobNo, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      if (job.partyName.isNotEmpty) job.partyName,
                      if (job.fabricName.isNotEmpty) job.fabricName,
                      '${job.actualProduction.toStringAsFixed(2)} / ${job.orderQuantity.toStringAsFixed(0)} kg',
                    ].join(' • ')),
                  );
                },
              )),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _selectedIds.isEmpty ? null : () {
            Navigator.pop(context, widget.jobs.where((job) => _selectedIds.contains(job.id)).toList());
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add ${_selectedIds.length} Job${_selectedIds.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}

class _YarnSummary extends StatelessWidget {
  final int count;

  const _YarnSummary({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Active Yarn Masters',
        '$count',
        Icons.all_inclusive,
      ),
      (
        'Total Stock',
        '—',
        Icons.inventory_2_outlined,
      ),
      (
        'Active Lots',
        '—',
        Icons.layers_outlined,
      ),
      (
        'Today\'s Movements',
        '—',
        Icons.swap_vert,
      ),
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
                child: _YarnStatCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                ),
              );
            }).toList(),
          );
        }

        return Row(
          children: cards.map((card) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                ),
                child: _YarnStatCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _YarnStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _YarnStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BBTheme.black2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BBTheme.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BBTheme.red.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: BBTheme.red,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }
}

class _YarnTable extends StatelessWidget {
  final List<YarnMaster> yarns;
  final ValueChanged<YarnMaster> onEdit;
  final ValueChanged<YarnMaster> onDeactivate;

  const _YarnTable({
    required this.yarns,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: yarns.map((yarn) {
              return Container(
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
                      radius: 18,
                      backgroundColor: Color(0xFF153A38),
                      child: Icon(
                        Icons.all_inclusive,
                        color: Color(0xFF00BFA6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            yarn.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${yarn.code} • ${yarn.count.isEmpty ? 'No count' : yarn.count}',
                            style: const TextStyle(
                              color: Color(0xFF71808D),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            yarn.composition.isEmpty ? 'Composition not specified' : yarn.composition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5F6D78),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(yarn);
                        } else if (value == 'deactivate') {
                          onDeactivate(yarn);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Deactivate'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: BBTheme.black3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Yarn No.',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Yarn',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Count',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Composition',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            ...yarns.map(
              (yarn) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
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
                          yarn.code.isEmpty ? '—' : yarn.code,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          yarn.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          yarn.count.isEmpty
                              ? '—'
                              : yarn.count,
                          style: const TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          yarn.composition.isEmpty
                              ? '—'
                              : yarn.composition,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit(yarn);
                          } else if (value ==
                              'deactivate') {
                            onDeactivate(yarn);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _YarnFormDialog extends StatefulWidget {
  final ApiService api;
  final YarnMaster? yarn;
  final String generatedCode;
  const _YarnFormDialog({
    required this.api,
    required this.yarn,
    required this.generatedCode,
  });

  @override
  State<_YarnFormDialog> createState() => _YarnFormDialogState();
}

class _YarnFormDialogState extends State<_YarnFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _compositionController;
  late final TextEditingController _descriptionController;

  bool _saving = false;

  bool get _editing => widget.yarn != null;

  @override
  void initState() {
    super.initState();

    final yarn = widget.yarn;

    _nameController = TextEditingController(
      text: yarn?.name ?? '',
    );
    _countController = TextEditingController(
      text: yarn?.count ?? '',
    );
    _compositionController = TextEditingController(
      text: yarn?.composition ?? '',
    );
    _descriptionController = TextEditingController(
      text: yarn?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _compositionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: BBTheme.black3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF25313B),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF25313B),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF00BFA6),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }


    setState(() {
      _saving = true;
    });

    try {
      final code = widget.generatedCode.trim();
      final name = _nameController.text.trim();
      final count = _countController.text.trim();
      final composition =
          _compositionController.text.trim();
      final description =
          _descriptionController.text.trim();

      if (_editing) {
        await widget.api.updateYarn(
          id: widget.yarn!.id,
          code: code,
          name: name,
          count: count.isEmpty ? null : count,
          yarnTypeId: widget.yarn!.yarnTypeId,
          composition:
              composition.isEmpty ? null : composition,
          unitId: widget.yarn!.unitId,
          description:
              description.isEmpty ? null : description,
        );
      } else {
        await widget.api.createYarn(
          code: code,
          name: name,
          count: count.isEmpty ? null : count,
          yarnTypeId: null,
          composition:
              composition.isEmpty ? null : composition,
          unitId: null,
          description:
              description.isEmpty ? null : description,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BBTheme.black2,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 650,
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
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editing
                              ? 'Edit Yarn'
                              : 'Add Yarn',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _editing
                              ? 'Update yarn master details'
                              : 'Create a new yarn master',
                          style: const TextStyle(
                            color: Color(0xFF71808D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFF25313B),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns =
                          constraints.maxWidth > 560;

                      final width = twoColumns
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth;

                      Widget field(Widget child) {
                        return SizedBox(
                          width: width,
                          child: child,
                        );
                      }

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          field(
                            TextFormField(
                              initialValue:
                                  widget.generatedCode,
                              readOnly: true,
                              decoration:
                                  _decoration('Yarn No.').copyWith(
                                suffixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          field(
                            TextFormField(
                              controller: _nameController,
                              decoration: _decoration(
                                'Yarn Name',
                                hint:
                                    'e.g. Polyester 75D',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Yarn name is required';
                                }

                                return null;
                              },
                            ),
                          ),
                          field(
                            TextFormField(
                              controller: _countController,
                              decoration: _decoration(
                                'Count',
                                hint: 'e.g. 75D / 30s',
                              ),
                            ),
                          ),
                          field(
                            TextFormField(
                              controller:
                                  _compositionController,
                              decoration: _decoration(
                                'Composition',
                                hint:
                                    'e.g. 100% Polyester',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: TextFormField(
                              controller:
                                  _descriptionController,
                              maxLines: 3,
                              decoration:
                                  _decoration('Description'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFF25313B),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          BBTheme.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _editing
                                ? 'Save Changes'
                                : 'Add Yarn',
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
      padding: const EdgeInsets.all(35),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFF71808D),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load Yarn Master',
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71808D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh,
              size: 17,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


class _ColorMasterDialog extends StatefulWidget {
  final ApiService api;
  const _ColorMasterDialog({required this.api});
  @override
  State<_ColorMasterDialog> createState() => _ColorMasterDialogState();
}

class _ColorMasterDialogState extends State<_ColorMasterDialog> {
  List<ColorMaster> _colors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final colors = await widget.api.getColors();
      if (!mounted) return;
      setState(() { _colors = colors; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _edit({ColorMaster? color}) async {
    final name = TextEditingController(text: color?.name ?? '');
    final description = TextEditingController(text: color?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(color == null ? 'Add Color' : 'Edit Color'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Color Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Color name is required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              if (color == null) {
                await widget.api.createColor(name: name.text.trim(), description: description.text.trim().isEmpty ? null : description.text.trim());
              } else {
                await widget.api.updateColor(id: color.id, name: name.text.trim(), description: description.text.trim().isEmpty ? null : description.text.trim());
              }
              if (context.mounted) Navigator.pop(context, true);
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }, child: const Text('Save')),
        ],
      ),
    );
    name.dispose(); description.dispose();
    if (saved == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Color Master'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(children: [
                    Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Color'))),
                    const SizedBox(height: 12),
                    Expanded(child: _colors.isEmpty ? const Center(child: Text('No colors found')) : ListView.separated(
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) { final c = _colors[i]; return ListTile(title: Text(c.name), subtitle: Text(c.code), trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(color: c))); },
                    )),
                  ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
        color: BBTheme.black2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BBTheme.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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

class _TableHeaderStyle {
  static const style = TextStyle(
    color: Color(0xFF71808D),
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}
