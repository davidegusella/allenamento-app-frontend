import 'package:allenamentofrontend/providers/timer/serieTimeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:allenamentofrontend/pages/allenamentoPage.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allenamento App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,  // Consiglio di abilitare Material 3 per avere l'UI più moderna
      ),
      home: AllenamentoPage(),
    );
  }
}
