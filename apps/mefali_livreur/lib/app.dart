import 'package:flutter/material.dart';
import 'package:mefali_design/mefali_design.dart';

class MefaliLivreurApp extends StatelessWidget {
  const MefaliLivreurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mefali Livreur',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('mefali Livreur'))),
    );
  }
}
