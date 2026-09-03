import 'package:flutter/material.dart';
import '../services/api_service.dart';

class YarnPage extends StatefulWidget {
  const YarnPage({super.key});
  @override
  State<YarnPage> createState() => _YarnPageState();
}

class _YarnPageState extends State<YarnPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<YarnMaster> _yarns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadYarns(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadYarns() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _api.getYarns();
      if (!mounted) return;
      setState(() { _yarns = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<YarnMaster> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _yarns;
    return _yarns.where((y) =>
      y.code.toLowerCase().contains(q) ||
      y.name.toLowerCase().contains(q) ||
      y.count.toLowerCase().contains(q) ||
      y.composition.toLowerCase().contains(q) ||
      y.colour.toLowerCase().contains(q)).toList();
  }

  Future<void> _form({YarnMaster? yarn}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _YarnFormDialog(
        api: _api,
        yarn: yarn,
        defaultCompanyId: yarn?.companyId ?? (_yarns.isNotEmpty ? _yarns.first.companyId : null),
      ),
    );
    if (saved == true && mounted) await _loadYarns();
  }

  Future<void> _deactivate(YarnMaster yarn) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Deactivate Yarn'),
        content: Text('Deactivate "${yarn.name}" (${yarn.code})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deactivateYarn(yarn.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yarn deactivated')));
      await _loadYarns();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Yarn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('Yarn master, lots and live stock', style: TextStyle(color: Color(0xFF84919D), fontSize: 13)),
          ])),
          FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Yarn'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BFA6), foregroundColor: Colors.white)),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _loadYarns, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 24),
        _Summary(count: _yarns.length),
        const SizedBox(height: 20),
        _Card(title: 'Yarn Master', child: Column(children: [
          const SizedBox(height: 14),
          TextField(controller: _searchController, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: 'Search code, yarn, count, composition or colour...', prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear, size: 18)),
              filled: true, fillColor: const Color(0xFF0F171E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFF25313B))))),
          const SizedBox(height: 18),
          if (_loading) const Padding(padding: EdgeInsets.all(45), child: CircularProgressIndicator())
          else if (_error != null) _Error(message: _error!, retry: _loadYarns)
          else if (rows.isEmpty) const Padding(padding: EdgeInsets.all(45), child: Text('No yarn found', style: TextStyle(color: Color(0xFF9BA7B2))))
          else _Table(rows: rows, edit: (y) => _form(yarn: y), deactivate: _deactivate),
        ])),
        const SizedBox(height: 20),
        const _Card(title: 'Recent Yarn Movements', child: Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Movement transactions will be connected after Yarn Master.', style: TextStyle(color: Color(0xFF71808D), fontSize: 12)))),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  final int count;
  const _Summary({required this.count});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final cards = [('Active Yarn Masters', '$count', Icons.all_inclusive), ('Stock', '—', Icons.inventory_2_outlined), ('Active Lots', '—', Icons.layers_outlined), ('Today\'s Movements', '—', Icons.swap_vert)];
    final children = cards.map((x) => _Stat(title: x.$1, value: x.$2, icon: x.$3)).toList();
    if (c.maxWidth < 760) return Wrap(spacing: 12, runSpacing: 12, children: children.map((x) => SizedBox(width: (c.maxWidth - 12) / 2, child: x)).toList());
    return Row(children: children.map((x) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: x))).toList());
  });
}

class _Stat extends StatelessWidget {
  final String title, value; final IconData icon;
  const _Stat({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF111A22), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E2A34))), child: Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF00BFA6).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF00BFA6))),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF84919D), fontSize: 11)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))]))
  ]));
}

class _Table extends StatelessWidget {
  final List<YarnMaster> rows; final ValueChanged<YarnMaster> edit, deactivate;
  const _Table({required this.rows, required this.edit, required this.deactivate});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    if (c.maxWidth < 850) return Column(children: rows.map((y) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 5), leading: const CircleAvatar(backgroundColor: Color(0xFF153A38), child: Icon(Icons.all_inclusive, color: Color(0xFF00BFA6))), title: Text(y.name), subtitle: Text('${y.code} • ${y.count.isEmpty ? 'No count' : y.count}'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') edit(y); else deactivate(y); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))]))).toList());
    Widget h(String s, int f) => Expanded(flex: f, child: Text(s, style: const TextStyle(color: Color(0xFF71808D), fontSize: 10, fontWeight: FontWeight.w600)));
    Widget cell(String s, int f) => Expanded(flex: f, child: Text(s.isEmpty ? '—' : s, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9BA7B2), fontSize: 12)));
    return Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: const Color(0xFF0F171E), borderRadius: BorderRadius.circular(8)), child: Row(children: [h('Code',2), h('Yarn',4), h('Count',2), h('Composition',3), h('Colour',2), const SizedBox(width: 48)])), ...rows.map((y) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1D2933)))), child: Row(children: [cell(y.code,2), Expanded(flex:4, child: Text(y.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))), cell(y.count,2), cell(y.composition,3), cell(y.colour,2), PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') edit(y); else deactivate(y); }, itemBuilder: (_) => const [PopupMenuItem(value:'edit', child:Text('Edit')), PopupMenuItem(value:'deactivate', child:Text('Deactivate'))]))]))]);
  });
}

class _YarnFormDialog extends StatefulWidget {
  final ApiService api; final YarnMaster? yarn; final int? defaultCompanyId;
  const _YarnFormDialog({required this.api, required this.yarn, required this.defaultCompanyId});
  @override State<_YarnFormDialog> createState() => _YarnFormDialogState();
}

