import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialiser Firebase une fois qu'il ya les fichiers de config
  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: InventoryLiteApp()));
}

class InventoryLiteApp extends StatelessWidget {
  const InventoryLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InventoryLite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('InventoryLite - Setup Initial Ok')),
      ),
    );
  }
}
