import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:allenamentofrontend/pages/allenamentoPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allenamento App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AnimatedSplashScreen(
        duration: 1,
        splash: SizedBox(
          height: 10,
          child: Image.asset("lib/assets/iconwb.png"),
        ),
        nextScreen: AllenamentoPage(),
        splashTransition: SplashTransition.scaleTransition,
        backgroundColor: Colors.blue,
      ),
    );
  }
}