// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,

      // Primary Colors
      primaryColor: const Color(0xFF20429C),
      primarySwatch: Colors.blue,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF20429C),
        brightness: brightness,
      ),

      // Scaffold Background
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : Colors.grey[50],

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF20429C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF20429C),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
          side: BorderSide(
            color: isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: isDark ? Colors.white : Colors.black,
        iconColor: isDark ? Colors.grey[400] : Colors.grey[700],
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        thickness: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        headlineMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        headlineSmall: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleSmall: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        bodyLarge: TextStyle(
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
        bodySmall: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor:
            isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[700],
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF4A6EC5).withOpacity(0.2)
            : const Color(0xFF20429C).withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[600] : Colors.grey[700],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
            );
          }
          return IconThemeData(
            color: isDark ? Colors.grey[600] : Colors.grey[700],
          );
        }),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontSize: 14,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:
            isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
        foregroundColor: Colors.white,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),

      // Badge Theme
      badgeTheme: const BadgeThemeData(
        backgroundColor: Colors.red,
        textColor: Colors.white,
      ),
    );
  }
}
