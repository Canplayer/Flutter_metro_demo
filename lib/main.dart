import 'package:flutter/material.dart';
import 'package:metro_demo/splashscreen_page.dart';
import 'package:metro_ui/app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MetroApp(
      navigatorObservers: [],
      
      title: 'Flutter Demo',
      //229,20,0
      metroColor: Color.fromARGB(255, 229, 20, 0),
      //themeMode: MetroThemeMode.light,
      useWVGAMode: true,
      home: ArtisticTextPage(),
    );
  }
}

