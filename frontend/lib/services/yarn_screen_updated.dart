import 'package:flutter/material.dart';

import '../services/api_service.dart';

class YarnPage extends StatefulWidget {
  const YarnPage({super.key});

  @override
  State<YarnPage> createState() => _YarnPageState();
}

class _YarnPageState extends State<YarnPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<YarnMaster> _yarns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadYarns();
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

  List<YarnMaster> get _filteredYarns {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _yarns;
    }

    return _yarns.where((yarn) {
      return yarn.code.toLowerCase().contains(query) ||
          yarn.name.toLowerCase().contains(query) ||
          yarn.count.toLowerCase().contains(query) ||
          yarn.composition.toLowerCase().contains(query) ||
          yarn.colour.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openYarnForm({YarnMaster? yarn}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _YarnFormDialog(
        api: _api,
        yarn: yarn,
        defaultCompanyId: yarn?.companyId ??
            (_yarns.isNotEmpty ? _yarns.first.companyId : null),
      ),
    );

    if (saved == true && mounted) {
      await _loadYarns();
    }
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
        const SnackBar(content: Text('Yarn deactivated')),
      );

      await _loadYarns();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
                      'Yarn master, lots and live stock',
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
                onPressed: _loading ? null : _loadYarns,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () => _openYarnForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Yarn'),
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
          _YarnSummary(count: _yarns.length),
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
                        'Search code, yarn, count, composition or colour...',
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
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _loadYarns,
                  )
                else if (yarns.isEmpty)
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
                  _YarnTable(
                    yarns: yarns,
                    onEdit: (yarn) => _openYarnForm(yarn: yarn),
                    onDeactivate: _deactivateYarn,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _DashboardCard(
            title: 'Recent Yarn Movements',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Yarn movement transactions will be connected next. '
                'Yarn Master data above is live from the database.',
                style: TextStyle(
                  color: Color(0xFF71808D),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YarnSummary extends StatelessWidget {
  final int count;

  const _YarnSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Active Yarn Masters', '$count', Icons.all_inclusive),
      ('Stock', '—', Icons.inventory_2_outlined),
      ('Active Lots', '—', Icons.layers_outlined),
      ('Today\'s Movements', '—', Icons.swap_vert),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = cards
            .map(
              (card) => _YarnStatCard(
                title: card.$1,
                value: card.$2,
                icon: card.$3,
              ),
            )
            .toList();

        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map(
                  (child) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: child,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                            '${yarn.code} • '
                            '${yarn.count.isEmpty ? 'No count' : yarn.count}',
                            style: const TextStyle(
                              color: Color(0xFF71808D),
                              fontSize: 11,
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
                      itemBuilder: (context) => const [
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
                color: const Color(0xFF0F171E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Code',
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Colour',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  SizedBox(width: 48),
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
                    _TableCell(
                      text: yarn.code,
                      flex: 2,
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
                    _TableCell(
                      text: yarn.count,
                      flex: 2,
                    ),
                    _TableCell(
                      text: yarn.composition,
                      flex: 3,
                    ),
                    _TableCell(
                      text: yarn.colour,
                      flex: 2,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(yarn);
                        } else if (value == 'deactivate') {
                          onDeactivate(yarn);
                        }
                      },
                      itemBuilder: (context) => const [
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final int flex;

  const _TableCell({
    required this.text,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.isEmpty ? '—' : text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF9BA7B2),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _YarnFormDialog extends StatefulWidget {
  final ApiService api;
  final YarnMaster? yarn;
  final int? defaultCompanyId;

  const _YarnFormDialog({
    required this.api,
    required this.yarn,
    required this.defaultCompanyId,
  });

  @override
  State<_YarnFormDialog> createState() => _YarnFormDialogState();
}

class _YarnFormDialogState extends State<_YarnFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyController;
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _typeController;
  late final TextEditingController _compositionController;
  late final TextEditingController _colourController;
  late final TextEditingController _unitController;
  late final TextEditingController _descriptionController;

  bool _saving = false;

  bool get _editing => widget.yarn != null;

  @override
  void initState() {
    super.initState();

    final yarn = widget.yarn;

    _companyController = TextEditingController(
      text: (yarn?.companyId ?? widget.defaultCompanyId)?.toString() ?? '',
    );
    _codeController = TextEditingController(text: yarn?.code ?? '');
    _nameController = TextEditingController(text: yarn?.name ?? '');
    _countController = TextEditingController(text: yarn?.count ?? '');
    _typeController = TextEditingController(
      text: yarn?.yarnTypeId?.toString() ?? '',
    );
    _compositionController = TextEditingController(
      text: yarn?.composition ?? '',
    );
    _colourController = TextEditingController(text: yarn?.colour ?? '');
    _unitController = TextEditingController(
      text: yarn?.unitId?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: yarn?.description ?? '',
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _countController.dispose();
    _typeController.dispose();
    _compositionController.dispose();
    _colourController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = int.tryParse(_companyController.text.trim());
    final yarnTypeId = _typeController.text.trim().isEmpty
        ? null
        : int.tryParse(_typeController.text.trim());
    final unitId = _unitController.text.trim().isEmpty
        ? null
        : int.tryParse(_unitController.text.trim());

    if (companyId == null || companyId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Company ID')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final count = _optional(_countController.text);
      final composition = _optional(_compositionController.text);
      final colour = _optional(_colourController.text);
      final description = _optional(_descriptionController.text);

      if (_editing) {
        await widget.api.updateYarn(
          id: widget.yarn!.id,
          companyId: companyId,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          count: count,
          yarnTypeId: yarnTypeId,
          composition: composition,
          colour: colour,
          unitId: unitId,
          description: description,
        );
      } else {
        await widget.api.createYarn(
          companyId: companyId,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          count: count,
          yarnTypeId: yarnTypeId,
          composition: composition,
          colour: colour,
          unitId: unitId,
          description: description,
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
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
                  Expanded(
                    child: Text(
                      _editing ? 'Edit Yarn' : 'Add Yarn',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
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
                            child: TextFormField(
                              controller: _companyController,
                              keyboardType: TextInputType.number,
                              decoration: _decoration('Company ID'),
                              validator: (value) {
                                if (int.tryParse(value?.trim() ?? '') ==
                                    null) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _codeController,
                              decoration: _decoration('Yarn Code'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Yarn code is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: _decoration('Yarn Name'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Yarn name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _countController,
                              decoration: _decoration(
                                'Count',
                                hint: '75D / 30s',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _typeController,
                              keyboardType: TextInputType.number,
                              decoration: _decoration('Yarn Type ID'),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _unitController,
                              keyboardType: TextInputType.number,
                              decoration: _decoration('Unit ID'),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _compositionController,
                              decoration: _decoration(
                                'Composition',
                                hint: '100% Polyester',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _colourController,
                              decoration: _decoration('Colour'),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: _decoration('Description'),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA6),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _editing ? 'Save Changes' : 'Add Yarn',
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
          const Text('Could not load Yarn Master'),
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
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Retry'),
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

class _TableHeaderStyle {
  static const style = TextStyle(
    color: Color(0xFF71808D),
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}
