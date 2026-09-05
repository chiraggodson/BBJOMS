import 'dart:convert';
import 'package:http/http.dart' as http;

class YarnReceiptSupplier {
  final String id;
  final String code;
  final String name;
  YarnReceiptSupplier({required this.id, required this.code, required this.name});

  factory YarnReceiptSupplier.fromJson(Map<String, dynamic> json) =>
      YarnReceiptSupplier(
        id: '${json['id'] ?? ''}',
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
      );
}

class YarnReceiptLocation {
  final String id;
  final String code;
  final String name;
  final String type;
  YarnReceiptLocation({required this.id, required this.code, required this.name, required this.type});

  factory YarnReceiptLocation.fromJson(Map<String, dynamic> json) =>
      YarnReceiptLocation(
        id: '${json['id'] ?? ''}',
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        type: '${json['location_type'] ?? ''}',
      );
}

class YarnReceiptApi {
  final String baseUrl;
  final http.Client _client;

  YarnReceiptApi({
    this.baseUrl = 'http://192.168.1.20:4000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<YarnReceiptSupplier>> getSuppliers() async {
    final r = await _client.get(Uri.parse('$baseUrl/yarn-receipts/suppliers'));
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['suppliers'] as List? ?? [])
        .map((e) => YarnReceiptSupplier.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<YarnReceiptLocation>> getLocations() async {
    final r = await _client.get(Uri.parse('$baseUrl/yarn-receipts/locations'));
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['locations'] as List? ?? [])
        .map((e) => YarnReceiptLocation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getYarns() async {
    final r = await _client.get(Uri.parse('$baseUrl/yarns'));
    _check(r);
    final decoded = jsonDecode(r.body);
    final list = decoded is List ? decoded : (decoded['yarns'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createReceipt({
    required String receiptDate,
    String? challanNo,
    String? billNo,
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
        'challan_no': challanNo,
        'bill_no': billNo,
        'party_id': supplierId,
        'location_id': locationId,
        'notes': notes,
        'financial_year_id': financialYearId,
        'lines': lines,
      }),
    );
    _check(r);
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  Future<List<Map<String, dynamic>>> getReceipts() async {
    final r = await _client.get(Uri.parse('$baseUrl/yarn-receipts'));
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['receipts'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      String message = 'HTTP ${r.statusCode}';
      try {
        final data = jsonDecode(r.body);
        message = '${data['error'] ?? message}';
      } catch (_) {}
      throw Exception(message);
    }
  }
}
