import 'package:flutter/material.dart';
import 'screens/medal_demo_screen.dart';

void main() {
  runApp(const MedalDemoApp());
}

class MedalDemoApp extends StatelessWidget {
  const MedalDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Medal Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const MedalDemoScreen(),
    );
  }
}


