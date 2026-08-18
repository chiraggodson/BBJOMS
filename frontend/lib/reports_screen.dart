
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


class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Reports',style:TextStyle(fontSize:28,fontWeight:FontWeight.w700)),SizedBox(height:5),Text('Factory performance, production and stock reports',style:TextStyle(color:_muted,fontSize:13))])),FilledButton.icon(onPressed:()=>(),icon:const Icon(Icons.download_outlined,size:18),label:const Text('Export'))]),
    const SizedBox(height:24),
    LayoutBuilder(builder:(_,c)=>c.maxWidth<760?const Wrap(spacing:12,runSpacing:12,children:[_Stat('Production Today','1,284 kg',Icons.trending_up),_Stat('This Month','28,460 kg',Icons.calendar_month_outlined),_Stat('Efficiency','87%',Icons.speed_outlined),_Stat('Job Work','₹ 4.82 L',Icons.currency_rupee)]):const Row(children:[Expanded(child:_Stat('Production Today','1,284 kg',Icons.trending_up)),SizedBox(width:12),Expanded(child:_Stat('This Month','28,460 kg',Icons.calendar_month_outlined)),SizedBox(width:12),Expanded(child:_Stat('Efficiency','87%',Icons.speed_outlined)),SizedBox(width:12),Expanded(child:_Stat('Job Work','₹ 4.82 L',Icons.currency_rupee))])),
    const SizedBox(height:20),
    _Card(title:'Reports',child:Column(children:[
      _report(Icons.precision_manufacturing_outlined,'Production Report','Machine-wise and date-wise production','Open report'),
      _report(Icons.assignment_outlined,'Job Order Report','Job status, target, production and balance','Open report'),
      _report(Icons.all_inclusive,'Yarn Ledger','Receipts, issues, returns and live balance','Open report'),
      _report(Icons.people_outline,'Party Ledger','Party-wise material and job-work transactions','Open report'),
      _report(Icons.layers_outlined,'Fabric Stock Report','Finished fabric stock and dispatch','Open report'),
      _report(Icons.speed_outlined,'Machine Efficiency','RPM, production and utilisation analysis','Open report'),
    ])),
  ]));
  Widget _report(IconData icon,String title,String sub,String action)=>Container(padding:const EdgeInsets.symmetric(vertical:15),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF1D2933)))),child:Row(children:[
    Container(width:40,height:40,decoration:BoxDecoration(color:_teal.withValues(alpha:.10),borderRadius:BorderRadius.circular(9)),child:Icon(icon,color:_teal,size:20)),const SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:12)),const SizedBox(height:3),Text(sub,style:const TextStyle(color:_muted,fontSize:10))])),
    Text(action,style:const TextStyle(color:_teal,fontSize:10,fontWeight:FontWeight.w600)),const SizedBox(width:6),const Icon(Icons.chevron_right,color:_muted,size:18)
  ]));
}
