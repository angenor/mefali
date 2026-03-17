import 'package:flutter/material.dart';
import 'package:mefali_design/mefali_design.dart';

class MefaliAdminApp extends StatelessWidget {
  const MefaliAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mefali Admin',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('mefali Admin'))),
    );
  }
}
