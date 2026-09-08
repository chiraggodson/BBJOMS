import 'package:flutter/material.dart';
import 'services/yarn_receipt_service.dart';

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
  Widget build(BuildContext context) => Container(
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

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
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
              child: Icon(icon, color: _teal, size: 21),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
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

class _Status extends StatelessWidget {
  final String text;

  const _Status(this.text);

  @override
  Widget build(BuildContext context) {
    Color c = _muted;
    if (text == 'Running' || text == 'Open' || text == 'Available') {
      c = const Color(0xFF2DD4BF);
    }
    if (text == 'Yarn Needed' || text == 'Low Stock') {
      c = const Color(0xFFF87171);
    }
    if (text == 'Paused' || text == 'Pending') {
      c = const Color(0xFFFBBF24);
    }
    if (text == 'Closed' || text == 'Complete') {
      c = const Color(0xFFA78BFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Widget _search(String hint) => TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: _panel2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF25313B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF25313B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _teal),
        ),
      ),
    );

Widget _primary(
  String label,
  IconData icon,
  VoidCallback onPressed,
) =>
    FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
    );

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  final items = const [
    ('Finished Fabric', 'Single Jersey 180 GSM', '2,840 kg', 'Good'),
    ('Finished Fabric', 'Interlock 220 GSM', '1,920 kg', 'Good'),
    ('Yarn', 'Polyester 75D', '1,842 kg', 'Available'),
    ('Yarn', 'Cotton 30s', '932 kg', 'Available'),
    ('Yarn', 'Spandex 40D', '238 kg', 'Low Stock'),
  ];

  Future<void> _openReceiveYarn(BuildContext context) async {
    final posted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ReceiveYarnDialog(),
    );

    if (posted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yarn receipt posted successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
                        'Inventory',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Yarn, fabric and stock movement overview',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _primary(
                  'Receive Yarn',
                  Icons.south_west,
                  () => _openReceiveYarn(context),
                ),
                const SizedBox(width: 10),
                _primary(
                  'Stock Adjustment',
                  Icons.tune,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (_, c) => c.maxWidth < 760
                  ? const Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _Stat('Yarn Stock', '5,480 kg', Icons.all_inclusive),
                        _Stat('Fabric Stock', '4,760 kg', Icons.layers_outlined),
                        _Stat('Receipts Today', '730 kg', Icons.south_west),
                        _Stat('Issues Today', '410 kg', Icons.north_east),
                      ],
                    )
                  : const Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            'Yarn Stock',
                            '5,480 kg',
                            Icons.all_inclusive,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _Stat(
                            'Fabric Stock',
                            '4,760 kg',
                            Icons.layers_outlined,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _Stat(
                            'Receipts Today',
                            '730 kg',
                            Icons.south_west,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _Stat(
                            'Issues Today',
                            '410 kg',
                            Icons.north_east,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Stock Overview',
              child: Column(
                children: [
                  _search('Search item or material...'),
                  const SizedBox(height: 14),
                  ...items.map(
                    (i) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                              Icons.inventory_2_outlined,
                              color: _teal,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  i.$2,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              i.$3,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _Status(i.$4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Recent Stock Movements',
              child: Column(
                children: [
                  _move(
                    Icons.south_west,
                    'Yarn Received',
                    'A.K. Goyal Hosiery',
                    '420 kg',
                  ),
                  _move(
                    Icons.north_east,
                    'Yarn Issued',
                    'BBJO-00128',
                    '180 kg',
                  ),
                  _move(
                    Icons.layers_outlined,
                    'Fabric Produced',
                    'M-24 / BBJO-00127',
                    '112 kg',
                  ),
                  _move(
                    Icons.keyboard_return,
                    'Yarn Returned',
                    'BBJO-00125',
                    '24 kg',
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _move(
    IconData icon,
    String a,
    String b,
    String c,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF1D2933)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _teal, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    b,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              c,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

/* ============================================================
   RECEIVE YARN - INLINE INVENTORY FORM
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
  final _api = YarnReceiptApi();

  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _challan = TextEditingController();
  final _bill = TextEditingController();
  final _notes = TextEditingController();

  List<YarnReceiptCompany> _companies = [];
  List<YarnReceiptSupplier> _suppliers = [];
  List<YarnReceiptColor> _colors = [];
  List<YarnReceiptLocation> _locations = [];
  List<Map<String, dynamic>> _yarns = [];

  YarnReceiptCompany? _company;
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
        _api.getCompanies(),
        _api.getSuppliers(),
        _api.getColors(),
        _api.getYarns(),
      ]);

      if (!mounted) return;

      final companies = results[0] as List<YarnReceiptCompany>;
      final suppliers = results[1] as List<YarnReceiptSupplier>;
      final colors = results[2] as List<YarnReceiptColor>;
      final yarns = results[3] as List<Map<String, dynamic>>;

      YarnReceiptCompany? selectedCompany;
      if (companies.length == 1) {
        selectedCompany = companies.first;
      }

      List<YarnReceiptLocation> locations = [];
      if (selectedCompany != null) {
        locations = await _api.getLocations();
      }

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _supplier = null;
        _company = selectedCompany;
        _suppliers = suppliers;
        _colors = colors;
        _locations = locations;
        
        _yarns = yarns;
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
      _showError('Select the company that owns this yarn.');
      return;
    }

    if (_supplier == null) {
      _showError('Select a supplier.');
      return;
    }

    if (_date.text.trim().isEmpty) {
      _showError('Enter receipt date.');
      return;
    }

    if (_location == null) {
      _showError(
        _locations.isEmpty
            ? 'No active location is configured for the selected company. Please create a location first.'
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

      final lineKey = '${line.yarnId}|${line.colorId}';
      if (!seen.add(lineKey)) {
        _showError(
          'The same Yarn + Color cannot be entered twice in one receipt.',
        );
        return;
      }

      final boxesText = line.boxes.text.trim();
      final boxes = boxesText.isEmpty ? null : int.tryParse(boxesText);
      if (boxesText.isNotEmpty && (boxes == null || boxes < 0)) {
        _showError('Enter a valid whole number of boxes on line ${i + 1}.');
        return;
      }

      final quantity = double.tryParse(
        line.quantity.text.trim(),
      );

      if (quantity == null || quantity <= 0) {
        _showError(
          'Enter a quantity greater than zero on line ${i + 1}.',
        );
        return;
      }

      final rateText = line.rate.text.trim();
      final rate = rateText.isEmpty
          ? null
          : double.tryParse(rateText);

      if (rateText.isNotEmpty &&
          (rate == null || rate < 0)) {
        _showError('Invalid rate on line ${i + 1}.');
        return;
      }

      lines.add({
        'yarn_id': line.yarnId,
        'color_id': line.colorId,
        'box_count': boxes,
        'supplier_lot_no':
            line.supplierLot.text.trim().isEmpty
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
        challanNo: _challan.text.trim().isEmpty
            ? null
            : _challan.text.trim(),
        billNo: _bill.text.trim().isEmpty
            ? null
            : _bill.text.trim(),
        supplierId: _supplier!.id,
        locationId: _location!.id,
        notes: _notes.text.trim().isEmpty
            ? null
            : _notes.text.trim(),
        lines: lines,
      );

      if (!mounted) return;

      final receipt = result['receipt'];
      final receiptNo = receipt is Map
          ? '${receipt['receipt_no'] ?? ''}'
          : '';

      Navigator.of(context).pop(true);

      if (receiptNo.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receipt $receiptNo posted successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
        content: Text(
          message.replaceFirst('Exception: ', ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receive Yarn',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add one or multiple yarns against the same challan/bill.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _panel2,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border:
                                    Border.all(color: _border),
                              ),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: 230,
                                    child: DropdownButtonFormField<YarnReceiptCompany>(
                                      value: _company,
                                      isExpanded: true,
                                      decoration: _decoration('Company *'),
                                      items: _companies
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(
                                                c.name,
                                                overflow: TextOverflow.ellipsis,
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
                                                final locations = await _api.getLocations();
                                                if (!mounted) return;
                                                setState(() => _locations = locations);
                                              } catch (e) {
                                                if (mounted) _showError(e.toString());
                                              }
                                            },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 170,
                                    child: TextField(
                                      controller: _date,
                                      decoration: _decoration('Receipt Date'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 260,
                                    child:
                                        DropdownButtonFormField<
                                            YarnReceiptSupplier>(
                                      value: _supplier,
                                      isExpanded: true,
                                      decoration:
                                          _decoration('Supplier'),
                                      items: _suppliers
                                          .map(
                                            (s) =>
                                                DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s.name,
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
                                                () =>
                                                    _supplier = v,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 190,
                                    child: TextField(
                                      controller: _challan,
                                      decoration: _decoration(
                                        'Challan No.',
                                      ),
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
                                    child:
                                        DropdownButtonFormField<
                                            YarnReceiptLocation>(
                                      value: _location,
                                      isExpanded: true,
                                      decoration:
                                          _decoration('Location *'),
                                      items: _locations
                                          .map(
                                            (l) =>
                                                DropdownMenuItem(
                                              value: l,
                                              child: Text(
                                                l.name,
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
                                                () =>
                                                    _location = v,
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
                                borderRadius:
                                    BorderRadius.circular(10),
                                border:
                                    Border.all(color: _border),
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
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed:
                                            _saving ? null : _addLine,
                                        icon:
                                            const Icon(Icons.add),
                                        label:
                                            const Text('Add Yarn'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(
                                    _lines.length,
                                    (index) {
                                      final line =
                                          _lines[index];

                                      final seenIds =
                                          <String>{};

                                      final yarnItems = _yarns
                                          .where((y) {
                                            final id =
                                                '${y['id'] ?? ''}'
                                                    .trim();
                                            if (id.isEmpty ||
                                                !seenIds
                                                    .add(id)) {
                                              return false;
                                            }
                                            return true;
                                          })
                                          .map(
                                            (y) {
                                              final id =
                                                  '${y['id']}';
                                              final name =
                                                  '${y['name'] ?? ''}'
                                                      .trim();
                                              final count =
                                                  '${y['count'] ?? ''}'
                                                      .trim();
                                              final label =
                                                  '$name${count.isEmpty ? '' : ' • $count'}';

                                              return DropdownMenuItem<
                                                  String>(
                                                value: id,
                                                child: Text(
                                                  label,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                ),
                                              );
                                            },
                                          )
                                          .toList();

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          crossAxisAlignment:
                                              WrapCrossAlignment
                                                  .center,
                                          children: [
                                            SizedBox(
                                              width: 320,
                                              child:
                                                  DropdownButtonFormField<
                                                      String>(
                                                value: line.yarnId,
                                                isExpanded: true,
                                                decoration:
                                                    _decoration(
                                                  'Yarn ${index + 1}',
                                                ),
                                                items: yarnItems,
                                                onChanged: _saving
                                                    ? null
                                                    : (v) =>
                                                        setState(
                                                          () => line
                                                              .yarnId = v,
                                                        ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 190,
                                              child: DropdownButtonFormField<String>(
                                                value: line.colorId,
                                                isExpanded: true,
                                                decoration: _decoration('Color ${index + 1}'),
                                                items: _colors
                                                    .map((c) => DropdownMenuItem<String>(
                                                          value: c.id,
                                                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                                                        ))
                                                    .toList(),
                                                onChanged: _saving
                                                    ? null
                                                    : (v) => setState(() => line.colorId = v),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 145,
                                              child: TextField(
                                                controller: line.boxes,
                                                keyboardType: TextInputType.number,
                                                decoration: _decoration('No. of Boxes'),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 180,
                                              child: TextField(
                                                controller: line.supplierLot,
                                                decoration:
                                                    _decoration(
                                                  'Supplier Lot No.',
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 140,
                                              child: TextField(
                                                controller:
                                                    line.quantity,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                decoration:
                                                    _decoration(
                                                  'Qty (kg)',
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 130,
                                              child: TextField(
                                                controller:
                                                    line.rate,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                decoration:
                                                    _decoration(
                                                  'Rate',
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _saving ||
                                                      _lines.length ==
                                                          1
                                                  ? null
                                                  : () =>
                                                      _removeLine(
                                                        index,
                                                      ),
                                              icon: const Icon(
                                                Icons
                                                    .delete_outline,
                                              ),
                                              tooltip:
                                                  'Remove line',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
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
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _saving
                                ? 'Posting...'
                                : 'Post Receipt',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
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
