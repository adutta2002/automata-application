import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFFF43F5E);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  
  // Modern Light Sidebar
  static const Color sidebarColor = Color(0xFFFFFFFF);
  static const Color sidebarBorderColor = Color(0xFFE2E8F0);
  static const Color sidebarTextColor = Color(0xFF64748B);
  static const Color sidebarActiveColor = Color(0xFF6366F1);
  static const Color sidebarHoverColor = Color(0xFFF1F5F9);
  
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1E293B);
  static const Color mutedTextColor = Color(0xFF64748B);
  
  // Table Colors
  static const Color tableHeaderColor = Color(0xFFF8FAFC);
  static const Color tableRowEvenColor = Colors.white;
  static const Color tableRowOddColor = Color(0xFFFAFAFA);
  static const Color tableHoverColor = Color(0xFFEEF2FF);
  static const Color tableBorderColor = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
