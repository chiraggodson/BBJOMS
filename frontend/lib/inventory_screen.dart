
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'services/yarn_receipt_service.dart';

const _panel = BBTheme.panel;
const _panel2 = BBTheme.black3;
const _border = BBTheme.border;
const _muted = BBTheme.muted;
const _accent = BBTheme.red;

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final YarnReceiptApi _api = YarnReceiptApi();

  List<Map<String, dynamic>> _stock = [];
  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;
  String? _error;

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
      final results = await Future.wait([
        _api.getYarnStock(),
        _api.getYarnMovements(limit: 20),
      ]);

      if (!mounted) return;

      setState(() {
        _stock = results[0] as List<Map<String, dynamic>>;
        _movements = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value'.replaceAll(',', '').trim()) ?? 0;
  }

  double _stockQty(Map<String, dynamic> row) {
    for (final key in [
      'balance',
      'balance_qty',
      'available_qty',
      'available_quantity',
      'quantity',
      'qty',
      'closing_qty',
      'stock_qty',
      'current_balance',
    ]) {
      if (row.containsKey(key) && row[key] != null) {
        return _number(row[key]);
      }
    }
    return 0;
  }

  String _stockName(Map<String, dynamic> row) {
    for (final key in [
      'yarn_name',
      'yarn',
      'name',
      'yarn_description',
      'yarn_master_name',
    ]) {
      final value = '${row[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') return value;
    }
    return 'Yarn';
  }

  String _stockSecondary(Map<String, dynamic> row) {
    final parts = <String>[];

    for (final key in ['yarn_count', 'count', 'yarn_type', 'type']) {
      final value = '${row[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') parts.add(value);
    }

    for (final key in ['color_name', 'color', 'colour_name']) {
      final value = '${row[key] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') parts.add(value);
    }

    final owner = '${row['owner_name'] ?? row['stock_owner_name'] ?? ''}'.trim();
if (owner.isNotEmpty && owner != 'null') {
  parts.add('Owner: $owner');
}

