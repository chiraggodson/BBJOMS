
import 'package:flutter/material.dart';

const _bg = Color(0xFF0B1117);
const _panel = Color(0xFF111A22);
const _panel2 = Color(0xFF0F171E);
const _border = Color(0xFF1E2A34);
const _muted = Color(0xFF84919D);
const _teal = Color(0xFF00BFA6);

class _Card extends StatelessWidget {
  final String title;
  final String? action;
  final Widget child;
  const _Card({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (action != null) Text(action!, style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _Stat extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _Stat(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: _teal.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _teal, size: 21)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );
}

class _Status extends StatelessWidget {
  final String text;
  const _Status(this.text);
  @override
  Widget build(BuildContext context) {
    Color c = _muted;
    if (text == 'Running' || text == 'Open' || text == 'Available') c = const Color(0xFF2DD4BF);
    if (text == 'Yarn Needed' || text == 'Low Stock') c = const Color(0xFFF87171);
    if (text == 'Paused' || text == 'Pending') c = const Color(0xFFFBBF24);
    if (text == 'Closed' || text == 'Complete') c = const Color(0xFFA78BFA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

Widget _search(String hint) => TextField(
  decoration: InputDecoration(
    hintText: hint, prefixIcon: const Icon(Icons.search, size: 20),
    filled: true, fillColor: _panel2,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFF25313B))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFF25313B))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _teal)),
  ),
);

Widget _primary(String label, IconData icon, VoidCallback onPressed) => FilledButton.icon(
  onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label),
  style: FilledButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
);


class MachinesPage extends StatelessWidget {
  const MachinesPage({super.key});
  final machines = const [
    ('M-01','Ground Floor','Interlock 4 Track','Running','BBJO-00120'),
    ('M-03','Ground Floor','Sinker 4 Track','Running','BBJO-00122'),
    ('M-07','Ground Floor','Interlock Jacquard','Paused','BBJO-00125'),
    ('M-12','Second Floor','Sinker Jacquard','Yarn Needed','BBJO-00126'),
    ('M-18','First Floor','Interlock Jacquard','Running','BBJO-00128'),
    ('M-21','Second Floor','Transfer Interlock 32\"','Stopped','—'),
    ('M-24','Second Floor','Transfer Interlock','Running','BBJO-00127'),
  ];
  @override Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Machines',style:TextStyle(fontSize:28,fontWeight:FontWeight.w700)),SizedBox(height:5),Text('Machine master, status and current job allocation',style:TextStyle(color:_muted,fontSize:13))])),_primary('Add Machine',Icons.add,()=>())]),
    const SizedBox(height:24),
    LayoutBuilder(builder:(_,c)=>c.maxWidth<760?const Wrap(spacing:12,runSpacing:12,children:[_Stat('Total','31',Icons.precision_manufacturing_outlined),_Stat('Running','27',Icons.play_circle_outline),_Stat('Idle','2',Icons.pause_circle_outline),_Stat('Maintenance','1',Icons.build_outlined)]):const Row(children:[Expanded(child:_Stat('Total','31',Icons.precision_manufacturing_outlined)),SizedBox(width:12),Expanded(child:_Stat('Running','27',Icons.play_circle_outline)),SizedBox(width:12),Expanded(child:_Stat('Idle','2',Icons.pause_circle_outline)),SizedBox(width:12),Expanded(child:_Stat('Maintenance','1',Icons.build_outlined))])),
    const SizedBox(height:20),
    _Card(title:'Machine Register',child:Column(children:[_search('Search machine, floor, type or job...'),const SizedBox(height:14),...machines.map((m)=>Container(padding:const EdgeInsets.symmetric(vertical:14),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF1D2933)))),child:Row(children:[
      SizedBox(width:65,child:Text(m.$1,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12))),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.$3,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600)),Text(m.$2,style:const TextStyle(color:_muted,fontSize:9))])),
      SizedBox(width:110,child:Text(m.$5,textAlign:TextAlign.right,style:const TextStyle(color:_muted,fontSize:10))),
      const SizedBox(width:14),_Status(m.$4),const SizedBox(width:8),const Icon(Icons.more_horiz,color:_muted,size:18),
    ])))])),
  ]));
}