class _YarnFormDialogState extends State<_YarnFormDialog> {
  final keyForm = GlobalKey<FormState>();
  late final TextEditingController company, code, name, count, type, composition, colour, unit, description;
  bool saving = false;
  bool get editing => widget.yarn != null;
  @override void initState() { super.initState(); final y=widget.yarn; company=TextEditingController(text:(y?.companyId ?? widget.defaultCompanyId)?.toString()??''); code=TextEditingController(text:y?.code??''); name=TextEditingController(text:y?.name??''); count=TextEditingController(text:y?.count??''); type=TextEditingController(text:y?.yarnTypeId?.toString()??''); composition=TextEditingController(text:y?.composition??''); colour=TextEditingController(text:y?.colour??''); unit=TextEditingController(text:y?.unitId?.toString()??''); description=TextEditingController(text:y?.description??''); }
  @override void dispose(){ for(final x in [company,code,name,count,type,composition,colour,unit,description]) x.dispose(); super.dispose(); }
  InputDecoration d(String s)=>InputDecoration(labelText:s, filled:true, fillColor:const Color(0xFF0F171E), border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:Color(0xFF25313B))), enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:Color(0xFF25313B))), focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:Color(0xFF00BFA6))));
  Future<void> save() async { if(!keyForm.currentState!.validate()) return; final cid=int.tryParse(company.text.trim()); final tid=type.text.trim().isEmpty?null:int.tryParse(type.text.trim()); final uid=unit.text.trim().isEmpty?null:int.tryParse(unit.text.trim()); if(cid==null||cid<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid Company ID')));return;} setState(()=>saving=true); try { final args={ 'companyId':cid,'code':code.text.trim(),'name':name.text.trim(),'count':count.text.trim().isEmpty?null:count.text.trim(),'yarnTypeId':tid,'composition':composition.text.trim().isEmpty?null:composition.text.trim(),'colour':colour.text.trim().isEmpty?null:colour.text.trim(),'unitId':uid,'description':description.text.trim().isEmpty?null:description.text.trim()}; if(editing){await widget.api.updateYarn(id:widget.yarn!.id, companyId:args['companyId'] as int, code:args['code'] as String, name:args['name'] as String, count:args['count'] as String?, yarnTypeId:args['yarnTypeId'] as int?, composition:args['composition'] as String?, colour:args['colour'] as String?, unitId:args['unitId'] as int?, description:args['description'] as String?);} else {await widget.api.createYarn(companyId:args['companyId'] as int, code:args['code'] as String, name:args['name'] as String, count:args['count'] as String?, yarnTypeId:args['yarnTypeId'] as int?, composition:args['composition'] as String?, colour:args['colour'] as String?, unitId:args['unitId'] as int?, description:args['description'] as String?);} if(mounted) Navigator.pop(context,true); } catch(e){if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}} }
  @override Widget build(BuildContext context)=>Dialog(backgroundColor:const Color(0xFF111A22),insetPadding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760,maxHeight:720),child:Column(children:[Padding(padding:const EdgeInsets.fromLTRB(24,20,16,18),child:Row(children:[Expanded(child:Text(editing?'Edit Yarn':'Add Yarn',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700))),IconButton(onPressed:saving?null:()=>Navigator.pop(context),icon:const Icon(Icons.close))])),const Divider(height:1,color:Color(0xFF25313B)),Expanded(child:Form(key:keyForm,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:LayoutBuilder(builder:(_,c){final w=c.maxWidth>560?(c.maxWidth-14)/2:c.maxWidth; Widget f(Widget x)=>SizedBox(width:w,child:x); return Wrap(spacing:14,runSpacing:14,children:[f(TextFormField(controller:company,keyboardType:TextInputType.number,decoration:d('Company ID'),validator:(v)=>int.tryParse(v?.trim()??'')==null?'Required':null)),f(TextFormField(controller:code,decoration:d('Yarn Code'),validator:(v)=>v==null||v.trim().isEmpty?'Yarn code is required':null)),f(TextFormField(controller:name,decoration:d('Yarn Name'),validator:(v)=>v==null||v.trim().isEmpty?'Yarn name is required':null)),f(TextFormField(controller:count,decoration:d('Count'))),f(TextFormField(controller:type,keyboardType:TextInputType.number,decoration:d('Yarn Type ID'))),f(TextFormField(controller:unit,keyboardType:TextInputType.number,decoration:d('Unit ID'))),f(TextFormField(controller:composition,decoration:d('Composition'))),f(TextFormField(controller:colour,decoration:d('Colour'))),SizedBox(width:c.maxWidth,child:TextFormField(controller:description,maxLines:3,decoration:d('Description')))]);})))),const Divider(height:1,color:Color(0xFF25313B)),Padding(padding:const EdgeInsets.all(16),child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[TextButton(onPressed:saving?null:()=>Navigator.pop(context),child:const Text('Cancel')),const SizedBox(width:10),FilledButton(onPressed:saving?null:save,style:FilledButton.styleFrom(backgroundColor:const Color(0xFF00BFA6),foregroundColor:Colors.white),child:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Text(editing?'Save Changes':'Add Yarn'))]))])));
}

class _Error extends StatelessWidget { final String message; final VoidCallback retry; const _Error({required this.message,required this.retry}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(35),child:Column(children:[const Icon(Icons.cloud_off_outlined,size:42,color:Color(0xFF71808D)),const SizedBox(height:12),const Text('Could not load Yarn Master'),const SizedBox(height:7),Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF71808D),fontSize:11)),const SizedBox(height:14),OutlinedButton.icon(onPressed:retry,icon:const Icon(Icons.refresh,size:17),label:const Text('Retry'))])); }
class _Card extends StatelessWidget { final String title; final Widget child; const _Card({required this.title,required this.child}); @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFF111A22),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFF1E2A34))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w600)),child])); }
