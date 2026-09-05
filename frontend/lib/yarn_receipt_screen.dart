import 'package:flutter/material.dart';
import 'services/yarn_receipt_service.dart';

class YarnReceiptScreen extends StatefulWidget {
  const YarnReceiptScreen({super.key});

  @override
  State<YarnReceiptScreen> createState() => _YarnReceiptScreenState();
}

class _ReceiptLine {
  String? yarnId;
  final yarnName = TextEditingController();
  final supplierLot = TextEditingController();
  final quantity = TextEditingController();
  final rate = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    yarnName.dispose();
    supplierLot.dispose();
    quantity.dispose();
    rate.dispose();
    notes.dispose();
  }
}

class _YarnReceiptScreenState extends State<YarnReceiptScreen> {
  final _api = YarnReceiptApi();
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _challan = TextEditingController();
  final _bill = TextEditingController();
  final _notes = TextEditingController();

  List<YarnReceiptSupplier> _suppliers = [];
  List<YarnReceiptLocation> _locations = [];
  List<Map<String, dynamic>> _yarns = [];
  YarnReceiptSupplier? _supplier;
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
        _api.getSuppliers(),
        _api.getLocations(),
      ]);
      if (!mounted) return;
      setState(() {
        _suppliers = results[0] as List<YarnReceiptSupplier>;
        _locations = results[1] as List<YarnReceiptLocation>;
        _loading = false;
      });
      await _loadYarns();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error(e.toString());
    }
  }

  Future<void> _loadYarns() async {
    // The existing Yarn Master endpoint is already the source for generic yarns.
    // Importing ApiService here would couple this module to unrelated APIs, so
    // we use the same endpoint directly.
    try {
      final r = await _api.getYarns();
      if (!mounted) return;
      setState(() => _yarns = r);
    } catch (e) {
      if (mounted) _error('Could not load Yarn Master: $e');
    }
  }

  Future<void> _save() async {
    if (_supplier == null) {
      _error('Select a supplier.');
      return;
    }
    if (_date.text.trim().isEmpty) {
      _error('Enter receipt date.');
      return;
    }

    final seen = <String>{};
    final lines = <Map<String, dynamic>>[];

    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final yarnId = line.yarnId;
      final qty = double.tryParse(line.quantity.text.trim());

      if (yarnId == null) {
        _error('Select yarn on line ${i + 1}.');
        return;
      }
      if (!seen.add(yarnId)) {
        _error('The same Yarn Master cannot be entered twice in one receipt. Combine its quantity into one line.');
        return;
      }
      if (qty == null || qty <= 0) {
        _error('Enter a quantity greater than zero on line ${i + 1}.');
        return;
      }

      final rateText = line.rate.text.trim();
      final rate = rateText.isEmpty ? null : double.tryParse(rateText);
      if (rateText.isNotEmpty && (rate == null || rate < 0)) {
        _error('Invalid rate on line ${i + 1}.');
        return;
      }

      lines.add({
        'yarn_id': yarnId,
        'supplier_lot_no': line.supplierLot.text.trim().isEmpty
            ? null
            : line.supplierLot.text.trim(),
        'quantity': qty,
        'unit_rate': rate,
        'notes': line.notes.text.trim().isEmpty ? null : line.notes.text.trim(),
      });
    }

    setState(() => _saving = true);
    try {
      final result = await _api.createReceipt(
        receiptDate: _date.text.trim(),
        challanNo: _challan.text.trim().isEmpty ? null : _challan.text.trim(),
        billNo: _bill.text.trim().isEmpty ? null : _bill.text.trim(),
        supplierId: _supplier!.id,
        locationId: _location?.id,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        lines: lines,
      );

      if (!mounted) return;
      final receipt = Map<String, dynamic>.from(result['receipt'] ?? {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt ${receipt['receipt_no'] ?? ''} posted successfully.'),
        ),
      );
      _clearForm();
    } catch (e) {
      if (mounted) _error(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _challan.clear();
    _bill.clear();
    _notes.clear();
    _supplier = null;
    _location = null;
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..add(_ReceiptLine());
    setState(() {});
  }

  void _addLine() => setState(() => _lines.add(_ReceiptLine()));

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  void _error(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yarn Receipt'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yarn Receipt'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Post Receipt'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receive Yarn',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'One challan/bill can contain any number of different yarns.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _date,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<YarnReceiptSupplier>(
                        value: _supplier,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                        items: _suppliers
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _supplier = v),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _challan,
                        decoration: const InputDecoration(
                          labelText: 'Challan No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _bill,
                        decoration: const InputDecoration(
                          labelText: 'Bill No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<YarnReceiptLocation>(
                        value: _location,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        items: _locations
                            .map((l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _location = v),
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _notes,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Yarn Lines',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Yarn'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_lines.length, (index) {
                      final line = _lines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 310,
                              child: DropdownButtonFormField<String>(
                                value: line.yarnId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Yarn ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                items: _yarns.map((y) {
                                  final id = '${y['id']}';
                                  final count = '${y['count'] ?? ''}'.trim();
                                  final label = '${y['name'] ?? ''}${count.isEmpty ? '' : ' • $count'}';
                                  return DropdownMenuItem(
                                    value: id,
                                    child: Text(label, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => line.yarnId = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: line.supplierLot,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier Lot No.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: line.quantity,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Qty (kg)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: line.rate,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Rate',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _lines.length == 1 ? null : () => _removeLine(index),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove line',
                            ),
                          ],
                        ),
                      );
                    }),
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
