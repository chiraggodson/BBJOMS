import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.29.6:4000/api';

  // ============================================================
  // PARTIES
  // ============================================================

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

    final uri = Uri.parse('$baseUrl/parties').replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load parties',
        response.statusCode,
      );
    }

    final data = _decodeMap(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to load parties',
        response.statusCode,
      );
    }

    final parties = data['parties'] as List<dynamic>? ?? [];

    return parties
        .map(
          (party) => Party.fromJson(
            Map<String, dynamic>.from(party as Map),
          ),
        )
        .toList();
  }

  Future<Party> getParty(int id) async {
    final uri = Uri.parse('$baseUrl/parties/$id');

    final response = await http.get(uri);
    final data = _decodeMap(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to load party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      Map<String, dynamic>.from(data['party'] as Map),
    );
  }

  Future<PartyStats> getPartyStats() async {
    final uri = Uri.parse('$baseUrl/parties/stats');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load party statistics',
        response.statusCode,
      );
    }

    final data = _decodeMap(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to load party statistics',
        response.statusCode,
      );
    }

    return PartyStats.fromJson(
      Map<String, dynamic>.from(data['stats'] as Map),
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
    final uri = Uri.parse('$baseUrl/parties');

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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _decodeMap(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to create party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      Map<String, dynamic>.from(data['party'] as Map),
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
    final uri = Uri.parse('$baseUrl/parties/$id');

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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _decodeMap(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to update party',
        response.statusCode,
      );
    }

    return Party.fromJson(
      Map<String, dynamic>.from(data['party'] as Map),
    );
  }

  Future<void> deactivateParty(int id) async {
    final uri = Uri.parse('$baseUrl/parties/$id');

    final response = await http.delete(uri);
    final data = _decodeMap(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to deactivate party',
        response.statusCode,
      );
    }
  }

  // ============================================================
  // FABRICS
  // ============================================================

  Future<List<Fabric>> getFabrics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fabrics'),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load fabrics',
        response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw ApiException(
        _extractError(decoded, 'Failed to load fabrics'),
        response.statusCode,
      );
    }

    return decoded
        .map(
          (item) => Fabric.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ============================================================
  // MACHINES
  // ============================================================

  Future<List<Machine>> getMachines() async {
    final response = await http.get(
      Uri.parse('$baseUrl/machines'),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load machines',
        response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw ApiException(
        _extractError(decoded, 'Failed to load machines'),
        response.statusCode,
      );
    }

    return decoded
        .map(
          (item) => Machine.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ============================================================
  // YARNS
  // ============================================================

  Future<List<YarnMaster>> getYarns() async {
    final response = await http.get(
      Uri.parse('$baseUrl/yarns'),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load yarns',
        response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw ApiException(
        _extractError(decoded, 'Failed to load yarns'),
        response.statusCode,
      );
    }

    return decoded
        .map(
          (item) => YarnMaster.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ============================================================
  // JOB ORDERS
  // ============================================================

  Future<List<JobOrder>> getJobs({
    String? search,
    String? status,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (status != null &&
        status.trim().isNotEmpty &&
        status.trim().toLowerCase() != 'all') {
      queryParameters['status'] = status.trim();
    }

    final uri = Uri.parse('$baseUrl/jobs').replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load job orders',
        response.statusCode,
      );
    }

    /*
     * IMPORTANT:
     *
     * Backend response is:
     *
     * {
     *   "success": true,
     *   "jobs": []
     * }
     *
     * NOT:
     *
     * [
     *   {...}
     * ]
     *
     * Therefore we must decode the Map first and then read
     * data['jobs'].
     */
    final data = _decodeMap(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Failed to load job orders',
        response.statusCode,
      );
    }

    final rawJobs = data['jobs'];

    if (rawJobs == null) {
      return [];
    }

    if (rawJobs is! List) {
      throw ApiException(
        'Invalid jobs response from server',
        response.statusCode,
      );
    }

    final jobs = rawJobs
        .whereType<Map>()
        .map(
          (item) => JobOrder.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    /*
     * Local filtering is retained as a safety net.
     * The backend can also filter using query parameters.
     */

    final searchText = search?.trim().toLowerCase() ?? '';
    final statusText = status?.trim().toLowerCase() ?? '';

    var filteredJobs = jobs;

    if (searchText.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        return job.jobNo.toLowerCase().contains(searchText) ||
            job.partyName.toLowerCase().contains(searchText) ||
            job.fabricName.toLowerCase().contains(searchText) ||
            job.machineNo.toLowerCase().contains(searchText) ||
            job.status.toLowerCase().contains(searchText) ||
            job.gsm.toString().contains(searchText);
      }).toList();
    }

    if (statusText.isNotEmpty && statusText != 'all') {
      filteredJobs = filteredJobs
          .where(
            (job) => job.status.toLowerCase() == statusText,
          )
          .toList();
    }

    return filteredJobs;
  }

  // ============================================================
  // GET ONE JOB
  // ============================================================

  Future<JobOrder> getJob(String jobNo) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobNo'),
    );

    final decoded = _tryDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(decoded, 'Failed to load job'),
        response.statusCode,
      );
    }

    if (decoded is Map &&
        decoded['success'] == true &&
        decoded['job'] is Map) {
      return JobOrder.fromJson(
        Map<String, dynamic>.from(decoded['job'] as Map),
      );
    }

    if (decoded is Map) {
      return JobOrder.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    }

    throw ApiException(
      'Invalid job response',
      response.statusCode,
    );
  }

  // ============================================================
  // JOB DETAILS
  // ============================================================

  Future<JobDetails> getJobDetails(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/details/$id'),
    );

    final decoded = _tryDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(decoded, 'Failed to load job details'),
        response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw ApiException(
        'Invalid job details response',
        response.statusCode,
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    if (data['success'] == true && data['job'] is Map) {
      final jobData = Map<String, dynamic>.from(
        data['job'] as Map,
      );

      if (data['machines'] is List) {
        jobData['machines'] = data['machines'];
      }

      if (data['yarns'] is List) {
        jobData['yarns'] = data['yarns'];
      }

      return JobDetails.fromJson(jobData);
    }

    return JobDetails.fromJson(data);
  }

  // ============================================================
  // CREATE JOB
  // ============================================================

  Future<List<String>> createJob({
    required int partyId,
    required int fabricId,
    required double gsm,
    required double orderQuantity,
    required List<int> machineIds,
    List<JobYarnRequirement> yarns = const [],
  }) async {
    if (machineIds.isEmpty) {
      throw const ApiException(
        'Select at least one machine',
        400,
      );
    }

    final uri = Uri.parse('$baseUrl/jobs');

    final body = <String, dynamic>{
      'party_id': partyId,
      'fabric_id': fabricId,
      'gsm': gsm,
      'order_quantity': orderQuantity,
      'machine_ids': machineIds,
      'yarns': yarns
          .map(
            (yarn) => {
              'yarn_id': yarn.yarnId,
              'quantity': yarn.quantity,
            },
          )
          .toList(),
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _tryDecode(response.body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw ApiException(
        _extractError(data, 'Failed to create job order'),
        response.statusCode,
      );
    }

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid create job response',
        response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        _extractError(data, 'Failed to create job order'),
        response.statusCode,
      );
    }

    final jobs = data['jobs'];

    if (jobs is! List) {
      throw ApiException(
        data['error']?.toString() ??
            'Job was created but no job numbers were returned',
        response.statusCode,
      );
    }

    return jobs
        .map((job) {
          if (job is Map && job['job_no'] != null) {
            return job['job_no'].toString();
          }
          return job.toString();
        })
        .toList();
  }

  // ============================================================
  // UPDATE JOB
  // ============================================================

  Future<JobOrder> updateJob({
    required int id,
    required int partyId,
    required int fabricId,
    required double gsm,
    required double orderQuantity,
    List<int> machineIds = const [],
    List<JobYarnRequirement> yarns = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/jobs/$id');

    final body = <String, dynamic>{
      'party_id': partyId,
      'fabric_id': fabricId,
      'gsm': gsm,
      'order_quantity': orderQuantity,
      'machine_ids': machineIds,
      'yarns': yarns
          .map(
            (yarn) => {
              'yarn_id': yarn.yarnId,
              'quantity': yarn.quantity,
            },
          )
          .toList(),
    };

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _tryDecode(response.body);

    if (response.statusCode != 200 ||
        data is! Map<String, dynamic>) {
      throw ApiException(
        _extractError(data, 'Failed to update job order'),
        response.statusCode,
      );
    }

    if (data['success'] != true || data['job'] is! Map) {
      throw ApiException(
        _extractError(data, 'Failed to update job order'),
        response.statusCode,
      );
    }

    return JobOrder.fromJson(
      Map<String, dynamic>.from(data['job'] as Map),
    );
  }

  // ============================================================
  // CLOSE JOB
  // ============================================================

  Future<void> closeJob(String jobNo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jobs/close/$jobNo'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = _tryDecode(response.body);

    if (response.statusCode != 200 ||
        data is! Map<String, dynamic>) {
      throw ApiException(
        _extractError(data, 'Failed to close job'),
        response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        _extractError(data, 'Failed to close job'),
        response.statusCode,
      );
    }
  }

  // ============================================================
  // CHANGE JOB MACHINE
  // ============================================================

  Future<void> changeJobMachine({
    required int jobId,
    required int newMachineId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jobs/change-machine/$jobId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'new_machine_id': newMachineId,
      }),
    );

    final data = _tryDecode(response.body);

    if (response.statusCode != 200 ||
        data is! Map<String, dynamic>) {
      throw ApiException(
        _extractError(data, 'Failed to change job machine'),
        response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        _extractError(data, 'Failed to change job machine'),
        response.statusCode,
      );
    }
  }

  // ============================================================
  // JOB YARN HISTORY
  // ============================================================

  Future<List<JobYarnHistory>> getJobYarnHistory(
    String jobNo,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobNo/yarn-history'),
    );

    final decoded = _tryDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(decoded, 'Failed to load yarn history'),
        response.statusCode,
      );
    }

    if (decoded is Map && decoded['history'] is List) {
      return (decoded['history'] as List)
          .whereType<Map>()
          .map(
            (item) => JobYarnHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    if (decoded is! List) {
      throw ApiException(
        'Invalid yarn history response',
        response.statusCode,
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => JobYarnHistory.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // JOB PRODUCTION HISTORY
  // ============================================================

  Future<List<JobProductionHistory>> getJobProductionHistory(
    String jobNo,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobNo/production-history'),
    );

    final decoded = _tryDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractError(
          decoded,
          'Failed to load production history',
        ),
        response.statusCode,
      );
    }

    if (decoded is Map && decoded['history'] is List) {
      return (decoded['history'] as List)
          .whereType<Map>()
          .map(
            (item) => JobProductionHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    if (decoded is! List) {
      throw ApiException(
        'Invalid production history response',
        response.statusCode,
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => JobProductionHistory.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

Future<Fabric> createFabric({
  required String fabricCode,
  required String name,
  String? description,
  double? gsm,
  String? composition,
  double? widthInches,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/fabrics'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fabric_code': fabricCode,
      'name': name,
      'description': description,
      'gsm': gsm,
      'composition': composition,
      'width_inches': widthInches,
    }),
  );

  final data = _decodeMap(response.body);

  if (response.statusCode != 201 ||
      data['success'] != true) {
    throw ApiException(
      data['error']?.toString() ??
          'Failed to create fabric',
      response.statusCode,
    );
  }

  return Fabric.fromJson(
    Map<String, dynamic>.from(
      data['fabric'] as Map,
    ),
  );
}

Future<Fabric> updateFabric({
  required int id,
  required String fabricCode,
  required String name,
  String? description,
  double? gsm,
  String? composition,
  double? widthInches,
  bool isActive = true,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/fabrics/$id'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fabric_code': fabricCode,
      'name': name,
      'description': description,
      'gsm': gsm,
      'composition': composition,
      'width_inches': widthInches,
      'is_active': isActive,
    }),
  );

  final data = _decodeMap(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw ApiException(
      data['error']?.toString() ??
          'Failed to update fabric',
      response.statusCode,
    );
  }

  return Fabric.fromJson(
    Map<String, dynamic>.from(
      data['fabric'] as Map,
    ),
  );
}

Future<void> deactivateFabric(int id) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/fabrics/$id'),
  );

  final data = _decodeMap(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw ApiException(
      data['error']?.toString() ??
          'Failed to deactivate fabric',
      response.statusCode,
    );
  }
}













  // ============================================================
  // HELPERS
  // ============================================================

  static Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const ApiException(
        'Invalid server response',
        500,
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractError(
    dynamic data,
    String fallback,
  ) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          fallback;
    }

    return fallback;
  }
}

