import 'package:flutter/material.dart';
import 'app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Hero(),
          SizedBox(height: 20),
          _Kpis(),
          SizedBox(height: 20),
          _OperationsGrid(),
          SizedBox(height: 20),
          _Attention(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: BBTheme.panel,
        border: Border.all(color: BBTheme.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(width: 5, height: 64, color: BBTheme.red),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('B&B KNITFAB', style: TextStyle(color: BBTheme.redLight, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
                SizedBox(height: 5),
                Text('FACTORY COMMAND CENTER', style: TextStyle(color: BBTheme.text, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: .2)),
                SizedBox(height: 4),
                Text('Live operational view of jobs, production, machines and material.', style: TextStyle(color: BBTheme.muted, fontSize: 18)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: BBTheme.black3, border: Border.all(color: BBTheme.border), borderRadius: BorderRadius.circular(5)),
            child: const Row(children: [
              Icon(Icons.circle, size: 8, color: BBTheme.green),
              SizedBox(width: 8),
              Text('SYSTEM ONLINE', style: TextStyle(color: BBTheme.green, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .7)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis();
  @override
  Widget build(BuildContext context) {
    const data = [
      ('ACTIVE JOBS', '12', '3 NEED ATTENTION', Icons.assignment_outlined, BBTheme.red),
      ('PRODUCTION TODAY', '1,284 KG', '+8.4% VS YESTERDAY', Icons.trending_up, BBTheme.green),
      ('YARN STOCK', '8,462 KG', '24 LOTS AVAILABLE', Icons.inventory_2_outlined, BBTheme.red),
      ('MACHINES RUNNING', '27 / 31', '87% AVAILABILITY', Icons.precision_manufacturing_outlined, BBTheme.green),
    ];
    return LayoutBuilder(builder: (_, c) {
      final n = c.maxWidth < 760 ? 2 : 4;
      final gap = 12.0;
      final w = (c.maxWidth - gap * (n - 1)) / n;
      return Wrap(spacing: gap, runSpacing: gap, children: data.map((d) => SizedBox(width: w, child: _Kpi(title:d.$1, value:d.$2, sub:d.$3, icon:d.$4, accent:d.$5))).toList());
    });
  }
}

class _Kpi extends StatelessWidget {
  final String title, value, sub; final IconData icon; final Color accent;
  const _Kpi({required this.title, required this.value, required this.sub, required this.icon, required this.accent});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: BBTheme.panel, border: Border.all(color: BBTheme.border), borderRadius: BorderRadius.circular(7)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 32, height: 3, color: accent), const Spacer(), Icon(icon, size: 19, color: accent)]),
      const SizedBox(height: 17),
      Text(title, style: const TextStyle(color: BBTheme.muted, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .8)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: BBTheme.text, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -.5)),
      const SizedBox(height: 5),
      Text(sub, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .4)),
    ]),
  );
}

class _OperationsGrid extends StatelessWidget {
  const _OperationsGrid();
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    if (c.maxWidth < 1000) return const Column(children: [_Production(), SizedBox(height: 14), _Machines()]);
    return const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _Production()), SizedBox(width: 14), Expanded(flex: 2, child: _Machines())]);
  });
}

class _Panel extends StatelessWidget {
  final String title, action; final Widget child;
  const _Panel({required this.title, required this.action, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: BBTheme.panel, border: Border.all(color: BBTheme.border), borderRadius: BorderRadius.circular(7)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(title, style: const TextStyle(color: BBTheme.text, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .2)), const Spacer(), Text(action, style: const TextStyle(color: BBTheme.redLight, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .5))]),
      const SizedBox(height: 13),
      child,
    ]),
  );
}

