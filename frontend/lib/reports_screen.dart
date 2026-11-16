import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'widgets/app_widgets.dart';
import 'services/api_service.dart';

const _panel = BBTheme.panel;
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
  final List<_ReportDefinition> _reports = const [
    _ReportDefinition('production', 'Production', 'Posted production by date, job and machine', Icons.precision_manufacturing_outlined),
    _ReportDefinition('jobs', 'Job orders', 'Targets, produced quantity and remaining balance', Icons.assignment_outlined),
    _ReportDefinition('fabric-stock', 'Fabric stock', 'Reconciled available dispatch lots', Icons.layers_outlined),
  ];
  String _selected = 'production';
  bool _loading = true;
  bool _overviewLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _overview = {};
  DateTime _to = DateTime.now();
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));

  _ReportDefinition get _report => _reports.firstWhere((report) => report.key == _selected);

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _loadRows();
  }

  Future<void> _loadOverview() async {
    try {
      final value = await _api.getReportOverview();
      if (mounted) setState(() { _overview = value; _overviewLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _overviewLoading = false);
    }
  }

  Future<void> _loadRows() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _api.getReportRows(_selected, from: _selected == 'production' ? _from : null, to: _selected == 'production' ? _to : null);
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _loading = false; _rows = []; });
    }
  }

  Future<void> _chooseDate(bool isFrom) async {
    final value = await showDatePicker(context: context, initialDate: isFrom ? _from : _to, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 366)));
    if (value == null) return;
    setState(() { if (isFrom) { _from = value; } else { _to = value; } });
    await _loadRows();
  }

  String _dateLabel(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _kg(dynamic value) { final n = double.tryParse(value?.toString() ?? ''); return n == null ? '—' : '${n.toStringAsFixed(2)} kg'; }
  String _overviewValue(String key, {bool kg = true}) {
    if (_overviewLoading) return '…';
    final value = double.tryParse(_overview[key]?.toString() ?? '') ?? 0;
    return kg ? _kg(value) : value.toStringAsFixed(0);
  }

  Future<void> _exportCsv() async {
    if (_rows.isEmpty) return;
    final columns = _report.columns;
    String quote(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = [columns.map((c) => quote(c.label)).join(','), ..._rows.map((row) => columns.map((c) => quote(_cell(row[c.key]))).join(','))].join('\r\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied as CSV. Paste it into a spreadsheet.')));
  }

  String _cell(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return _dateLabel(value);
    final text = value.toString();
    final parsed = DateTime.tryParse(text);
    return parsed == null ? text : _dateLabel(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BBPageHeader(title: 'Reports', subtitle: 'Production, job progress and dispatch-ready stock', actions: [IconButton(onPressed: () { _loadOverview(); _loadRows(); }, tooltip: 'Refresh', icon: const Icon(Icons.refresh))]),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, constraints) {
          final stats = [
            _Stat('Production today', _overviewValue('production_today_kg'), Icons.trending_up),
            _Stat('Production this month', _overviewValue('production_month_kg'), Icons.calendar_month_outlined),
            _Stat('Open jobs', _overviewValue('open_jobs', kg: false), Icons.assignment_outlined),
            _Stat('Available fabric', _overviewValue('available_fabric_kg'), Icons.layers_outlined),
          ];
          final columns = constraints.maxWidth < 650 ? 1 : constraints.maxWidth < 1000 ? 2 : 4;
          return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: columns == 1 ? 4.8 : columns == 2 ? 3.5 : 2.5, children: stats);
        }),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 12, spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: _accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(9)), child: Icon(_report.icon, color: _accent)),
              const SizedBox(width: 11),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Report workspace', style: TextStyle(color: _muted, fontSize: 11)), Text(_report.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))]),
            ]),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              DropdownButton<String>(value: _selected, underline: const SizedBox(), items: _reports.map((r) => DropdownMenuItem(value: r.key, child: Text(r.title))).toList(), onChanged: (value) { if (value != null) setState(() => _selected = value); _loadRows(); }),
              if (_selected == 'production') ...[
                OutlinedButton.icon(onPressed: () => _chooseDate(true), icon: const Icon(Icons.calendar_today_outlined, size: 15), label: Text(_dateLabel(_from))),
                const Text('to', style: TextStyle(color: _muted)),
                OutlinedButton.icon(onPressed: () => _chooseDate(false), icon: const Icon(Icons.calendar_today_outlined, size: 15), label: Text(_dateLabel(_to))),
              ],
              OutlinedButton.icon(onPressed: _rows.isEmpty ? null : _exportCsv, icon: const Icon(Icons.file_download_outlined, size: 17), label: const Text('Copy CSV')),
            ]),
          ]),
          const SizedBox(height: 5),
          Text(_report.description, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 18),
          if (_loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) _EmptyState(icon: Icons.error_outline, title: 'Could not load this report', detail: _error!, action: TextButton.icon(onPressed: _loadRows, icon: const Icon(Icons.refresh), label: const Text('Try again')))
          else if (_rows.isEmpty) _EmptyState(icon: Icons.inbox_outlined, title: 'No records in this report', detail: _selected == 'fabric-stock' ? 'Available stock appears here after existing production rolls are reconciled in Dispatch.' : 'Try a wider date range or check again when records are available.')
          else _ReportTable(columns: _report.columns, rows: _rows),
          if (!_loading && _rows.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${_rows.length} records${_rows.length >= 1000 ? ' · showing first 1,000' : ''}', style: const TextStyle(color: _muted, fontSize: 11))),
        ])),
      ]),
    );
  }
}

