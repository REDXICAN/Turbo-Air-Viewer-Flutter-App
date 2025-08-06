import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      primaryColor: const Color(0xFF20429C),

      // Fixed color scheme for dark mode
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Color(0xFF4A6EC5),
              secondary: Color(0xFF4A6EC5),
              surface: Color(0xFF1E1E1E),
              surfaceContainerHighest: Color(0xFF2C2C2C),
              onSurface: Colors.white,
              onPrimary: Colors.white,
              error: Color(0xFFCF6679),
            )
          : ColorScheme.fromSeed(
              seedColor: const Color(0xFF20429C),
              brightness: brightness,
            ),

      useMaterial3: true,
      fontFamily: 'SF Pro Display',

      // Scaffold background
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : Colors.grey[50],

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: isDark ? 1 : 2,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
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

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontSize: 16,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? const Color(0xFF4A6EC5) : const Color(0xFF20429C);
          }
          return isDark ? Colors.grey[600] : Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? const Color(0xFF4A6EC5).withOpacity(0.5)
                : const Color(0xFF20429C).withOpacity(0.5);
          }
          return isDark ? Colors.grey[800] : Colors.grey[300];
        }),
      ),
    );
  }
}
