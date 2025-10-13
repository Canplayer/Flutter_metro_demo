import 'package:flutter/material.dart';
import 'package:metro_demo/launcher.dart';
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
      color: Colors.red,
      //themeMode: MetroThemeMode.light,
      useWVGAMode: true,
      home: ArtisticTextPage(),
    );
  }
}

