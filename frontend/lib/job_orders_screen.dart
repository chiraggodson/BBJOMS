
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


class JobOrdersPage extends StatefulWidget {
  const JobOrdersPage({super.key});
  @override State<JobOrdersPage> createState() => _JobOrdersPageState();
}
class _JobOrdersPageState extends State<JobOrdersPage> {
  final jobs = const [
    ('BBJO-00128','Sandhir Textiles','Single Jersey 180 GSM','420 kg','Running'),
    ('BBJO-00127','ABC Fabrics','Interlock 220 GSM','680 kg','Running'),
    ('BBJO-00126','Modern Knits','2-Way Stretch 180 GSM','310 kg','Yarn Needed'),
    ('BBJO-00125','ST Traders','Cotton Lycra 200 GSM','520 kg','Paused'),
    ('BBJO-00124','Fashion Mills','Polyester Rib 160 GSM','780 kg','Closed'),
  ];
  @override Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Job Orders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          SizedBox(height: 5), Text('Create, track and manage knitting job orders', style: TextStyle(color: _muted, fontSize: 13)),
        ])),
        _primary('New Job Order', Icons.add_task, () => _dialog(context)),
      ]),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (_, c) => c.maxWidth < 760
        ? const Wrap(spacing: 12, runSpacing: 12, children: [_Stat('Active Jobs','12',Icons.assignment_outlined),_Stat('Running','8',Icons.play_circle_outline),_Stat('Yarn Needed','3',Icons.warning_amber_outlined),_Stat('Closed Today','4',Icons.check_circle_outline)])
        : const Row(children: [
            Expanded(child:_Stat('Active Jobs','12',Icons.assignment_outlined)),SizedBox(width:12),
            Expanded(child:_Stat('Running','8',Icons.play_circle_outline)),SizedBox(width:12),
            Expanded(child:_Stat('Yarn Needed','3',Icons.warning_amber_outlined)),SizedBox(width:12),
            Expanded(child:_Stat('Closed Today','4',Icons.check_circle_outline)),
          ])),
      const SizedBox(height:20),
      _Card(title:'Job Order Register', child: Column(children:[
        _search('Search job, party, fabric or status...'), const SizedBox(height:16),
        ...jobs.map((j)=>Container(
          padding: const EdgeInsets.symmetric(vertical:15),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1D2933)))),
          child: Row(children:[
            SizedBox(width:105, child:Text(j.$1,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:12))),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(j.$2,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),const SizedBox(height:3),Text(j.$3,style:const TextStyle(color:_muted,fontSize:10))])),
            SizedBox(width:90,child:Text(j.$4,textAlign:TextAlign.right,style:const TextStyle(fontSize:11))),
            const SizedBox(width:14), _Status(j.$5), const SizedBox(width:8),
            const Icon(Icons.more_horiz,color:_muted,size:18),
          ]),
        )),
      ])),
    ]),
  );
  void _dialog(BuildContext context) => showDialog(context:context,builder:(_)=>AlertDialog(
    backgroundColor:_panel,title:const Text('New Job Order'),
    content:const SizedBox(width:520,child:Text('Job order form is ready for the next database-connected pass.\n\nWe will connect party, fabric, yarn requirements, machines and target quantity here.')),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close')),_primary('Create',Icons.check,()=>Navigator.pop(context))],
  ));
}
