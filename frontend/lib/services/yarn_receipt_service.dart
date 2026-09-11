import 'dart:convert';
import 'package:http/http.dart' as http;


class YarnReceiptCompany {
  final String id;
  final String code;
  final String name;

  YarnReceiptCompany({
    required this.id,
    required this.code,
    required this.name,
  });

  factory YarnReceiptCompany.fromJson(Map<String, dynamic> json) {
    return YarnReceiptCompany(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
    );
  }
}

class YarnReceiptColor {
  final String id;
  final String code;
  final String name;
  final String description;

  YarnReceiptColor({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
  });

  factory YarnReceiptColor.fromJson(Map<String, dynamic> json) {
    return YarnReceiptColor(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
    );
  }
}

class YarnReceiptSupplier {
  final String id;
  final String code;
  final String name;

  YarnReceiptSupplier({
    required this.id,
    required this.code,
    required this.name,
  });

  factory YarnReceiptSupplier.fromJson(Map<String, dynamic> json) {
    return YarnReceiptSupplier(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? json['party_code'] ?? ''}',
      name: '${json['name'] ?? ''}',
    );
  }
}

class YarnReceiptLocation {
  final String id;
  final String code;
  final String name;
  final String type;

  YarnReceiptLocation({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
  });

  factory YarnReceiptLocation.fromJson(Map<String, dynamic> json) {
    return YarnReceiptLocation(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      type: '${json['location_type'] ?? json['type'] ?? ''}',
    );
  }
}

class YarnReceiptApi {
  final String baseUrl;
  final http.Client _client;

  YarnReceiptApi({
    this.baseUrl = 'http://192.168.29.6:4000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();


  // ------------------------------------------------------------
  // Companies - the company that owns the received yarn stock.
  // ------------------------------------------------------------
  Future<List<YarnReceiptCompany>> getCompanies() async {
    final r = await _client.get(
      Uri.parse('$baseUrl/yarn-receipts/companies'),
    );
    _check(r);

    final decoded = jsonDecode(r.body);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['companies'] is List) {
      list = decoded['companies'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => YarnReceiptCompany.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }

  // ------------------------------------------------------------
  // Yarn Suppliers
  // Uses the same Parties API that the existing Parties screen uses.
  // This is important because the current party module stores roles as
  // party_roles.role = 'Yarn Supplier'.
  // ------------------------------------------------------------
  Future<List<YarnReceiptSupplier>> getSuppliers() async {
    final uri = Uri.parse(
      '$baseUrl/parties?role=${Uri.encodeQueryComponent('Yarn Supplier')}&active=true',
    );

    final r = await _client.get(uri);
    _check(r);

    final decoded = jsonDecode(r.body);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['parties'] is List) {
      list = decoded['parties'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => YarnReceiptSupplier.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((s) => s.id.isNotEmpty && s.name.isNotEmpty)
        .toList();
  }

  Future<List<YarnReceiptColor>> getColors() async {
    final r = await _client.get(
      Uri.parse('$baseUrl/yarn-receipts/colors'),
    );
    _check(r);

    final decoded = jsonDecode(r.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['colors'] is List) {
      list = decoded['colors'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => YarnReceiptColor.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }

  // ------------------------------------------------------------
  // Locations
  // ------------------------------------------------------------
  Future<List<YarnReceiptLocation>> getLocations({String? companyId}) async {
    final uri = Uri.parse('$baseUrl/yarn-receipts/locations').replace(
      queryParameters: companyId == null || companyId.trim().isEmpty
          ? null
          : {'company_id': companyId.trim()},
    );

    final r = await _client.get(uri);
    _check(r);

    final decoded = jsonDecode(r.body);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['locations'] is List) {
      list = decoded['locations'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => YarnReceiptLocation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((l) => l.id.isNotEmpty && l.name.isNotEmpty)
        .toList();
  }

  // ------------------------------------------------------------
  // Generic Yarn Master
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getYarns() async {
    final r = await _client.get(
      Uri.parse('$baseUrl/yarns'),
    );
    _check(r);

    final decoded = jsonDecode(r.body);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['yarns'] is List) {
      list = decoded['yarns'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ------------------------------------------------------------
  // Create Yarn Receipt
  // One header + multiple yarn lines.
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> createReceipt({
    required String receiptDate,
    String? challanNo,
    String? billNo,
    required String companyId,
    required String supplierId,
    String? locationId,
    String? notes,
    String? financialYearId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final r = await _client.post(
      Uri.parse('$baseUrl/yarn-receipts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receipt_date': receiptDate,
        'company_id': companyId,
        'challan_no': _clean(challanNo),
        'bill_no': _clean(billNo),
        'party_id': supplierId,
        'location_id': _clean(locationId),
        'notes': _clean(notes),
        'financial_year_id': _clean(financialYearId),
        'lines': lines,
      }),
    );

    _check(r);

    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'success': true, 'data': decoded};
  }

  // ------------------------------------------------------------
  // Receipt List
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getReceipts() async {
    final r = await _client.get(
      Uri.parse('$baseUrl/yarn-receipts'),
    );
    _check(r);

    final decoded = jsonDecode(r.body);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['receipts'] is List) {
      list = decoded['receipts'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }


  // ------------------------------------------------------------
  // Live yarn stock available for issue.
  // One row represents a yarn lot at a specific location.
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getYarnStock() async {
    final r = await _client.get(
      Uri.parse('$baseUrl/yarn-receipts/stock'),
    );
    _check(r);

    final decoded = jsonDecode(r.body);
    final List<dynamic> list;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['stock'] is List) {
      list = decoded['stock'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ------------------------------------------------------------
  // Live yarn movement ledger.
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getYarnMovements({int limit = 50}) async {
    final safeLimit = limit.clamp(1, 200);
    final uri = Uri.parse('$baseUrl/yarn-receipts/movements').replace(
      queryParameters: {'limit': safeLimit.toString()},
    );

    final r = await _client.get(uri);
    _check(r);

    final decoded = jsonDecode(r.body);
    final List<dynamic> list;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['movements'] is List) {
      list = decoded['movements'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ------------------------------------------------------------
  // Multiple jobs / multiple yarns in one posting.
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> issueYarnBatch({
    required List<Map<String, dynamic>> entries,
    String? issueDate,
  }) async {
    if (entries.isEmpty) {
      throw Exception('At least one yarn issue line is required.');
    }

    final r = await _client.post(
      Uri.parse('$baseUrl/yarn-receipts/issue-batch'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'issue_date': _clean(issueDate),
        'entries': entries,
      }),
    );

    _check(r);

    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'success': true, 'issues': decoded};
  }

  String? _clean(String? value) {
    if (value == null) return null;
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      String message = 'HTTP ${r.statusCode}';

      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map<String, dynamic>) {
          message = '${decoded['error'] ?? decoded['message'] ?? message}';
          final details = decoded['details'];
          if (details != null && details.toString().trim().isNotEmpty) {
            message = '$message: $details';
          }
        }
      } catch (_) {
        if (r.body.trim().isNotEmpty) {
          message = r.body.trim();
        }
      }

      throw Exception(message);
    }
  }
}
