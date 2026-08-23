import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.29.6:4000/api';

  Future<List<Party>> getParties({
    String? search,
    String? role,
    bool? active,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (role != null && role.trim().isNotEmpty) {
      queryParameters['role'] = role.trim();
    }

    if (active != null) {
      queryParameters['active'] = active.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/parties',
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load parties',
        response.statusCode,
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to load parties',
        response.statusCode,
      );
    }

    final parties =
        data['parties'] as List<dynamic>? ?? [];

    return parties
        .map(
          (party) => Party.fromJson(
            party as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Party> getParty(int id) async {
    final uri = Uri.parse(
      '$baseUrl/parties/$id',
    );

    final response = await http.get(uri);

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to load party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      data['party'] as Map<String, dynamic>,
    );
  }

  Future<PartyStats> getPartyStats() async {
    final uri = Uri.parse(
      '$baseUrl/parties/stats',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load party statistics',
        response.statusCode,
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to load party statistics',
        response.statusCode,
      );
    }

    return PartyStats.fromJson(
      data['stats'] as Map<String, dynamic>,
    );
  }

  Future<Party> createParty({
    required String name,
    String? alias,
    String? gstin,
    String? pan,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pinCode,
    String? country,
    String? contactPerson,
    String? phone,
    String? email,
    required List<String> roles,
    bool isActive = true,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/parties',
    );

    final body = <String, dynamic>{
      'name': name,
      'alias': alias,
      'gstin': gstin,
      'pan': pan,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'country': country ?? 'India',
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'roles': roles,
      'is_active': isActive,
      'notes': notes,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 ||
        data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to create party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      data['party'] as Map<String, dynamic>,
    );
  }

  Future<Party> updateParty({
    required int id,
    required String name,
    String? alias,
    String? gstin,
    String? pan,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pinCode,
    String? country,
    String? contactPerson,
    String? phone,
    String? email,
    required List<String> roles,
    bool isActive = true,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/parties/$id',
    );

    final body = <String, dynamic>{
      'name': name,
      'alias': alias,
      'gstin': gstin,
      'pan': pan,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'pin_code': pinCode,
      'country': country ?? 'India',
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'roles': roles,
      'is_active': isActive,
      'notes': notes,
    };

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to update party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      data['party'] as Map<String, dynamic>,
    );
  }

  Future<void> deactivateParty(int id) async {
    final uri = Uri.parse(
      '$baseUrl/parties/$id',
    );

    final response = await http.delete(uri);

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ??
            'Failed to deactivate party',
        response.statusCode,
      );
    }
  }
}

class Party {
  final int id;
  final String partyCode;
  final String name;
  final String alias;
  final String gstin;
  final String pan;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final String contactPerson;
  final String phone;
  final String email;
  final bool isActive;
  final String notes;
  final List<String> roles;

  const Party({
    required this.id,
    required this.partyCode,
    required this.name,
    required this.alias,
    required this.gstin,
    required this.pan,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.country,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.notes,
    required this.roles,
  });

  factory Party.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawRoles =
        json['roles'] as List<dynamic>? ?? [];

    return Party(
      id: _toInt(json['id']),
      partyCode:
          json['party_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      addressLine1:
          json['address_line1']?.toString() ?? '',
      addressLine2:
          json['address_line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pinCode:
          json['pin_code']?.toString() ?? '',
      country:
          json['country']?.toString() ?? 'India',
      contactPerson:
          json['contact_person']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString() ?? '',
      roles: rawRoles
          .map(
            (role) => role.toString(),
          )
          .toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class PartyStats {
  final int totalParties;
  final int activeParties;
  final int inactiveParties;
  final int customers;
  final int yarnSuppliers;
  final int jobWorkers;
  final int fabricBuyers;

  const PartyStats({
    required this.totalParties,
    required this.activeParties,
    required this.inactiveParties,
    required this.customers,
    required this.yarnSuppliers,
    required this.jobWorkers,
    required this.fabricBuyers,
  });

  factory PartyStats.fromJson(
    Map<String, dynamic> json,
  ) {
    return PartyStats(
      totalParties:
          _toInt(json['total_parties']),
      activeParties:
          _toInt(json['active_parties']),
      inactiveParties:
          _toInt(json['inactive_parties']),
      customers:
          _toInt(json['customers']),
      yarnSuppliers:
          _toInt(json['yarn_suppliers']),
      jobWorkers:
          _toInt(json['job_workers']),
      fabricBuyers:
          _toInt(json['fabric_buyers']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(
    this.message,
    this.statusCode,
  );

  @override
  String toString() {
    return '$message (HTTP $statusCode)';
  }
}