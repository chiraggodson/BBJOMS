import 'package:flutter/material.dart';

class YarnReceiptScreen extends StatelessWidget {
  const YarnReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Yarn Receipt is now available from Inventory.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}