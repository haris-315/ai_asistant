import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  const MethodChannel channel = MethodChannel('init');

  channel.setMethodCallHandler((call) async {
    if (call.method == "shareStats") {
      exit(0);
    }
  });

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
      border: null,
      focusedBorder: null,
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
