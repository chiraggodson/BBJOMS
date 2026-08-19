import 'package:flutter/material.dart';

import 'services/api_service.dart';

class PartiesPage extends StatefulWidget {
  const PartiesPage({super.key});

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Party> _parties = [];
  PartyStats? _stats;

  bool _loading = true;
  bool _loadingStats = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParties();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final parties = await _apiService.getParties(
        active: true,
      );

      if (!mounted) return;

      setState(() {
        _parties = parties;
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

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.getPartyStats();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadParties(),
      _loadStats(),
    ]);
  }

  List<Party> get _filteredParties {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _parties;
    }

    return _parties.where((party) {
      return party.name.toLowerCase().contains(query) ||
          party.partyCode.toLowerCase().contains(query) ||
          party.city.toLowerCase().contains(query) ||
          party.gstin.toLowerCase().contains(query) ||
          party.phone.toLowerCase().contains(query) ||
          party.roles.any(
            (role) => role.toLowerCase().contains(query),
          );
    }).toList();
  }

  Future<void> _openPartyForm() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _PartyFormDialog(),
    );

    if (saved == true) {
      await _refresh();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7A2525),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parties = _filteredParties;

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
                      'Parties',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Customers, suppliers, job workers and other business parties',
                      style: TextStyle(
                        color: Color(0xFF84919D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openPartyForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Party'),
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
          _PartySummary(
            stats: _stats,
            loading: _loadingStats,
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Party Master',
            child: Column(
              children: [
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search party, city or role...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                            ),
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
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BFA6),
                    ),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _refresh,
                  )
                else if (parties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 42,
                          color: Color(0xFF53616D),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No parties found',
                          style: TextStyle(
                            color: Color(0xFF9BA7B2),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create your first party using New Party.',
                          style: TextStyle(
                            color: Color(0xFF53616D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _PartyTable(parties: parties),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartySummary extends StatelessWidget {
  final PartyStats? stats;
  final bool loading;

  const _PartySummary({
    required this.stats,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Total Parties',
        loading ? '—' : '${stats?.totalParties ?? 0}',
        Icons.people_outline,
      ),
      (
        'Customers',
        loading ? '—' : '${stats?.customers ?? 0}',
        Icons.storefront_outlined,
      ),
      (
        'Job Workers',
        loading ? '—' : '${stats?.jobWorkers ?? 0}',
        Icons.precision_manufacturing_outlined,
      ),
      (
        'Yarn Suppliers',
        loading ? '—' : '${stats?.yarnSuppliers ?? 0}',
        Icons.local_shipping_outlined,
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
                child: _PartyStatCard(
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
                    child: _PartyStatCard(
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

class _PartyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _PartyStatCard({
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
        border: Border.all(
          color: const Color(0xFF1E2A34),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6).withValues(
                alpha: 0.12,
              ),
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

class _PartyTable extends StatelessWidget {
  final List<Party> parties;

  const _PartyTable({
    required this.parties,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        if (compact) {
          return Column(
            children: parties.map((party) {
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
                        Icons.business_outlined,
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
                            party.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${party.partyCode} • '
                            '${party.city.isEmpty ? '—' : party.city} • '
                            '${party.roles.join(', ')}',
                            style: const TextStyle(
                              color: Color(0xFF71808D),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF53616D),
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
                      'Party',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Role',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'City',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'GSTIN',
                      style: _TableHeaderStyle.style,
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            ...parties.map(
              (party) => Container(
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
                      flex: 3,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0xFF153A38),
                            child: Icon(
                              Icons.business_outlined,
                              color: Color(0xFF00BFA6),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  party.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  party.partyCode,
                                  style: const TextStyle(
                                    color: Color(0xFF53616D),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: party.roles
                            .map(
                              (role) => _RoleChip(
                                role: role,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        party.city.isEmpty ? '—' : party.city,
                        style: const TextStyle(
                          color: Color(0xFF9BA7B2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        party.gstin.isEmpty
                            ? '—'
                            : party.gstin,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF71808D),
                          fontSize: 11,
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
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA6).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFF62D9C9),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
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

class _PartyFormDialog extends StatefulWidget {
  const _PartyFormDialog();

  @override
  State<_PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<_PartyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  final Set<String> _roles = {'Customer'};

  bool _saving = false;

  static const _availableRoles = [
    'Customer',
    'Yarn Supplier',
    'Job Worker',
    'Processor',
    'Fabric Buyer',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
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
      fillColor: const Color(0xFF0F171E),
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

  String? _clean(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one party role.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _apiService.createParty(
        name: _nameController.text.trim(),
        alias: _clean(_aliasController.text),
        gstin: _clean(_gstinController.text),
        pan: _clean(_panController.text),
        addressLine1: _clean(_address1Controller.text),
        addressLine2: _clean(_address2Controller.text),
        city: _clean(_cityController.text),
        state: _clean(_stateController.text),
        pinCode: _clean(_pinController.text),
        country: 'India',
        contactPerson: _clean(_contactController.text),
        phone: _clean(_phoneController.text),
        email: _clean(_emailController.text),
        roles: _roles.toList(),
        isActive: true,
        notes: _clean(_notesController.text),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Party saved successfully.',
          ),
          backgroundColor: Color(0xFF087F6B),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save party: $error',
          ),
          backgroundColor: const Color(0xFF7A2525),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111A22),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 780,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Party',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create a business party and assign its roles',
                          style: TextStyle(
                            color: Color(0xFF71808D),
                            fontSize: 11,
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
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const _FormSectionTitle(
                        title: 'Basic Information',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            _decoration('Party Name *'),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Party name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _aliasController,
                        decoration:
                            _decoration('Print Alias'),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Party Roles',
                        style: TextStyle(
                          color: Color(0xFF9BA7B2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableRoles.map((role) {
                          final selected =
                              _roles.contains(role);

                          return FilterChip(
                            label: Text(role),
                            selected: selected,
                            onSelected: _saving
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value) {
                                        _roles.add(role);
                                      } else {
                                        _roles.remove(role);
                                      }
                                    });
                                  },
                            selectedColor:
                                const Color(0xFF00BFA6)
                                    .withValues(alpha: 0.18),
                            checkmarkColor:
                                const Color(0xFF00BFA6),
                            side: const BorderSide(
                              color: Color(0xFF25313B),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const _FormSectionTitle(
                        title: 'Tax & Registration',
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns =
                              constraints.maxWidth > 650;

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
                                  controller:
                                      _gstinController,
                                  decoration:
                                      _decoration('GSTIN'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _panController,
                                  decoration:
                                      _decoration('PAN'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _FormSectionTitle(
                        title: 'Address',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns =
                              constraints.maxWidth > 650;

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
                                  controller:
                                      _address1Controller,
                                  decoration: _decoration(
                                    'Address Line 1',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _address2Controller,
                                  decoration: _decoration(
                                    'Address Line 2',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _cityController,
                                  decoration:
                                      _decoration('City'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _stateController,
                                  decoration:
                                      _decoration('State'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _pinController,
                                  decoration:
                                      _decoration('PIN Code'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  initialValue: 'India',
                                  decoration:
                                      _decoration('Country'),
                                  enabled: false,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _FormSectionTitle(
                        title: 'Contact',
                        icon: Icons.contact_phone_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns =
                              constraints.maxWidth > 650;

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
                                  controller:
                                      _contactController,
                                  decoration: _decoration(
                                    'Contact Person',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _phoneController,
                                  decoration: _decoration(
                                    'Contact Number',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _emailController,
                                  decoration:
                                      _decoration('Email'),
                                  keyboardType:
                                      TextInputType.emailAddress,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller:
                                      _notesController,
                                  decoration:
                                      _decoration('Notes'),
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
                    onPressed:
                        _saving ? null : _saveParty,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF00BFA6),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
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
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Party'),
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

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FormSectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF00BFA6),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFFB66A6A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load parties',
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
              color: Color(0xFF71808D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}