// ============================================================
// PARTY MODEL
// ============================================================

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

  factory Party.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] is List
        ? json['roles'] as List
        : const [];

    return Party(
      id: _toInt(json['id']),
      partyCode: json['party_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pinCode: json['pin_code']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      contactPerson: json['contact_person']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString() ?? '',
      roles: rawRoles.map((role) => role.toString()).toList(),
    );
  }
}

// ============================================================
// PARTY STATS
// ============================================================

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

  factory PartyStats.fromJson(Map<String, dynamic> json) {
    return PartyStats(
      totalParties: _toInt(json['total_parties']),
      activeParties: _toInt(json['active_parties']),
      inactiveParties: _toInt(json['inactive_parties']),
      customers: _toInt(json['customers']),
      yarnSuppliers: _toInt(json['yarn_suppliers']),
      jobWorkers: _toInt(json['job_workers']),
      fabricBuyers: _toInt(json['fabric_buyers']),
    );
  }
}

// ============================================================
// FABRIC MODEL
// ============================================================
class Fabric {
  final int id;
  final String fabricCode;
  final String name;
  final String description;
  final double? gsm;
  final String composition;
  final double? widthInches;
  final bool isActive;

  const Fabric({
    required this.id,
    required this.fabricCode,
    required this.name,
    required this.description,
    required this.gsm,
    required this.composition,
    required this.widthInches,
    required this.isActive,
  });

