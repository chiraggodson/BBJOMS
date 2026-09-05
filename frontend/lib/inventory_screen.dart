
import 'package:flutter/material.dart';
import 'yarn_receipt_screen.dart';

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


class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});
  final items=const[
    ('Finished Fabric','Single Jersey 180 GSM','2,840 kg','Good'),
    ('Finished Fabric','Interlock 220 GSM','1,920 kg','Good'),
    ('Yarn','Polyester 75D','1,842 kg','Available'),
    ('Yarn','Cotton 30s','932 kg','Available'),
    ('Yarn','Spandex 40D','238 kg','Low Stock'),
  ];
  @override Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Inventory',style:TextStyle(fontSize:28,fontWeight:FontWeight.w700)),SizedBox(height:5),Text('Yarn, fabric and stock movement overview',style:TextStyle(color:_muted,fontSize:13))])),Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _primary(
          'Receive Yarn',
          Icons.south_west,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const YarnReceiptScreen(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _primary('Stock Adjustment', Icons.tune, () {}),
      ],
    )]),
    const SizedBox(height:24),
    LayoutBuilder(builder:(_,c)=>c.maxWidth<760?const Wrap(spacing:12,runSpacing:12,children:[_Stat('Yarn Stock','5,480 kg',Icons.all_inclusive),_Stat('Fabric Stock','4,760 kg',Icons.layers_outlined),_Stat('Receipts Today','730 kg',Icons.south_west),_Stat('Issues Today','410 kg',Icons.north_east)]):const Row(children:[Expanded(child:_Stat('Yarn Stock','5,480 kg',Icons.all_inclusive)),SizedBox(width:12),Expanded(child:_Stat('Fabric Stock','4,760 kg',Icons.layers_outlined)),SizedBox(width:12),Expanded(child:_Stat('Receipts Today','730 kg',Icons.south_west)),SizedBox(width:12),Expanded(child:_Stat('Issues Today','410 kg',Icons.north_east))])),
    const SizedBox(height:20),
    _Card(title:'Stock Overview',child:Column(children:[_search('Search item or material...'),const SizedBox(height:14),...items.map((i)=>Container(padding:const EdgeInsets.symmetric(vertical:14),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF1D2933)))),child:Row(children:[
      const CircleAvatar(radius:17,backgroundColor:Color(0xFF153A38),child:Icon(Icons.inventory_2_outlined,color:_teal,size:17)),const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(i.$1,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:11)),Text(i.$2,style:const TextStyle(color:_muted,fontSize:10))])),
      SizedBox(width:90,child:Text(i.$3,textAlign:TextAlign.right,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:11))),const SizedBox(width:14),_Status(i.$4),
    ])))])),
    const SizedBox(height:20),
    _Card(title:'Recent Stock Movements',child:Column(children:[
      _move(Icons.south_west,'Yarn Received','A.K. Goyal Hosiery','420 kg'),
      _move(Icons.north_east,'Yarn Issued','BBJO-00128','180 kg'),
      _move(Icons.layers_outlined,'Fabric Produced','M-24 / BBJO-00127','112 kg'),
      _move(Icons.keyboard_return,'Yarn Returned','BBJO-00125','24 kg'),
    ])),
  ]));
  Widget _move(IconData icon,String a,String b,String c)=>Container(padding:const EdgeInsets.symmetric(vertical:12),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF1D2933)))),child:Row(children:[Icon(icon,color:_teal,size:18),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600)),Text(b,style:const TextStyle(color:_muted,fontSize:10))])),Text(c,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]));
}
