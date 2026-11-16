import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets/app_widgets.dart';
import 'services/api_service.dart';
import 'services/dispatch_service.dart';

class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final _dispatchApi = DispatchService();
  final _api = ApiService();
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _unreconciledRolls = [];
  List<Map<String, dynamic>> _dispatches = [];
  List<Party> _parties = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _dispatchApi.getLots(),
        _dispatchApi.getUnreconciledRolls(),
        _dispatchApi.getDispatches(),
        _api.getParties(active: true),
      ]);
      if (!mounted) return;
      setState(() {
        _lots = values[0] as List<Map<String, dynamic>>;
        _unreconciledRolls = values[1] as List<Map<String, dynamic>>;
        _dispatches = values[2] as List<Map<String, dynamic>>;
        _parties = values[3] as List<Party>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _kg(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _formatKg(dynamic value) => '${_kg(value).toStringAsFixed(3)} kg';

  Future<void> _split(Map<String, dynamic> lot) async {
    final result = await showDialog<_SplitValues>(
      context: context,
      builder: (_) => _SplitLotDialog(
        quantityKg: _kg(lot['quantity_kg']),
        lotNo: '${lot['lot_no']}',
      ),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      await _dispatchApi.splitLot(
        lotId: '${lot['id']}',
        childQuantitiesKg: [result.firstKg, result.secondKg],
        cuttingLossKg: result.lossKg,
      );
      await _load();
      if (mounted) {
        setState(() => _saving = false);
      }
      if (mounted) {
        _message('Lot split recorded. The new lots are ready for dispatch.');
      }
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _newDispatch() async {
    final result = await showDialog<_DispatchDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _CreateDispatchDialog(lots: _lots, parties: _parties, kg: _kg),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      await _dispatchApi.createDispatch(
        partyId: result.partyId,
        lotIds: result.lotIds,
        challanDate:
            '${result.date.year.toString().padLeft(4, '0')}-${result.date.month.toString().padLeft(2, '0')}-${result.date.day.toString().padLeft(2, '0')}',
        transporter: result.transporter,
        vehicleNo: result.vehicleNo,
        notes: result.notes,
      );
      await _load();
      if (mounted) {
        setState(() => _saving = false);
        _message('Dispatch challan posted.');
      }
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reconcileExistingStock() async {
    final selectedRollIds = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReconcileStockDialog(rolls: _unreconciledRolls, kg: _kg),
    );
    if (selectedRollIds == null || selectedRollIds.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _dispatchApi.reconcileOpeningStock(rollIds: selectedRollIds);
      await _load();
      if (mounted) {
        setState(() => _saving = false);
        _message('Confirmed rolls are now available in Dispatch.');
      }
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
        setState(() => _saving = false);
      }
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? BBTheme.redDark : BBTheme.black4,
      ),
    );
  }

  Future<void> _viewDispatch(Map<String, dynamic> row) async {
    try {
      final details = await _dispatchApi.getDispatch('${row['id']}');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _DispatchDetailsDialog(details: details, kg: _kg),
      );
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _lots
        .where((lot) => lot['status'] == 'AVAILABLE')
        .toList();
    final availableKg = available.fold<double>(
      0,
      (sum, lot) => sum + _kg(lot['quantity_kg']),
    );
    final dispatchedKg = _dispatches.fold<double>(
      0,
      (sum, row) => sum + _kg(row['quantity_kg']),
    );
    return RefreshIndicator(
      onRefresh: _load,
      color: BBTheme.red,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          BBPageHeader(
            title: 'Dispatch',
            subtitle:
                'Split finished rolls into traceable lots and post delivery challans',
            actions: [
              IconButton(
                onPressed: _loading || _saving ? null : _load,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
              ),
              if (_unreconciledRolls.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _loading || _saving
                      ? null
                      : _reconcileExistingStock,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text('Reconcile stock (${_unreconciledRolls.length})'),
                ),
              FilledButton.icon(
                onPressed: _loading || _saving || available.isEmpty
                    ? null
                    : _newDispatch,
                icon: const Icon(Icons.add),
                label: const Text('New challan'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                label: 'Available lots',
                value: '${available.length}',
                icon: Icons.inventory_2_outlined,
              ),
              _MetricCard(
                label: 'Available fabric',
                value: _formatKg(availableKg),
                icon: Icons.scale_outlined,
              ),
              _MetricCard(
                label: 'Challans posted',
                value: '${_dispatches.length}',
                icon: Icons.local_shipping_outlined,
              ),
              _MetricCard(
                label: 'Recent dispatched',
                value: _formatKg(dispatchedKg),
                icon: Icons.outbox_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Available lots'),
                icon: Icon(Icons.inventory_2_outlined),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Challans'),
                icon: Icon(Icons.receipt_long_outlined),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (selection) =>
                setState(() => _tab = selection.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _InfoBox(text: _error!, isError: true),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tab == 0)
            _buildLots(available)
          else
            _buildDispatches(),
        ],
      ),
    );
  }

  Widget _buildLots(List<Map<String, dynamic>> lots) {
    if (lots.isEmpty) {
      return const _InfoBox(
        text:
            'No dispatchable fabric lots yet. Newly posted production rolls appear automatically. Review existing production rolls above to add only fabric that is physically on hand.',
      );
    }
    return Column(
      children: lots
          .map(
            (lot) => Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 9, color: BBTheme.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lot['lot_no']}  ·  ${lot['roll_no'] ?? 'Roll'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lot['party_name']}  ·  ${lot['job_no']}  ·  ${lot['fabric_name'] ?? ''}',
                            style: const TextStyle(
                              color: BBTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatKg(lot['quantity_kg']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _split(lot),
                      icon: const Icon(Icons.content_cut, size: 17),
                      label: const Text('Split into lots'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDispatches() {
    if (_dispatches.isEmpty) {
      return const _InfoBox(text: 'No dispatch challans have been posted yet.');
    }
    return Column(
      children: _dispatches
          .map(
            (row) => Card(
              child: InkWell(
                onTap: () => _viewDispatch(row),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: BBTheme.redLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['dispatch_no']}  ·  ${row['party_name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${row['challan_date']}  ·  Jobs ${row['job_numbers'] ?? '—'}  ·  ${row['lot_count']} lots',
                              style: const TextStyle(
                                color: BBTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatKg(row['quantity_kg']),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReconcileStockDialog extends StatefulWidget {
  final List<Map<String, dynamic>> rolls;
  final double Function(dynamic) kg;

  const _ReconcileStockDialog({required this.rolls, required this.kg});

  @override
  State<_ReconcileStockDialog> createState() => _ReconcileStockDialogState();
}

class _ReconcileStockDialogState extends State<_ReconcileStockDialog> {
  final Set<String> _selected = {};
  bool _confirmedOnHand = false;

  @override
  Widget build(BuildContext context) {
    final selectedRolls = widget.rolls
        .where((roll) => _selected.contains('${roll['id']}'))
        .toList();
    final selectedKg = selectedRolls.fold<double>(
      0,
      (sum, roll) => sum + widget.kg(roll['quantity_kg']),
    );
    return AlertDialog(
      title: const Text('Reconcile existing production rolls'),
      content: SizedBox(
        width: 680,
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select only rolls that are physically still in stock. Selected rolls become dispatchable; all other production stays unchanged.',
              style: TextStyle(color: BBTheme.muted),
            ),
            const SizedBox(height: 12),
            Text(
              '${_selected.length} selected · ${selectedKg.toStringAsFixed(3)} kg',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: widget.rolls.length,
                itemBuilder: (context, index) {
                  final roll = widget.rolls[index];
                  final id = '${roll['id']}';
                  return CheckboxListTile(
                    value: _selected.contains(id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(id);
                      } else {
                        _selected.remove(id);
                      }
                    }),
                    title: Text(
                      '${roll['roll_no']}  ·  ${widget.kg(roll['quantity_kg']).toStringAsFixed(3)} kg',
                    ),
                    subtitle: Text(
                      '${roll['job_no']}  ·  ${roll['party_name']}  ·  ${roll['fabric_name'] ?? ''}  ·  ${roll['production_date']}',
                    ),
                    dense: true,
                  );
                },
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmedOnHand,
              onChanged: (value) =>
                  setState(() => _confirmedOnHand = value == true),
              title: const Text(
                'I confirmed the selected rolls are physically on hand.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selected.isNotEmpty && _confirmedOnHand
              ? () => Navigator.pop(context, _selected.toList())
              : null,
          icon: const Icon(Icons.check),
          label: const Text('Add selected stock'),
        ),
      ],
    );
  }
}

class _SplitValues {
  final double firstKg;
  final double secondKg;
  final double lossKg;
  const _SplitValues(this.firstKg, this.secondKg, this.lossKg);
}

class _SplitLotDialog extends StatefulWidget {
  final double quantityKg;
  final String lotNo;
  const _SplitLotDialog({required this.quantityKg, required this.lotNo});
  @override
  State<_SplitLotDialog> createState() => _SplitLotDialogState();
}

class _SplitLotDialogState extends State<_SplitLotDialog> {
  late final TextEditingController _first;
  final _loss = TextEditingController(text: '0');
  @override
  void initState() {
    super.initState();
    _first = TextEditingController(
      text: (widget.quantityKg / 2).toStringAsFixed(3),
    );
    _first.addListener(_refresh);
    _loss.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _first.dispose();
    _loss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = double.tryParse(_first.text) ?? 0;
    final loss = double.tryParse(_loss.text) ?? 0;
    final second = widget.quantityKg - first - loss;
    return AlertDialog(
      title: Text('Split ${widget.lotNo}'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original lot: ${widget.quantityKg.toStringAsFixed(3)} kg',
              style: const TextStyle(color: BBTheme.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _first,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'New lot quantity (kg)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loss,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cutting loss (kg)',
                helperText: 'Enter 0 when all fabric is accounted for.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Remainder lot: ${second.toStringAsFixed(3)} kg',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (second <= 0)
              const Text(
                'Both lots must have a positive quantity.',
                style: TextStyle(color: BBTheme.redLight),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: first > 0 && second > 0 && loss >= 0
              ? () => Navigator.pop(context, _SplitValues(first, second, loss))
              : null,
          child: const Text('Record split'),
        ),
      ],
    );
  }
}

class _DispatchDraft {
  final String partyId;
  final List<String> lotIds;
  final DateTime date;
  final String transporter;
  final String vehicleNo;
  final String notes;
  const _DispatchDraft(
    this.partyId,
    this.lotIds,
    this.date,
    this.transporter,
    this.vehicleNo,
    this.notes,
  );
}

class _CreateDispatchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> lots;
  final List<Party> parties;
  final double Function(dynamic) kg;
  const _CreateDispatchDialog({
    required this.lots,
    required this.parties,
    required this.kg,
  });
  @override
  State<_CreateDispatchDialog> createState() => _CreateDispatchDialogState();
}

class _CreateDispatchDialogState extends State<_CreateDispatchDialog> {
  String? _partyId;
  final Set<String> _selected = {};
  DateTime _date = DateTime.now();
  final _transporter = TextEditingController();
  final _vehicle = TextEditingController();
  final _notes = TextEditingController();
  @override
  void dispose() {
    _transporter.dispose();
    _vehicle.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partyLots = widget.lots
        .where(
          (lot) =>
              lot['status'] == 'AVAILABLE' && '${lot['party_id']}' == _partyId,
        )
        .toList();
    final totalKg = partyLots
        .where((lot) => _selected.contains('${lot['id']}'))
        .fold<double>(0, (sum, lot) => sum + widget.kg(lot['quantity_kg']));
    return AlertDialog(
      title: const Text('New dispatch challan'),
      content: SizedBox(
        width: 640,
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _partyId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Party'),
              items: widget.parties
                  .where(
                    (party) => widget.lots.any(
                      (lot) =>
                          '${lot['party_id']}' == party.id &&
                          lot['status'] == 'AVAILABLE',
                    ),
                  )
                  .map(
                    (party) => DropdownMenuItem(
                      value: party.id,
                      child: Text(party.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _partyId = value;
                _selected.clear();
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select whole rolls or lots (${totalKg.toStringAsFixed(3)} kg)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _date = date);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  ),
                ),
              ],
            ),
            Expanded(
              child: partyLots.isEmpty
                  ? const Center(
                      child: Text(
                        'Choose a party with available lots.',
                        style: TextStyle(color: BBTheme.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: partyLots.length,
                      itemBuilder: (context, index) {
                        final lot = partyLots[index];
                        final id = '${lot['id']}';
                        return CheckboxListTile(
                          value: _selected.contains(id),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          }),
                          title: Text(
                            '${lot['lot_no']}  ·  ${lot['roll_no'] ?? 'Roll'}',
                          ),
                          subtitle: Text(
                            '${lot['job_no']}  ·  ${lot['fabric_name'] ?? ''}  ·  ${widget.kg(lot['quantity_kg']).toStringAsFixed(3)} kg',
                          ),
                          dense: true,
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _transporter,
                    decoration: const InputDecoration(
                      labelText: 'Transporter (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _vehicle,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle number (optional)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _partyId != null && _selected.isNotEmpty
              ? () => Navigator.pop(
                  context,
                  _DispatchDraft(
                    _partyId!,
                    _selected.toList(),
                    _date,
                    _transporter.text.trim(),
                    _vehicle.text.trim(),
                    _notes.text.trim(),
                  ),
                )
              : null,
          icon: const Icon(Icons.check),
          label: const Text('Post challan'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: BBTheme.redLight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(color: BBTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool isError;
  const _InfoBox({required this.text, this.isError = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: BBTheme.panel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: isError ? BBTheme.red : BBTheme.border),
    ),
    child: Text(
      text,
      style: TextStyle(color: isError ? BBTheme.redLight : BBTheme.muted),
    ),
  );
}

class _DispatchDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> details;
  final double Function(dynamic) kg;
  const _DispatchDetailsDialog({required this.details, required this.kg});
  @override
  Widget build(BuildContext context) {
    final dispatch = Map<String, dynamic>.from(details['dispatch'] as Map);
    final lines = (details['lines'] as List<Map<String, dynamic>>?) ?? const [];
    return AlertDialog(
      title: Text('Challan ${dispatch['dispatch_no']}'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${dispatch['party_name']}  ·  ${dispatch['challan_date']}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if ('${dispatch['transporter'] ?? ''}'.isNotEmpty ||
                  '${dispatch['vehicle_no'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${dispatch['transporter'] ?? ''}  ${dispatch['vehicle_no'] ?? ''}',
                  style: const TextStyle(color: BBTheme.muted),
                ),
              ],
              const Divider(height: 24),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${line['lot_no']}  ·  ${line['roll_no']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${line['job_no']}  ·  ${line['fabric_name'] ?? ''}  ·  GSM ${line['gsm'] ?? '—'}',
                              style: const TextStyle(
                                color: BBTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('${kg(line['quantity_kg']).toStringAsFixed(3)} kg'),
                    ],
                  ),
                ),
              if ('${dispatch['notes'] ?? ''}'.trim().isNotEmpty) ...[
                const Divider(height: 24),
                Text('${dispatch['notes']}'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
