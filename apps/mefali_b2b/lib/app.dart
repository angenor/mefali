import 'package:flutter/material.dart';
import 'package:mefali_design/mefali_design.dart';

class MefaliB2bApp extends StatelessWidget {
  const MefaliB2bApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mefali B2B',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('mefali B2B'),
        ),
      ),
    );
  }
}
