import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/api_service.dart';

const _bg = Color(0xFF0B1117);
const _panel = Color(0xFF111A22);
const _panel2 = Color(0xFF0F171E);
const _border = Color(0xFF1E2A34);
const _muted = Color(0xFF84919D);
const _teal = Color(0xFF00BFA6);

class AddMachinePage extends StatefulWidget {
  final Machine? machine;

  const AddMachinePage({
    super.key,
    this.machine,
  });

  bool get isEditing => machine != null;

  @override
  State<AddMachinePage> createState() => _AddMachinePageState();
}

class _AddMachinePageState extends State<AddMachinePage> {
  static const String _baseUrl = 'http://192.168.1.20:4000/api';

  final _formKey = GlobalKey<FormState>();

  final _machineNoController = TextEditingController();
  final _rpmController = TextEditingController();
  final _counterController = TextEditingController();
  final _rollSizeController = TextEditingController();
  final _kgPerHourController = TextEditingController();

  String _status = 'idle';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final machine = widget.machine;

    if (machine != null) {
      _machineNoController.text = machine.machineNo;
      _rpmController.text = _formatNumber(machine.rpm);
      _counterController.text = _formatNumber(machine.counter);
      _rollSizeController.text = _formatNumber(machine.rollSize);
      _kgPerHourController.text = _formatNumber(machine.kgPerHour);

      final validStatuses = {
        'idle',
        'running',
        'maintenance',
        'stopped',
      };

      final normalizedStatus = machine.status.trim().toLowerCase();

      _status = validStatuses.contains(normalizedStatus)
          ? normalizedStatus
          : 'idle';
    }
  }

  @override
  void dispose() {
    _machineNoController.dispose();
    _rpmController.dispose();
    _counterController.dispose();
    _rollSizeController.dispose();
    _kgPerHourController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final body = {
      'machine_no': _machineNoController.text.trim(),
      'status': _status,
      'rpm': double.tryParse(_rpmController.text.trim()) ?? 0,
      'counter': double.tryParse(_counterController.text.trim()) ?? 0,
      'roll_size': double.tryParse(_rollSizeController.text.trim()) ?? 0,
    };

    try {
      final bool editing = widget.machine != null;

      final Uri uri = editing
          ? Uri.parse(
              '$_baseUrl/machines/${widget.machine!.id}',
            )
          : Uri.parse('$_baseUrl/machines');

      final response = await (editing
              ? http.put(
                  uri,
                  headers: const {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                  body: jsonEncode(body),
                )
              : http.post(
                  uri,
                  headers: const {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                  body: jsonEncode(body),
                ))
          .timeout(const Duration(seconds: 15));

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          _errorFromResponse(
            decoded,
            response.statusCode,
            response.body,
            editing,
          ),
        );
      }

      if (decoded is Map && decoded['success'] == false) {
        throw Exception(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'The server rejected the machine.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? 'Machine updated successfully.'
                : 'Machine added successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      final message =
          e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  String _errorFromResponse(
    dynamic decoded,
    int statusCode,
    String rawBody,
    bool editing,
  ) {
    if (decoded is Map) {
      final error =
          decoded['error'] ?? decoded['message'];

      if (error != null &&
          error.toString().trim().isNotEmpty) {
        return error.toString();
      }
    }

    final action = editing ? 'update' : 'add';

    if (rawBody.trim().isNotEmpty) {
      return 'Failed to $action machine '
          '(HTTP $statusCode): ${rawBody.trim()}';
    }

    return 'Failed to $action machine '
        '(HTTP $statusCode).';
  }

  InputDecoration _decoration(
    String label, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon == null ? null : Icon(icon, size: 19),
      filled: true,
      fillColor: _panel2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide:
            const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide:
            const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide:
            const BorderSide(color: _teal),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: _decoration(
        label,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _panel,
        elevation: 0,
        title: Text(
          editing ? 'Edit Machine' : 'Add Machine',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing
                          ? 'Edit Machine'
                          : 'Machine Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      editing
                          ? 'Update the machine master information.'
                          : 'Enter the machine master information.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),

                    TextFormField(
                      controller:
                          _machineNoController,
                      decoration: _decoration(
                        'Machine No.',
                        icon: Icons
                            .precision_manufacturing_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Machine No. is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _decoration(
                        'Status',
                        icon:
                            Icons.circle_outlined,
                      ),
                      dropdownColor: _panel,
                      items: const [
                        DropdownMenuItem(
                          value: 'idle',
                          child: Text('Idle'),
                        ),
                        DropdownMenuItem(
                          value: 'running',
                          child: Text('Running'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child:
                              Text('Maintenance'),
                        ),
                        DropdownMenuItem(
                          value: 'stopped',
                          child: Text('Stopped'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(
                                  () => _status = value,
                                );
                              }
                            },
                    ),

                    const SizedBox(height: 14),

                    LayoutBuilder(
                      builder:
                          (context, constraints) {
                        final fields = [
                          _numberField(
                            _rpmController,
                            'RPM',
                            Icons.speed_outlined,
                          ),
                          _numberField(
                            _kgPerHourController,
                            'Kg / Hour',
                            Icons.scale_outlined,
                          ),
                          _numberField(
                            _rollSizeController,
                            'Roll Size (kg)',
                            Icons.inventory_2_outlined,
                          ),
                          _numberField(
                            _counterController,
                            'Counter',
                            Icons.calculate_outlined,
                          ),
                        ];

                        if (constraints.maxWidth <
                            560) {
                          return Column(
                            children: [
                              for (
                                int i = 0;
                                i < fields.length;
                                i++
                              ) ...[
                                fields[i],
                                if (i <
                                    fields.length - 1)
                                  const SizedBox(
                                    height: 14,
                                  ),
                              ],
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: fields[0],
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Expanded(
                                  child: fields[1],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: fields[2],
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Expanded(
                                  child: fields[3],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                    const Divider(color: _border),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(
                                    context,
                                  ).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed:
                              _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            _saving
                                ? 'Saving...'
                                : editing
                                    ? 'Save Changes'
                                    : 'Save Machine',
                          ),
                          style:
                              FilledButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor:
                                Colors.black,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}