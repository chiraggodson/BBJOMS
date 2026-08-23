import 'package:flutter/material.dart';
import 'services/api_service.dart';

const _bg = Color(0xFF0B1117);
const _panel = Color(0xFF111A22);
const _panel2 = Color(0xFF0F171E);
const _border = Color(0xFF1E2A34);
const _muted = Color(0xFF84919D);
const _teal = Color(0xFF00BFA6);

class FabricPage extends StatefulWidget {
  const FabricPage({super.key});

  @override
  State<FabricPage> createState() => _FabricPageState();
}

class _FabricPageState extends State<FabricPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController =
      TextEditingController();

  List<Fabric> _fabrics = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFabrics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFabrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fabrics = await _apiService.getFabrics();

      if (!mounted) return;

      setState(() {
        _fabrics = fabrics;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<Fabric> get _filteredFabrics {
    final query =
        _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _fabrics;
    }

    return _fabrics.where((fabric) {
      return fabric.name.toLowerCase().contains(query) ||
          fabric.fabricCode.toLowerCase().contains(query) ||
          fabric.composition.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _createFabric() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _FabricFormDialog(),
    );

    if (result == true) {
      await _loadFabrics();
    }
  }

  Future<void> _editFabric(Fabric fabric) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FabricFormDialog(
        fabric: fabric,
      ),
    );

    if (result == true) {
      await _loadFabrics();
    }
  }

  Future<void> _deactivateFabric(Fabric fabric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _panel,
          title: const Text('Deactivate Fabric'),
          content: Text(
            'Deactivate "${fabric.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF9B3A3A),
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _apiService.deactivateFabric(
        fabric.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fabric deactivated'),
        ),
      );

      await _loadFabrics();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to deactivate fabric: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fabrics = _filteredFabrics;

    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fabric',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Fabric master, specifications and active production',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _createFabric,
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                  ),
                  label:
                      const Text('New Fabric'),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final stats = [
                  _Stat(
                    'Fabric Types',
                    _fabrics.length.toString(),
                    Icons.layers_outlined,
                  ),
                  _Stat(
                    'Active',
                    _fabrics.length.toString(),
                    Icons.check_circle_outline,
                  ),
                ];

                if (constraints.maxWidth < 760) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stats
                        .map(
                          (stat) => SizedBox(
                            width:
                                (constraints.maxWidth -
                                        12) /
                                    2,
                            child: stat,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: stats
                      .map(
                        (stat) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(
                              right: 12,
                            ),
                            child: stat,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            _Card(
              title: 'Fabric Master',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration:
                        InputDecoration(
                      hintText:
                          'Search fabric, code or composition...',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                        size: 20,
                      ),
                      suffixIcon:
                          _searchController.text
                                  .isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController
                                        .clear();
                                    setState(() {});
                                  },
                                  icon:
                                      const Icon(
                                    Icons.clear,
                                    size: 18,
                                  ),
                                ),
                      filled: true,
                      fillColor: _panel2,
                      border:
                          _inputBorder(),
                      enabledBorder:
                          _inputBorder(),
                      focusedBorder:
                          _inputBorder(
                        _teal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_loading)
                    const Padding(
                      padding:
                          EdgeInsets.all(50),
                      child:
                          CircularProgressIndicator(
                        color: _teal,
                      ),
                    )
                  else if (_error != null)
                    _ErrorState(
                      message: _error!,
                      onRetry: _loadFabrics,
                    )
                  else if (fabrics.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.all(50),
                      child: Column(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 42,
                            color:
                                Color(0xFF53616D),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No fabrics found',
                            style: TextStyle(
                              color:
                                  Color(0xFF9BA7B2),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Click New Fabric to create one.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _FabricTable(
                      fabrics: fabrics,
                      onEdit: _editFabric,
                      onDeactivate:
                          _deactivateFabric,
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

// ============================================================
// FABRIC FORM
// ============================================================

class _FabricFormDialog extends StatefulWidget {
  final Fabric? fabric;

  const _FabricFormDialog({
    this.fabric,
  });

  @override
  State<_FabricFormDialog> createState() =>
      _FabricFormDialogState();
}

class _FabricFormDialogState
    extends State<_FabricFormDialog> {
  final ApiService _apiService = ApiService();

  late final TextEditingController
      _codeController;
  late final TextEditingController
      _nameController;
  late final TextEditingController
      _descriptionController;
  late final TextEditingController
      _gsmController;
  late final TextEditingController
      _compositionController;
  late final TextEditingController
      _widthController;

  bool _saving = false;

  bool get _editing => widget.fabric != null;

  @override
  void initState() {
    super.initState();

    final fabric = widget.fabric;

    _codeController = TextEditingController(
      text: fabric?.fabricCode ?? '',
    );

    _nameController = TextEditingController(
      text: fabric?.name ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: fabric?.description ?? '',
    );

    _gsmController = TextEditingController(
      text: fabric?.gsm?.toString() ?? '',
    );

    _compositionController =
        TextEditingController(
      text: fabric?.composition ?? '',
    );

    _widthController = TextEditingController(
      text: fabric?.widthInches?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _gsmController.dispose();
    _compositionController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code =
        _codeController.text.trim();
    final name =
        _nameController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Fabric code and name are required',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final gsm = double.tryParse(
        _gsmController.text.trim(),
      );

      final width = double.tryParse(
        _widthController.text.trim(),
      );

      if (_editing) {
        await _apiService.updateFabric(
          id: widget.fabric!.id,
          fabricCode: code,
          name: name,
          description:
              _descriptionController.text.trim(),
          gsm: gsm,
          composition:
              _compositionController.text.trim(),
          widthInches: width,
          isActive: true,
        );
      } else {
        await _apiService.createFabric(
          fabricCode: code,
          name: name,
          description:
              _descriptionController.text.trim(),
          gsm: gsm,
          composition:
              _compositionController.text.trim(),
          widthInches: width,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save fabric: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _panel,
      title: Text(
        _editing
            ? 'Edit Fabric'
            : 'New Fabric',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _FormField(
                controller: _codeController,
                label: 'Fabric Code *',
                hint: 'e.g. SJ-180',
              ),
              const SizedBox(height: 14),
              _FormField(
                controller: _nameController,
                label: 'Fabric Name *',
                hint: 'e.g. Single Jersey 180 GSM',
              ),
              const SizedBox(height: 14),
              _FormField(
                controller:
                    _descriptionController,
                label: 'Description',
                hint: 'Optional',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _gsmController,
                      label: 'GSM',
                      hint: '180',
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      controller:
                          _widthController,
                      label: 'Width (inches)',
                      hint: '72',
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormField(
                controller:
                    _compositionController,
                label: 'Composition',
                hint: 'e.g. 100% Cotton',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () =>
                  Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _editing
                      ? 'Update'
                      : 'Create',
                ),
        ),
      ],
    );
  }
}

// ============================================================
// FABRIC TABLE
// ============================================================

class _FabricTable extends StatelessWidget {
  final List<Fabric> fabrics;
  final Future<void> Function(Fabric)
      onEdit;
  final Future<void> Function(Fabric)
      onDeactivate;

  const _FabricTable({
    required this.fabrics,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: fabrics.map((fabric) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                decoration:
                    const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Color(0xFF1D2933),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            fabric.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fabric.fabricCode,
                            style:
                                const TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fabric.gsm ?? '—'} GSM • ${fabric.composition.isEmpty ? '—' : fabric.composition}',
                            style:
                                const TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(fabric);
                        } else if (value ==
                            'deactivate') {
                          onDeactivate(
                            fabric,
                          );
                        }
                      },
                      itemBuilder:
                          (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text(
                            'Deactivate',
                          ),
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
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _panel2,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Fabric',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Code',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'GSM',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Composition',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Width',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  SizedBox(width: 80),
                ],
              ),
            ),
            ...fabrics.map(
              (fabric) => Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration:
                    const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Color(0xFF1D2933),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        fabric.name,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        fabric.fabricCode,
                        style:
                            const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        fabric.gsm == null
                            ? '—'
                            : '${fabric.gsm}',
                        style:
                            const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        fabric.composition
                                .isEmpty
                            ? '—'
                            : fabric.composition,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        fabric.widthInches ==
                                null
                            ? '—'
                            : '${fabric.widthInches}"',
                        style:
                            const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () =>
                                onEdit(fabric),
                            icon:
                                const Icon(
                              Icons.edit_outlined,
                              size: 17,
                              color: _muted,
                            ),
                          ),
                          IconButton(
                            tooltip:
                                'Deactivate',
                            onPressed: () =>
                                onDeactivate(
                              fabric,
                            ),
                            icon:
                                const Icon(
                              Icons
                                  .more_horiz,
                              size: 18,
                              color: _muted,
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

// ============================================================
// FORM FIELD
// ============================================================

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _panel2,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(_teal),
      ),
    );
  }
}

// ============================================================
// CARD
// ============================================================

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// STAT
// ============================================================

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(
    this.title,
    this.value,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _teal.withValues(
                alpha: .12,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _teal,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

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
      padding:
          const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFFB66A6A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load fabrics',
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
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TABLE HEADER
// ============================================================

class _TableHeaderStyle {
  static const style = TextStyle(
    color: _muted,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}

// ============================================================
// INPUT BORDER
// ============================================================

OutlineInputBorder _inputBorder([
  Color color = const Color(0xFF25313B),
]) {
  return OutlineInputBorder(
    borderRadius:
        BorderRadius.circular(9),
    borderSide:
        BorderSide(color: color),
  );
}