for (final key in ['location_name', 'location']) {
  final value = '${row[key] ?? ''}'.trim();
  if (value.isNotEmpty && value != 'null') {
    parts.add(value);
    break;
  }
}

    return parts.join(' • ');
  }

  String _formatKg(double value) {
    if (value.abs() >= 1000) {
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} kg';
    }
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} kg';
  }

  bool _isToday(dynamic value) {
    final text = '$value';
    if (text.isEmpty || text == 'null') return false;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return false;

    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  double _todayMovementTotal(bool incoming) {
    double total = 0;

    for (final row in _movements) {
      final type = '${row['movement_type'] ?? row['type'] ?? row['transaction_type'] ?? ''}'
          .toLowerCase();

      final incomingType = type.contains('receipt') ||
          type.contains('receive') ||
          type.contains('inward') ||
          type.contains('received');

      final outgoingType = type.contains('issue') ||
          type.contains('issued') ||
          type.contains('outward') ||
          type.contains('return');

      final matches = incoming ? incomingType : outgoingType;
      if (!matches) continue;

      final date = row['movement_date'] ??
          row['transaction_date'] ??
          row['date'] ??
          row['created_at'];

      if (_isToday(date)) {
        for (final key in [
          'quantity',
          'qty',
          'weight',
          'quantity_kg',
          'weight_kg',
        ]) {
          if (row[key] != null) {
            total += _number(row[key]);
            break;
          }
        }
      }
    }

    return total;
  }

  Future<void> _receiveYarn() async {
    final posted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ReceiveYarnDialog(),
    );

    if (posted == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStock =
        _stock.fold<double>(0, (sum, row) => sum + _stockQty(row));
    final receiptsToday = _todayMovementTotal(true);
    final issuesToday = _todayMovementTotal(false);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 34),
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
                        'Inventory',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Live yarn stock and stock movement',
                        style: TextStyle(color: _muted, fontSize: 14),
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
                  onPressed: _loading ? null : _receiveYarn,
                  icon: const Icon(Icons.south_west, size: 18),
                  label: const Text('Receive Yarn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) _ErrorBanner(message: _error!),
            if (_error != null) const SizedBox(height: 16),
            LayoutBuilder(
              builder: (_, constraints) {
                final stats = [
                  _Stat(
                    title: 'Yarn Stock',
                    value: _loading ? '...' : _formatKg(totalStock),
                    icon: Icons.all_inclusive,
                  ),
                  _Stat(
                    title: 'Yarn Lots',
                    value: _loading ? '...' : '${_stock.length}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _Stat(
                    title: 'Receipts Today',
                    value: _loading ? '...' : _formatKg(receiptsToday),
                    icon: Icons.south_west,
                  ),
                  _Stat(
                    title: 'Issues Today',
                    value: _loading ? '...' : _formatKg(issuesToday),
                    icon: Icons.north_east,
                  ),
                ];

                if (constraints.maxWidth < 760) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stats,
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      Expanded(child: stats[i]),
                      if (i != stats.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Live Yarn Stock',
              action: '${_stock.length} lots',
              child: _loading
                  ? const _LoadingBox()
                  : _stock.isEmpty
                      ? const _EmptyBox(
                          icon: Icons.inventory_2_outlined,
                          text: 'No yarn stock available.',
                        )
                      : Column(
                          children: [
                            for (final row in _stock) _stockRow(row),
                          ],
                        ),
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Recent Stock Movements',
              action: '${_movements.length} records',
              child: _loading
                  ? const _LoadingBox()
                  : _movements.isEmpty
                      ? const _EmptyBox(
                          icon: Icons.swap_vert,
                          text: 'No stock movements found.',
                        )
                      : Column(
                          children: [
                            for (final row in _movements) _movementRow(row),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockRow(Map<String, dynamic> row) {
    final qty = _stockQty(row);
    final secondary = _stockSecondary(row);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stockName(row),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (secondary.isNotEmpty)
                  Text(
                    secondary,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatKg(qty),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          _Status(qty > 0 ? 'Available' : 'Empty'),
        ],
      ),
    );
  }

  Widget _movementRow(Map<String, dynamic> row) {
    final type = '${row['movement_type'] ?? row['type'] ?? row['transaction_type'] ?? 'Stock Movement'}';
    final lower = type.toLowerCase();

    final incoming = lower.contains('receipt') ||
        lower.contains('receive') ||
        lower.contains('inward') ||
        lower.contains('received');

    final outgoing = lower.contains('issue') ||
        lower.contains('issued') ||
        lower.contains('outward');

    final icon = incoming
        ? Icons.south_west
        : outgoing
            ? Icons.north_east
            : Icons.swap_vert;

    final title = incoming
        ? 'Yarn Received'
        : outgoing
            ? 'Yarn Issued'
            : type;

    final party = '${row['party_name'] ?? row['customer_name'] ?? row['party'] ?? ''}'.trim();
    final reference = '${row['reference_no'] ?? row['receipt_no'] ?? row['job_no'] ?? row['document_no'] ?? ''}'.trim();
    final yarn = '${row['yarn_name'] ?? row['yarn'] ?? ''}'.trim();

    final details = [
      if (party.isNotEmpty && party != 'null') party,
      if (reference.isNotEmpty && reference != 'null') reference,
      if (yarn.isNotEmpty && yarn != 'null') yarn,
    ].join(' • ');

    double qty = 0;
    for (final key in ['quantity', 'qty', 'weight', 'quantity_kg', 'weight_kg']) {
      if (row[key] != null) {
        qty = _number(row[key]);
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatKg(qty),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(7),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

  const _Stat({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, color: _accent, size: 21),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
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
    final color = text == 'Available'
        ? const Color(0xFF2DD4BF)
        : text == 'Empty'
            ? const Color(0xFFF87171)
            : _muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyBox({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _muted, size: 26),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: _muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A171A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF7F1D1D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(''),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   RECEIVE YARN
   ============================================================ */

class _ReceiptLine {
  String? yarnId;
  String? colorId;
  final supplierLot = TextEditingController();
  final boxes = TextEditingController();
  final quantity = TextEditingController();
  final rate = TextEditingController();

  void dispose() {
    supplierLot.dispose();
    boxes.dispose();
    quantity.dispose();
    rate.dispose();
  }
}

class _ReceiveYarnDialog extends StatefulWidget {
  const _ReceiveYarnDialog();

  @override
  State<_ReceiveYarnDialog> createState() => _ReceiveYarnDialogState();
}

class _ReceiveYarnDialogState extends State<_ReceiveYarnDialog> {
  final YarnReceiptApi _api = YarnReceiptApi();

  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _challan = TextEditingController();
  final _bill = TextEditingController();
  final _notes = TextEditingController();

  List<YarnReceiptCompany> _companies = [];
  List<YarnReceiptParty> _parties = [];
  List<YarnReceiptParty> _suppliers = [];
  List<YarnReceiptColor> _colors = [];
  List<YarnReceiptLocation> _locations = [];
  List<Map<String, dynamic>> _yarns = [];

  YarnReceiptCompany? _company;
  YarnReceiptParty? _party;
  YarnReceiptParty? _supplier;
  YarnReceiptLocation? _location;

  bool _loading = true;
  bool _saving = false;

  final List<_ReceiptLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _lines.add(_ReceiptLine());
    _load();
  }

  @override
  void dispose() {
    _date.dispose();
    _challan.dispose();
    _bill.dispose();
    _notes.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getCompanies(),
        _api.getParties(),
        _api.getSuppliers(),
        _api.getColors(),
        _api.getYarns(),
      ]);

      if (!mounted) return;

      final companies = results[0] as List<YarnReceiptCompany>;
      final parties = results[1] as List<YarnReceiptParty>;
      final suppliers = results[2] as List<YarnReceiptParty>;
      final colors = results[3] as List<YarnReceiptColor>;
      final yarns = results[4] as List<Map<String, dynamic>>;

      YarnReceiptCompany? selectedCompany;
      if (companies.length == 1) {
        selectedCompany = companies.first;
      }

      List<YarnReceiptLocation> locations = [];
      if (selectedCompany != null) {
        locations = await _api.getLocations(
          companyId: selectedCompany.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _parties = parties;
        _suppliers = suppliers;
        _colors = colors;
        _yarns = yarns;
        _company = selectedCompany;
        _locations = locations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _save() async {
    if (_company == null) {
      _showError('No company is configured for yarn receipt.');
      return;
    }

    if (_party == null) {
      _showError('Select the customer / party sending the yarn.');
      return;
    }

    if (_supplier == null) {
      _showError('Select the yarn supplier / source.');
      return;
    }

    if (_date.text.trim().isEmpty) {
      _showError('Enter receipt date.');
      return;
    }

    if (_location == null) {
      _showError(
        _locations.isEmpty
            ? 'No active location is configured.'
            : 'Select a location.',
      );
      return;
    }

    final seen = <String>{};
    final lines = <Map<String, dynamic>>[];

    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];

      if (line.yarnId == null) {
        _showError('Select yarn on line ${i + 1}.');
        return;
      }

      if (line.colorId == null) {
        _showError('Select color on line ${i + 1}.');
        return;
      }

      final key = '${line.yarnId}|${line.colorId}';
      if (!seen.add(key)) {
        _showError(
          'The same Yarn + Color cannot be entered twice in one receipt.',
        );
        return;
      }

      final boxesText = line.boxes.text.trim();
      final boxes = boxesText.isEmpty ? null : int.tryParse(boxesText);

      if (boxesText.isNotEmpty && (boxes == null || boxes < 0)) {
        _showError('Invalid box count on line ${i + 1}.');
        return;
      }

      final quantity = double.tryParse(line.quantity.text.trim());

      if (quantity == null || quantity <= 0) {
        _showError('Enter quantity greater than zero on line ${i + 1}.');
        return;
      }

      final rateText = line.rate.text.trim();
      final rate = rateText.isEmpty ? null : double.tryParse(rateText);

      if (rateText.isNotEmpty && (rate == null || rate < 0)) {
        _showError('Invalid rate on line ${i + 1}.');
        return;
      }

      lines.add({
        'yarn_id': line.yarnId,
        'color_id': line.colorId,
        'box_count': boxes,
        'supplier_lot_no': line.supplierLot.text.trim().isEmpty
            ? null
            : line.supplierLot.text.trim(),
        'quantity': quantity,
        'unit_rate': rate,
      });
    }

    setState(() => _saving = true);

    try {
      final result = await _api.createReceipt(
        receiptDate: _date.text.trim(),
        companyId: _company!.id,
        partyId: _party!.id,
        supplierPartyId: _supplier!.id,
        challanNo:
            _challan.text.trim().isEmpty ? null : _challan.text.trim(),
        billNo: _bill.text.trim().isEmpty ? null : _bill.text.trim(),
        locationId: _location!.id,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        lines: lines,
      );

      if (!mounted) return;

      final receipt = result['receipt'];
      final receiptNo =
          receipt is Map ? '${receipt['receipt_no'] ?? ''}' : '';

      Navigator.of(context).pop(true);

      if (receiptNo.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt $receiptNo posted successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addLine() {
    setState(() => _lines.add(_ReceiptLine()));
  }

  void _removeLine(int index) {
    if (_lines.length == 1) return;

    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Receive Yarn'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _panel,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1050,
          maxHeight: 760,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receive Yarn',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Post yarn received from a customer / party.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _panel2,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: _border),
                              ),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (_companies.length > 1)
                                    SizedBox(
                                      width: 230,
                                      child: DropdownButtonFormField<
                                          YarnReceiptCompany>(
                                        value: _company,
                                        isExpanded: true,
                                        decoration:
                                            _decoration('Company'),
                                        items: _companies
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(
                                                  c.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: _saving
                                            ? null
                                            : (v) async {
                                                setState(() {
                                                  _company = v;
                                                  _location = null;
                                                  _locations = [];
                                                });

                                                if (v == null) return;

                                                try {
                                                  final locations =
                                                      await _api.getLocations(
                                                    companyId: v.id,
                                                  );
                                                  if (!mounted) return;
                                                  setState(() =>
                                                      _locations =
                                                          locations);
                                                } catch (e) {
                                                  if (mounted) {
                                                    _showError(e.toString());
                                                  }
                                                }
                                              },
                                      ),
                                    ),
                                  SizedBox(
                                    width: 170,
                                    child: TextField(
                                      controller: _date,
                                      decoration:
                                          _decoration('Receipt Date'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    child: DropdownButtonFormField<
                                        YarnReceiptParty>(
                                      value: _party,
                                      isExpanded: true,
                                      decoration: _decoration(
                                        'Customer / Party *',
                                      ),
                                      items: _parties
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(
                                                p.name,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _saving
                                          ? null
                                          : (v) async {
                                              setState(() {
                                                _party = v;
                                                _supplier = null;
                                              });

                                              if (v == null) return;

                                              try {
                                                final suppliers =
                                                    await _api.getSuppliers(
                                                  partyId: v.id,
                                                );
                                                if (!mounted) return;
                                                setState(() {
                                                  _suppliers = suppliers;
                                                  _supplier = null;
                                                });
                                              } catch (e) {
                                                if (mounted) {
                                                  _showError(e.toString());
                                                }
                                              }
                                            },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    child: DropdownButtonFormField<
                                        YarnReceiptParty>(
                                      value: _supplier,
                                      isExpanded: true,
                                      decoration: _decoration(
                                        'Yarn Supplier / Source *',
                                      ),
                                      items: _suppliers
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(
                                                p.name,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _saving
                                          ? null
                                          : (v) => setState(
                                                () => _supplier = v,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 190,
                                    child: TextField(
                                      controller: _challan,
                                      decoration:
                                          _decoration('Challan No.'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 190,
                                    child: TextField(
                                      controller: _bill,
                                      decoration:
                                          _decoration('Bill No.'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 220,
                                    child: DropdownButtonFormField<
                                        YarnReceiptLocation>(
                                      value: _location,
                                      isExpanded: true,
                                      decoration:
                                          _decoration('Location *'),
                                      items: _locations
                                          .map(
                                            (l) => DropdownMenuItem(
                                              value: l,
                                              child: Text(
                                                l.name,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _saving
                                          ? null
                                          : (v) => setState(
                                                () => _location = v,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 430,
                                    child: TextField(
                                      controller: _notes,
                                      decoration:
                                          _decoration('Remarks'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _panel2,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Yarn Lines',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed:
                                            _saving ? null : _addLine,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Yarn'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(_lines.length, (index) {
                                    final line = _lines[index];

                                    final seen = <String>{};
                                    final yarnItems = _yarns
                                        .where((y) {
                                          final id =
                                              '${y['id'] ?? ''}'.trim();
                                          if (id.isEmpty ||
                                              !seen.add(id)) {
                                            return false;
                                          }
                                          return true;
                                        })
                                        .map((y) {
                                          final id = '${y['id']}';
                                          final name =
                                              '${y['name'] ?? y['yarn_name'] ?? ''}'
                                                  .trim();
                                          final count =
                                              '${y['count'] ?? y['yarn_count'] ?? ''}'
                                                  .trim();

                                          final label = '$name'
                                              '${count.isEmpty ? '' : ' • $count'}';

                                          return DropdownMenuItem<String>(
                                            value: id,
                                            child: Text(
                                              label,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          );
                                        })
                                        .toList();

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 320,
                                            child:
                                                DropdownButtonFormField<
                                                    String>(
                                              value: line.yarnId,
                                              isExpanded: true,
                                              decoration: _decoration(
                                                'Yarn ${index + 1}',
                                              ),
                                              items: yarnItems,
                                              onChanged: _saving
                                                  ? null
                                                  : (v) => setState(
                                                        () => line.yarnId =
                                                            v,
                                                      ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 190,
                                            child:
                                                DropdownButtonFormField<
                                                    String>(
                                              value: line.colorId,
                                              isExpanded: true,
                                              decoration: _decoration(
                                                'Color ${index + 1}',
                                              ),
                                              items: _colors
                                                  .map(
                                                    (c) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                      value: c.id,
                                                      child: Text(
                                                        c.name,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: _saving
                                                  ? null
                                                  : (v) => setState(
                                                        () => line.colorId =
                                                            v,
                                                      ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 145,
                                            child: TextField(
                                              controller: line.boxes,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: _decoration(
                                                'No. of Boxes',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 180,
                                            child: TextField(
                                              controller: line.supplierLot,
                                              decoration: _decoration(
                                                'Supplier Lot No.',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: TextField(
                                              controller: line.quantity,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration: _decoration(
                                                'Qty (kg)',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 130,
                                            child: TextField(
                                              controller: line.rate,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration:
                                                  _decoration('Rate'),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _saving ||
                                                    _lines.length == 1
                                                ? null
                                                : () => _removeLine(index),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            tooltip: 'Remove line',
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
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
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _saving ? 'Posting...' : 'Post Receipt',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
