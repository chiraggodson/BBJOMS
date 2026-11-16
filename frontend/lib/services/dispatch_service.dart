import 'dart:convert';

import '../app_config.dart';
import 'api_http.dart';

class DispatchService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<List<Map<String, dynamic>>> getLots() async {
    final response = await ApiHttp.get(Uri.parse('$baseUrl/dispatch/lots'));
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Failed to load fabric lots',
      );
    }
    return (data['lots'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUnreconciledRolls() async {
    final response = await ApiHttp.get(
      Uri.parse('$baseUrl/dispatch/unreconciled-rolls'),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Failed to load existing production rolls',
      );
    }
    return (data['rolls'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getDispatches() async {
    final response = await ApiHttp.get(Uri.parse('$baseUrl/dispatch'));
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to load dispatches');
    }
    return (data['dispatches'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<Map<String, dynamic>> getDispatch(String id) async {
    final response = await ApiHttp.get(Uri.parse('$baseUrl/dispatch/$id'));
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Failed to load dispatch details',
      );
    }
    return {
      'dispatch': Map<String, dynamic>.from(data['dispatch'] as Map),
      'lines': (data['lines'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
    };
  }

  Future<void> splitLot({
    required String lotId,
    required List<double> childQuantitiesKg,
    double cuttingLossKg = 0,
    String? notes,
  }) async {
    final response = await ApiHttp.post(
      Uri.parse('$baseUrl/dispatch/lots/$lotId/split'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'child_quantities_kg': childQuantitiesKg,
        'cutting_loss_kg': cuttingLossKg,
        'notes': notes,
      }),
    );
    _requireSuccess(
      response.body,
      response.statusCode,
      201,
      'Lot split failed',
    );
  }

  Future<void> reconcileOpeningStock({required List<String> rollIds}) async {
    final response = await ApiHttp.post(
      Uri.parse('$baseUrl/dispatch/opening-stock'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'roll_ids': rollIds}),
    );
    _requireSuccess(
      response.body,
      response.statusCode,
      201,
      'Opening stock reconciliation failed',
    );
  }

  Future<void> createDispatch({
    required String partyId,
    required List<String> lotIds,
    required String challanDate,
    String? transporter,
    String? vehicleNo,
    String? notes,
  }) async {
    final response = await ApiHttp.post(
      Uri.parse('$baseUrl/dispatch'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'party_id': partyId,
        'lot_ids': lotIds,
        'challan_date': challanDate,
        'transporter': transporter,
        'vehicle_no': vehicleNo,
        'notes': notes,
      }),
    );
    _requireSuccess(
      response.body,
      response.statusCode,
      201,
      'Dispatch save failed',
    );
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }

  void _requireSuccess(String body, int status, int expected, String fallback) {
    final data = _decode(body);
    if (status != expected || data['success'] != true) {
      throw Exception(data['error']?.toString() ?? '$fallback (HTTP $status)');
    }
  }
}