  factory Fabric.fromJson(
    Map<String, dynamic> json,
  ) {
    return Fabric(
      id: _toInt(json['id']),
      fabricCode:
          json['fabric_code']?.toString() ?? '',
      name:
          json['name']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      gsm: json['gsm'] == null
          ? null
          : _toDouble(json['gsm']),
      composition:
          json['composition']?.toString() ?? '',
      widthInches:
          json['width_inches'] == null
              ? null
              : _toDouble(
                  json['width_inches'],
                ),
      isActive:
          json['is_active'] == true,
    );
  }
}

// ============================================================
// MACHINE MODEL
// ============================================================

class Machine {
  final int id;
  final String machineNo;
  final String status;
  final double rpm;
  final double counter;
  final double rollSize;
  final double kgPerHour;
  final double kg24h;
  final int estimatedRolls24h;

  const Machine({
    required this.id,
    required this.machineNo,
    required this.status,
    required this.rpm,
    required this.counter,
    required this.rollSize,
    required this.kgPerHour,
    required this.kg24h,
    required this.estimatedRolls24h,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: _toInt(json['id']),
      machineNo: json['machine_no']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      rpm: _toDouble(json['rpm']),
      counter: _toDouble(json['counter']),
      rollSize: _toDouble(json['roll_size']),
      kgPerHour: _toDouble(json['kg_per_hour']),
      kg24h: _toDouble(json['kg_24h']),
      estimatedRolls24h: _toInt(json['estimated_rolls_24h']),
    );
  }
}

