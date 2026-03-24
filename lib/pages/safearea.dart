import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';

class SafeAreaPage extends StatelessWidget {
  const SafeAreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: SafeArea(child: 
        Container(
          color: Colors.blue,
          child: const Center(
            child: Text(
              'SafeAeroPage',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
      ),
      
      
    );
  }
}