import 'package:flutter/material.dart';
import 'package:mefali_design/mefali_design.dart';

class MefaliB2cApp extends StatelessWidget {
  const MefaliB2cApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mefali',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('mefali B2C'),
        ),
      ),
    );
  }
}