class _Production extends StatelessWidget {
  const _Production();
  static const rows = [('BBJO-00128','Sandhir Textiles','Single Jersey 180 GSM',86.0,420.0),('BBJO-00127','ABC Fabrics','Interlock 220 GSM',112.0,680.0),('BBJO-00125','ST Traders','Cotton Lycra 200 GSM',34.0,520.0),('BBJO-00124','Fashion Mills','Polyester Rib 160 GSM',0.0,780.0)];
  @override
  Widget build(BuildContext context) => _Panel(title:'TODAY\'S PRODUCTION', action:'VIEW ALL', child: Column(children: rows.map((r) => _ProdRow(r)).toList()));
}
class _ProdRow extends StatelessWidget {
  final (String,String,String,double,double) r; const _ProdRow(this.r);
  @override
  Widget build(BuildContext context) {
    final p = r.$5 == 0 ? 0.0 : (r.$4/r.$5).clamp(0.0,1.0);
    return Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BBTheme.borderSoft))), child: Column(children: [
      Row(children: [SizedBox(width:90, child: Text(r.$1, style: const TextStyle(color: BBTheme.text, fontSize: 14, fontWeight: FontWeight.w900))), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.$2, style: const TextStyle(color: BBTheme.text, fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height:2), Text(r.$3, style: const TextStyle(color: BBTheme.muted, fontSize: 13))])), Text('${r.$4.toStringAsFixed(0)} / ${r.$5.toStringAsFixed(0)} KG', style: const TextStyle(color: BBTheme.text, fontSize: 14, fontWeight: FontWeight.w800))]),
      const SizedBox(height:8), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value:p, minHeight:5, backgroundColor:BBTheme.black4, color:p==0?BBTheme.subtle:BBTheme.red)),
    ]));
  }
}

class _Machines extends StatelessWidget {
  const _Machines();
  @override
  Widget build(BuildContext context) => _Panel(title:'MACHINE STATUS', action:'VIEW MACHINES', child: Column(children: [
    _Machine('RUNNING','27',BBTheme.green,Icons.play_circle_outline),
    _Machine('IDLE','2',BBTheme.amber,Icons.pause_circle_outline),
    _Machine('MAINTENANCE','1',BBTheme.red,Icons.build_outlined),
    _Machine('STOPPED','1',BBTheme.red,Icons.stop_circle_outlined),
    const SizedBox(height:12),
    Row(children: [Expanded(child: ClipRRect(borderRadius:BorderRadius.circular(3), child: const LinearProgressIndicator(value:27/31,minHeight:7,backgroundColor:BBTheme.black4,color:BBTheme.red))), const SizedBox(width:10), const Text('87%',style:TextStyle(color:BBTheme.text,fontSize:13,fontWeight:FontWeight.w900))]),
  ]));
}
class _Machine extends StatelessWidget { final String label,value; final Color color; final IconData icon; const _Machine(this.label,this.value,this.color,this.icon); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[Icon(icon,size:17,color:color),const SizedBox(width:10),Expanded(child:Text(label,style:const TextStyle(color:BBTheme.muted,fontSize:13,fontWeight:FontWeight.w700))),Text(value,style:TextStyle(color:color,fontSize:16,fontWeight:FontWeight.w900))])); }

class _Attention extends StatelessWidget {
  const _Attention();
  @override
  Widget build(BuildContext context) => _Panel(title:'MANAGEMENT ATTENTION', action:'4 OPEN ITEMS', child: LayoutBuilder(builder: (_, c) {
    final items=[('YARN','BBJO-00126 requires yarn before production can start.',Icons.inventory_2_outlined),('MAINTENANCE','1 machine is currently under maintenance.',Icons.build_outlined),('PRODUCTION','2 active jobs are below today\'s planned output.',Icons.trending_down),('STOCK','Spandex 40D is approaching low-stock level.',Icons.warning_amber_outlined)];
    return Wrap(spacing:10,runSpacing:10,children:items.map((i)=>SizedBox(width:c.maxWidth<700?c.maxWidth:(c.maxWidth-10)/2,child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:BBTheme.black2,border:Border.all(color:BBTheme.borderSoft),borderRadius:BorderRadius.circular(5)),child:Row(children:[Container(width:34,height:34,decoration:BoxDecoration(color:const Color(0x22E53935),borderRadius:BorderRadius.circular(5)),child:Icon(i.$3,color:BBTheme.redLight,size:17)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(i.$1,style:const TextStyle(color:BBTheme.redLight,fontSize:11,fontWeight:FontWeight.w900,letterSpacing:.8)),const SizedBox(height:3),Text(i.$2,style:const TextStyle(color:BBTheme.text,fontSize:12,height:1.35))]))])))).toList());
  }));
}