class _ReportDefinition {
  final String key, title, description;
  final IconData icon;
  const _ReportDefinition(this.key, this.title, this.description, this.icon);
  List<_Column> get columns => switch (key) {
    'production' => const [_Column('production_date','Date'),_Column('production_no','Production'),_Column('job_no','Job'),_Column('party_name','Party'),_Column('fabric_name','Fabric'),_Column('machine_no','Machine'),_Column('roll_count','Rolls'),_Column('quantity_kg','Quantity kg'),_Column('meters','Meters')],
    'jobs' => const [_Column('job_no','Job'),_Column('job_date','Date'),_Column('party_name','Party'),_Column('fabric_name','Fabric'),_Column('status','Status'),_Column('target_kg','Target kg'),_Column('produced_kg','Produced kg'),_Column('remaining_kg','Remaining kg')],
    _ => const [_Column('lot_no','Lot'),_Column('job_no','Job'),_Column('party_name','Party'),_Column('fabric_name','Fabric'),_Column('quantity_kg','Available kg'),_Column('received_date','Available since')],
  };
}

class _Column { final String key,label; const _Column(this.key,this.label); }

class _ReportTable extends StatelessWidget {
  final List<_Column> columns;
  final List<Map<String,dynamic>> rows;
  const _ReportTable({required this.columns,required this.rows});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: constraints.maxWidth), child: DataTable(columnSpacing: 22, horizontalMargin: 12, headingRowHeight: 44, dataRowMinHeight: 44, dataRowMaxHeight: 56, columns: columns.map((c) => DataColumn(label: Text(c.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))).toList(), rows: rows.map((row) => DataRow(cells: columns.map((c) => DataCell(Text(_format(row[c.key]), style: const TextStyle(fontSize: 11)))).toList())).toList()))));
  String _format(dynamic value) {
    if (value == null) return '—';
    final parsedDate = DateTime.tryParse(value.toString());
    if (parsedDate != null && value is! num) return '${parsedDate.day.toString().padLeft(2,'0')}/${parsedDate.month.toString().padLeft(2,'0')}/${parsedDate.year}';
    final number = double.tryParse(value.toString());
    return number == null ? value.toString() : number.toStringAsFixed(number == number.truncateToDouble() ? 0 : 2);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title,detail; final Widget? action;
  const _EmptyState({required this.icon,required this.title,required this.detail,this.action});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.symmetric(vertical: 28,horizontal: 12), child: Column(children: [Icon(icon,size:32,color:_muted),const SizedBox(height:10),Text(title,style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:5),Text(detail,textAlign:TextAlign.center,style:const TextStyle(color:_muted,fontSize:12)),if(action!=null) action!])));
}

class _Stat extends StatelessWidget {
  final String title,value; final IconData icon;
  const _Stat(this.title,this.value,this.icon);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)), child: Row(children: [Container(width: 40,height:40,decoration:BoxDecoration(color:_accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Icon(icon,color:_accent,size:20)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(title,style:const TextStyle(color:_muted,fontSize:11)),const SizedBox(height:4),Text(value,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700))]))]));
}
