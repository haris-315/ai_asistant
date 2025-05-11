import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: const Color(0xFF6200EA),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: CardTheme(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6200EA), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}