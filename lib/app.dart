import 'package:flutter/material.dart';
import 'ui/radar/radar_screen.dart';

class WiFiDropApp extends StatelessWidget {
  const WiFiDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Drop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0785F8),
          primary: const Color(0xFF0785F8),
        ),
        useMaterial3: true,
      ),
      home: const RadarScreen(),
    );
  }
}