// ============================================================
// YARN MASTER MODEL
// ============================================================

class YarnMaster {
  final int id;
  final String yarnName;
  final String yarnCount;
  final String yarnType;

  const YarnMaster({
    required this.id,
    required this.yarnName,
    required this.yarnCount,
    required this.yarnType,
  });

  factory YarnMaster.fromJson(Map<String, dynamic> json) {
    return YarnMaster(
      id: _toInt(json['id']),
      yarnName: json['yarn_name']?.toString() ?? '',
      yarnCount: json['yarn_count']?.toString() ?? '',
      yarnType: json['yarn_type']?.toString() ?? '',
    );
  }
}

// ============================================================
// JOB YARN REQUIREMENT
// ============================================================

class JobYarnRequirement {
  final int yarnId;
  final double? quantity;

  const JobYarnRequirement({
    required this.yarnId,
    this.quantity,
  });
}

// ============================================================
// JOB ORDER
// ============================================================

class JobOrder {
  final int id;
  final String jobNo;
  final int? fabricId;
  final String fabricName;
  final int? partyId;
  final String partyName;
  final int? machineId;
  final String machineNo;
  final double gsm;
  final double orderQuantity;
  final String status;
  final String createdAt;
  final String yarnsUsed;
  final double actualProduction;
  final double avgRollSize;
  final double remainingQuantity;

