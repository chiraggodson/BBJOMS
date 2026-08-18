import 'package:flutter/material.dart';

class YarnPage extends StatefulWidget {
  const YarnPage({super.key});

  @override
  State<YarnPage> createState() => _YarnPageState();
}

class _YarnPageState extends State<YarnPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_YarnItem> _yarns = [
    _YarnItem(
      name: 'Polyester 75D',
      count: '75D',
      type: 'Polyester',
      stock: 1842,
      lots: 6,
      unit: 'kg',
    ),
    _YarnItem(
      name: 'Polyester 150D',
      count: '150D',
      type: 'Polyester',
      stock: 1268,
      lots: 4,
      unit: 'kg',
    ),
    _YarnItem(
      name: 'Cotton 30s',
      count: '30s',
      type: 'Cotton',
      stock: 932,
      lots: 5,
      unit: 'kg',
    ),
    _YarnItem(
      name: 'Cotton 40s',
      count: '40s',
      type: 'Cotton',
      stock: 714,
      lots: 3,
      unit: 'kg',
    ),
    _YarnItem(
      name: 'Viscose 30s',
      count: '30s',
      type: 'Viscose',
      stock: 486,
      lots: 2,
      unit: 'kg',
    ),
    _YarnItem(
      name: 'Spandex 40D',
      count: '40D',
      type: 'Spandex',
      stock: 238,
      lots: 2,
      unit: 'kg',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_YarnItem> get _filteredYarns {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _yarns;

    return _yarns.where((yarn) {
      return yarn.name.toLowerCase().contains(query) ||
          yarn.count.toLowerCase().contains(query) ||
          yarn.type.toLowerCase().contains(query);
    }).toList();
  }

  void _openReceiveYarn() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ReceiveYarnDialog(),
    );
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
                      'Yarn master, lots and live stock',
                      style: TextStyle(
                        color: Color(0xFF84919D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openReceiveYarn,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Receive Yarn'),
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
          _YarnSummary(),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Yarn Stock',
            child: Column(
              children: [
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search yarn, count or type...',
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
                if (yarns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 42,
                          color: Color(0xFF53616D),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No yarn found',
                          style: TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _YarnTable(yarns: yarns),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardCard(
                title: 'Recent Yarn Movements',
                child: const Column(
              children: [
                _YarnMovementRow(
                  icon: Icons.south_west,
                  title: 'Yarn Received',
                  party: 'A.K. Goyal Hosiery',
                  details: 'Lot YR-260818-01 • 420 kg',
                  positive: true,
                ),
                _YarnMovementRow(
                  icon: Icons.north_east,
                  title: 'Yarn Issued',
                  party: 'Job BBJO-00128',
                  details: 'Polyester 75D • 180 kg',
                  positive: false,
                ),
                _YarnMovementRow(
                  icon: Icons.south_west,
                  title: 'Yarn Received',
                  party: 'Sandhir Textiles',
                  details: 'Lot YR-260817-04 • 310 kg',
                  positive: true,
                ),
                _YarnMovementRow(
                  icon: Icons.keyboard_return,
                  title: 'Yarn Returned',
                  party: 'Machine 18 / Job BBJO-00125',
                  details: 'Polyester 150D • 24 kg',
                  positive: true,
                ),
              ],
            ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all movements',
                    style: TextStyle(color: Color(0xFF00BFA6)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YarnSummary extends StatelessWidget {
  const _YarnSummary();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cards = [
          ('Total Yarn Stock', '5,480 kg', Icons.inventory_2_outlined),
          ('Active Lots', '22', Icons.layers_outlined),
          ('Received Today', '730 kg', Icons.south_west),
          ('Issued Today', '410 kg', Icons.north_east),
        ];

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
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _YarnStatCard(
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

class _YarnTable extends StatelessWidget {
  final List<_YarnItem> yarns;

  const _YarnTable({required this.yarns});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: yarns.map((yarn) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1D2933)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            '${yarn.type} • ${yarn.count} • ${yarn.lots} lots',
                            style: const TextStyle(
                              color: Color(0xFF71808D),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatKg(yarn.stock)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
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
                color: const Color(0xFF0F171E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Yarn',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Type',
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
                    flex: 2,
                    child: Text(
                      'Lots',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Stock',
                      style: _TableHeaderStyle.style,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(width: 42),
                ],
              ),
            ),
            ...yarns.map(
              (yarn) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1D2933)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0xFF153A38),
                            child: Icon(
                              Icons.all_inclusive,
                              color: Color(0xFF00BFA6),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              yarn.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        yarn.type,
                        style: const TextStyle(
                          color: Color(0xFF9BA7B2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        yarn.count,
                        style: const TextStyle(
                          color: Color(0xFF9BA7B2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${yarn.lots}',
                        style: const TextStyle(
                          color: Color(0xFF9BA7B2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_formatKg(yarn.stock)} kg',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Color(0xFF71808D),
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

  static String _formatKg(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _YarnItem {
  final String name;
  final String count;
  final String type;
  final double stock;
  final int lots;
  final String unit;

  const _YarnItem({
    required this.name,
    required this.count,
    required this.type,
    required this.stock,
    required this.lots,
    required this.unit,
  });
}

class _YarnMovementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String party;
  final String details;
  final bool positive;

  const _YarnMovementRow({
    required this.icon,
    required this.title,
    required this.party,
    required this.details,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1D2933)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (positive
                      ? const Color(0xFF00BFA6)
                      : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: positive
                  ? const Color(0xFF00BFA6)
                  : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  party,
                  style: const TextStyle(
                    color: Color(0xFF9BA7B2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            details,
            style: const TextStyle(
              color: Color(0xFF71808D),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveYarnDialog extends StatefulWidget {
  const _ReceiveYarnDialog();

  @override
  State<_ReceiveYarnDialog> createState() => _ReceiveYarnDialogState();
}

class _ReceiveYarnDialogState extends State<_ReceiveYarnDialog> {
  final _formKey = GlobalKey<FormState>();

  final _yarnController = TextEditingController();
  final _lotController = TextEditingController();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _remarksController = TextEditingController();

  String _source = 'Purchase';
  String _unit = 'kg';

  @override
  void dispose() {
    _yarnController.dispose();
    _lotController.dispose();
    _quantityController.dispose();
    _supplierController.dispose();
    _remarksController.dispose();
    super.dispose();
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
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 650,
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
                          'Receive Yarn',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create a yarn receipt and lot',
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
                                  initialValue: _source,
                                  decoration: _decoration('Receipt Source'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Purchase',
                                      child: Text('Purchase'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Customer',
                                      child: Text('Customer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Job Worker',
                                      child: Text('Job Worker'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Opening Stock',
                                      child: Text('Opening Stock'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _source = value);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _supplierController,
                                  decoration: _decoration(
                                    'Party / Supplier',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _yarnController,
                                  decoration: _decoration(
                                    'Yarn',
                                    hint: 'e.g. Polyester 75D',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Yarn is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _lotController,
                                  decoration: _decoration(
                                    'Lot Number',
                                    hint: 'e.g. YR-260818-01',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: _decoration('Quantity'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        double.tryParse(value) == null) {
                                      return 'Enter a valid quantity';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _unit,
                                  decoration: _decoration('Unit'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'kg',
                                      child: Text('Kilogram (kg)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cone',
                                      child: Text('Cone'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'box',
                                      child: Text('Box'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _unit = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _decoration(
                          'Remarks',
                          hint: 'Optional notes about this receipt',
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
                  FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Yarn receipt saved locally. Database linking comes next.',
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                    ),
                    child: const Text('Receive Yarn'),
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
            ],
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
