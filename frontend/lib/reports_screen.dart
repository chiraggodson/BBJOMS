import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/api_service.dart';

const _panel = BBTheme.panel;
const _panel2 = BBTheme.black3;
const _border = BBTheme.border;
const _muted = BBTheme.muted;
const _accent = BBTheme.red;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  double? _productionToday;
  double? _productionMonth;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _api.getReportOverview();
      if (!mounted) return;
      setState(() {
        _productionToday = _asDouble(summary['production_today_kg']);
        _productionMonth = _asDouble(summary['production_month_kg']);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatKg(double? value) {
    if (_loading) return 'Loading…';
    if (_error != null || value == null) return '—';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    SizedBox(height: 5),
                    Text('Factory performance, production and stock reports', style: TextStyle(color: _muted, fontSize: 13)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export unavailable'),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _loadOverview, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text('Production summary could not be loaded: $_error', style: const TextStyle(color: Color(0xFFE57373))),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                _Stat('Production Today', _formatKg(_productionToday), Icons.trending_up),
                _Stat('This Month', _formatKg(_productionMonth), Icons.calendar_month_outlined),
                const _Stat('Efficiency', 'Not tracked', Icons.speed_outlined),
                const _Stat('Job Work Charges', 'No charge data', Icons.currency_rupee),
              ];
              if (constraints.maxWidth < 760) {
                return Wrap(spacing: 12, runSpacing: 12, children: stats.map((stat) => SizedBox(width: 240, child: stat)).toList());
              }
              return Row(children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: stats[i]),
                ],
              ]);
            },
          ),
          const SizedBox(height: 20),
          _Card(
            title: 'Reports',
            child: Column(children: const [
              _ReportRow(Icons.precision_manufacturing_outlined, 'Production Report', 'Machine-wise and date-wise production'),
              _ReportRow(Icons.assignment_outlined, 'Job Order Report', 'Job status, target, production and balance'),
              _ReportRow(Icons.all_inclusive, 'Yarn Ledger', 'Receipts, issues, returns and live balance'),
              _ReportRow(Icons.people_outline, 'Party Ledger', 'Party-wise material and job-work transactions'),
              _ReportRow(Icons.layers_outlined, 'Fabric Stock Report', 'Finished fabric stock and dispatch'),
              _ReportRow(Icons.speed_outlined, 'Machine Efficiency', 'RPM, production and utilisation analysis'),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('Only posted production totals are connected. Other reports and exports will be enabled when their source data is available.', style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _accent, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ])),
        ]),
      );
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ReportRow(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: _accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: _accent, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
          ])),
          const Text('Not available', style: TextStyle(color: _muted, fontSize: 10)),
        ]),
      );
}