  const JobOrder({
    required this.id,
    required this.jobNo,
    required this.fabricId,
    required this.fabricName,
    required this.partyId,
    required this.partyName,
    required this.machineId,
    required this.machineNo,
    required this.gsm,
    required this.orderQuantity,
    required this.status,
    required this.createdAt,
    required this.yarnsUsed,
    required this.actualProduction,
    required this.avgRollSize,
    required this.remainingQuantity,
  });

  factory JobOrder.fromJson(Map<String, dynamic> json) {
    return JobOrder(
      id: _toInt(json['id']),
      jobNo: json['job_no']?.toString() ?? '',
      fabricId: _toNullableInt(json['fabric_id']),
      fabricName: json['fabric_name']?.toString() ?? '',
      partyId: _toNullableInt(json['party_id']),
      partyName: json['party_name']?.toString() ?? '',
      machineId: _toNullableInt(json['machine_id']),
      machineNo: json['machine_no']?.toString() ?? '',
      gsm: _toDouble(json['gsm']),
      orderQuantity: _toDouble(json['order_quantity']),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      yarnsUsed: json['yarns_used']?.toString() ?? '',
      actualProduction: _toDouble(json['actual_production']),
      avgRollSize: _toDouble(json['avg_roll_size']),
      remainingQuantity: _toDouble(json['remaining_quantity']),
    );
  }

  double get completionPercent {
    if (orderQuantity <= 0) {
      return 0;
    }

    final value = actualProduction / orderQuantity * 100;

    return value.clamp(0, 100);
  }
}

// ============================================================
// JOB DETAILS
// ============================================================

class JobDetails {
  final JobOrder job;
  final List<int> machineIds;
  final List<JobYarnRequirement> yarns;

  const JobDetails({
    required this.job,
    required this.machineIds,
    required this.yarns,
  });

  factory JobDetails.fromJson(Map<String, dynamic> json) {
    final rawMachines =
        json['machines'] is List
            ? json['machines'] as List
            : const [];

    final rawYarns =
        json['yarns'] is List
            ? json['yarns'] as List
            : const [];

    final jobData =
        json['job'] is Map
            ? Map<String, dynamic>.from(json['job'] as Map)
            : json;

    final job = JobOrder.fromJson(jobData);

    return JobDetails(
      job: job,
      machineIds: rawMachines.map((item) {
        if (item is Map) {
          return _toInt(
            item['machine_id'] ?? item['id'],
          );
        }

        return _toInt(item);
      }).toList(),
      yarns: rawYarns.map((item) {
        final map = Map<String, dynamic>.from(item as Map);

        return JobYarnRequirement(
          yarnId: _toInt(
            map['yarn_id'] ?? map['id'],
          ),
          quantity: map['quantity'] == null
              ? map['required_kg'] == null
                  ? null
                  : _toDouble(map['required_kg'])
              : _toDouble(map['quantity']),
        );
      }).toList(),
    );
  }
}

// ============================================================
// JOB YARN HISTORY
// ============================================================

class JobYarnHistory {
  final String transactionType;
  final double quantity;
  final String createdAt;
  final String lotNo;
  final String yarnName;
  final String remarks;

  const JobYarnHistory({
    required this.transactionType,
    required this.quantity,
    required this.createdAt,
    required this.lotNo,
    required this.yarnName,
    required this.remarks,
  });

  factory JobYarnHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return JobYarnHistory(
      transactionType:
          json['transaction_type']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      createdAt: json['created_at']?.toString() ?? '',
      lotNo: json['lot_no']?.toString() ?? '',
      yarnName: json['yarn_name']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

// ============================================================
// JOB PRODUCTION HISTORY
// ============================================================

class JobProductionHistory {
  final String rollNo;
  final double quantity;
  final String createdAt;

  const JobProductionHistory({
    required this.rollNo,
    required this.quantity,
    required this.createdAt,
  });

  factory JobProductionHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return JobProductionHistory(
      rollNo: json['roll_no']?.toString() ?? '',
      quantity: _toDouble(json['quantity'] ?? json['quantity_kg']),
      createdAt: json['created_at']?.toString() ??
          json['production_date']?.toString() ??
          '',
    );
  }
}

// ============================================================
// API EXCEPTION
// ============================================================

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

// ============================================================
// NUMBER HELPERS
// ============================================================

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}
