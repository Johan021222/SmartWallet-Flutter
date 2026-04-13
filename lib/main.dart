import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';

void main() {
  // Inicializar databaseFactory para plataformas de escritorio (Windows, Linux, macOS)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const SmartWalletApp());
}

class SmartWalletApp extends StatelessWidget {
  const SmartWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartWallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomeScreen(), // Llamamos a nuestra pantalla principal
    );
  }
}
