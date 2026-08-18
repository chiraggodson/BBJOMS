import 'package:flutter/material.dart';

class PartiesPage extends StatefulWidget {
  const PartiesPage({super.key});

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_Party> _parties = [
    _Party(
      name: 'B&B KNIT FAB',
      roles: ['Customer', 'Job Worker'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'A.D CLOTHING',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03ABKFA8325H...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'A.K.GOYAL HOSIERY',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03ABKPG4650H...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'AARADHYA CREATIONS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AQRPA0412D...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'ADAM KNITS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AKFPJ4824Q...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'AMIT ENTERPRISES',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AAJFA2975L...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'ANKUSH KNITS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AAVCA0500F...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'ANSH FABRICS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03ADHPA8268...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'BANI FABRICS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03ABLPT5283C...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'BHARTI FABRICS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03ABNPJ3788Q...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'B.D.S CLOTHING',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AAJFB5116N...',
      phone: '',
      contact: '',
    ),
    _Party(
      name: 'CHARLEY KNITS',
      roles: ['Customer'],
      city: 'Ludhiana',
      state: 'Punjab',
      gstin: '03AABCC2212...',
      phone: '9814085399',
      contact: '',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Party> get _filteredParties {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _parties;

    return _parties.where((party) {
      return party.name.toLowerCase().contains(query) ||
          party.city.toLowerCase().contains(query) ||
          party.roles.any((role) => role.toLowerCase().contains(query));
    }).toList();
  }

  void _openPartyForm() {
    showDialog<void>(
      context: context,
      builder: (_) => const _PartyFormDialog(),
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
          _PartySummary(),
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
                if (parties.isEmpty)
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
  const _PartySummary();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = const [
          ('Total Parties', '136', Icons.people_outline),
          ('Customers', '98', Icons.storefront_outlined),
          ('Job Workers', '21', Icons.precision_manufacturing_outlined),
          ('Suppliers', '17', Icons.local_shipping_outlined),
        ];

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

class _PartyTable extends StatelessWidget {
  final List<_Party> parties;

  const _PartyTable({required this.parties});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        if (compact) {
          return Column(
            children: parties.map((party) {
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
                        Icons.business_outlined,
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
                            party.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${party.city.isEmpty ? '—' : party.city} • ${party.roles.join(', ')}',
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
                              Icons.business_outlined,
                              color: Color(0xFF00BFA6),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              party.name,
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
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: party.roles
                            .map((role) => _RoleChip(role: role))
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
                        party.gstin.isEmpty ? '—' : party.gstin,
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

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA6).withValues(alpha: 0.10),
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

class _Party {
  final String name;
  final List<String> roles;
  final String city;
  final String state;
  final String gstin;
  final String phone;
  final String contact;

  const _Party({
    required this.name,
    required this.roles,
    required this.city,
    required this.state,
    required this.gstin,
    required this.phone,
    required this.contact,
  });
}

class _PartyFormDialog extends StatefulWidget {
  const _PartyFormDialog();

  @override
  State<_PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends State<_PartyFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _gstinController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final Set<String> _roles = {'Customer'};

  static const _availableRoles = [
    'Customer',
    'Yarn Supplier',
    'Job Worker',
    'Processor',
    'Other',
  ];

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _aliasController,
      _gstinController,
      _address1Controller,
      _address2Controller,
      _cityController,
      _stateController,
      _pinController,
      _contactController,
      _phoneController,
      _emailController,
    ]) {
      controller.dispose();
    }
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
          maxWidth: 900,
          maxHeight: 760,
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
                      const _FormSectionTitle(
                        title: 'Basic Information',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: _decoration('Party Name *'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Party name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _aliasController,
                        decoration: _decoration('Print Alias'),
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
                          final selected = _roles.contains(role);
                          return FilterChip(
                            label: Text(role),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _roles.add(role);
                                } else {
                                  _roles.remove(role);
                                }
                              });
                            },
                            selectedColor:
                                const Color(0xFF00BFA6).withValues(alpha: 0.18),
                            checkmarkColor: const Color(0xFF00BFA6),
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
                      TextFormField(
                        controller: _gstinController,
                        decoration: _decoration('GSTIN'),
                      ),
                      const SizedBox(height: 24),
                      const _FormSectionTitle(
                        title: 'Address',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns = constraints.maxWidth > 650;
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
                                  controller: _address1Controller,
                                  decoration: _decoration('Address Line 1'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _address2Controller,
                                  decoration: _decoration('Address Line 2'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: _decoration('City'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _stateController,
                                  decoration: _decoration('State'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _pinController,
                                  decoration: _decoration('PIN Code'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  initialValue: 'India',
                                  decoration: _decoration('Country'),
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
                          final twoColumns = constraints.maxWidth > 650;
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
                                  controller: _contactController,
                                  decoration: _decoration('Contact Person'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _phoneController,
                                  decoration: _decoration('Contact Number'),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: _decoration('Email'),
                                  keyboardType: TextInputType.emailAddress,
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
                            'Party saved locally. Database linking comes next.',
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
                    child: const Text('Save Party'),
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
