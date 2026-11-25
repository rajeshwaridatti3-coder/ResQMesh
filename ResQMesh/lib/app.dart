import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

class ResQMeshApp extends StatelessWidget {
  const ResQMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101B35);
    return MaterialApp(
      title: 'ResQMesh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE84B4B)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy, foregroundColor: Colors.white,
          centerTitle: false, elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
