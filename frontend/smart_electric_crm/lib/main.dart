import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Electric CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Electric CRM')),
        // Добавили const перед Center - теперь вся ветка виджетов статична
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 80, color: Colors.amber),
              SizedBox(height: 20),
              Text(
                'Система готова к работе!',
                style: TextStyle(fontSize: 24),
              ),
              Text('Windows + Android + Web'),
            ],
          ),
        ),
      ),
    );
  }
}
