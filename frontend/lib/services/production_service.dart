
import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductionService {
  static const String baseUrl = 'http://192.168.1.20:4000/api';

  Future<void> addProductionBatch({
    required List<Map<String, dynamic>> entries,
  }) async {
    if (entries.isEmpty) {
      throw Exception('At least one production roll is required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/jobs/production-batch'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'entries': entries}),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 201) {
      final error = decoded is Map
          ? decoded['error']?.toString()
          : null;
      throw Exception(
        error?.isNotEmpty == true
            ? error
            : 'Production batch save failed (HTTP ${response.statusCode})',
      );
    }

    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        decoded['error']?.toString() ?? 'Production batch save failed',
      );
    }
  }

  Future<void> addProduction({
    required int jobId,
    required int machineId,
    required String productionDate,
    required String rollNo,
    required double quantityKg,
    String? remarks,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/production'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'machine_id': machineId,
        'production_date': productionDate,
        'roll_no': rollNo.trim(),
        'quantity_kg': quantityKg,
        'remarks': remarks?.trim(),
      }),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 201) {
      final error = decoded is Map
          ? decoded['error']?.toString()
          : null;
      throw Exception(
        error?.isNotEmpty == true
            ? error
            : 'Production save failed (HTTP ${response.statusCode})',
      );
    }

    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        decoded['error']?.toString() ?? 'Production save failed',
      );
    }
  }
}
