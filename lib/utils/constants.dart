import 'package:flutter/material.dart';

class Constants {
  // ⚠️ PAKAI API LOGIN SEDERHANA INI
  static const String baseUrl = 'http://192.168.18.8/dhini_beauty/api';
  
  // Premium Rich Beauty & Spa Aesthetics (Same family but richer/warmer, not pale)
  static const Color primaryColor = Color(0xFFD94B68); // Rich Vibrant Rose
  static const Color secondaryColor = Color(0xFFFFD5E0); // Luminous Soft Rose
  static const Color backgroundColor = Color(0xFFFFF8F9); // Warm Premium Light Blush
  static const Color textDark = Color(0xFF1E1014); // Very Dark Chocolate-Plum Gray
  static const Color textLight = Color(0xFF7D6B70); // Warm Taupe Gray
  
  // Gradient for background - gorgeous and glowing
  static const List<Color> backgroundGradient = [
    Color(0xFFFFF5F7),
    Color(0xFFFCD3DE),
  ];

  static const List<String> jamTersedia = [
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
  ];
}