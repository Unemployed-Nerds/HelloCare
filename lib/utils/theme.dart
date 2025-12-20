import 'package:flutter/material.dart';

class AppTheme {
  // New Color Palette - Dark Theme
  // Shadow Grey: #232020
  // Chocolate Plum: #553739
  // Toffee Brown: #955e42
  // Palm Leaf: #9c914f
  // Palm Leaf 2: #748e54
  
  // Primary Colors - Palm Leaf variants
  static const Color primaryGreen = Color(0xFF9C914F); // Palm Leaf - main primary
  static const Color primaryGreenLight = Color(0xFFB5AB6F); // Lighter Palm Leaf
  static const Color primaryGreenDark = Color(0xFF748E54); // Palm Leaf 2
  static const Color accentGreen = Color(0xFFA8B57A); // Light green accent
  static const Color lightGreen = Color(0xFFC4C99A); // Very light green
  static const Color darkGreen = Color(0xFF5F6F44); // Darker Palm Leaf 2
  
  // Background Colors - Shadow Grey and Chocolate Plum
  static const Color backgroundDark = Color(0xFF232020); // Shadow Grey - main background
  static const Color surfaceDark = Color(0xFF553739); // Chocolate Plum - dark surface
  static const Color surfaceVariant = Color(0xFF6B4A4D); // Lighter Chocolate Plum variant
  static const Color backgroundGreen = Color(0xFF2A2B1F); // Dark green tint (Shadow Grey + Palm Leaf)
  
  // Glassmorphism Colors
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color glassBlack = Color(0xFF000000);
  
  // Text Colors for Dark Theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF757575);
  
  // Additional Colors - Dark Mode
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFF4A4A4A);
  static const Color darkGrey = Color(0xFF3A3A3A); // Adjusted for new palette
  static const Color errorRed = Color(0xFF955E42); // Toffee Brown for errors/warnings
  static const Color dangerRed = Color(0xFFDC3545); // Danger red for logout and critical actions
  
  // Accent Colors - Using palette colors
  static const Color accentPink = Color(0xFF955E42); // Toffee Brown
  static const Color accentBlue = Color(0xFF748E54); // Palm Leaf 2 variant
  static const Color accentYellow = Color(0xFF9C914F); // Palm Leaf
  static const Color accentPurple = Color(0xFF553739); // Chocolate Plum
  
  // Divider and Border Colors - Dark Mode
  static const Color divider = Color(0xFF3A3535); // Darker Shadow Grey variant
  static const Color border = Color(0xFF4A3F3F); // Shadow Grey + Chocolate Plum mix
  
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primaryGreen,
      onPrimary: black,
      primaryContainer: darkGreen,
      onPrimaryContainer: lightGreen,
      secondary: accentPink, // Toffee Brown
      onSecondary: white,
      secondaryContainer: Color(0xFF6B4A3D), // Darker Toffee Brown
      onSecondaryContainer: lightGreen,
      tertiary: accentBlue, // Palm Leaf 2
      onTertiary: white,
      error: errorRed, // Toffee Brown
      onError: white,
      errorContainer: Color(0xFF6B4A3D), // Darker Toffee Brown
      onErrorContainer: lightGreen,
      surface: surfaceDark,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceVariant: surfaceVariant,
      outline: border,
      outlineVariant: divider,
      shadow: black.withOpacity(0.5),
      scrim: black.withOpacity(0.6),
      inverseSurface: textPrimary,
      onInverseSurface: surfaceDark,
      inversePrimary: primaryGreenDark,
      surfaceTint: primaryGreen.withOpacity(0.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      
      // Scaffold
      scaffoldBackgroundColor: backgroundDark,
      
      // AppBar - Dark Mode with Glassmorphism
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: white,
          size: 28,
        ),
      ),
      
      // Cards - Dark Mode with Glassmorphism and Neon Glow
      cardTheme: CardThemeData(
        color: surfaceVariant.withOpacity(0.4),
        elevation: 0,
        shadowColor: primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Buttons - Webtoon Style with Neon Glow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          shadowColor: primaryGreen.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: MaterialStateProperty.all(0),
        ),
      ),
      
      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: textDisabled,
          fontSize: 14,
        ),
      ),
      
      // Drawer - Dark Mode with Glassmorphism
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceDark.withOpacity(0.95),
        elevation: 0,
        scrimColor: Colors.black.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      
      // List Tile - Webtoon Style
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primaryGreen.withOpacity(0.15),
        iconColor: textPrimary,
        textColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      
      // Dialog - Dark Mode with Glassmorphism and Neon Glow
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceVariant.withOpacity(0.9),
        elevation: 0,
        shadowColor: primaryGreen.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: white.withOpacity(0.2),
            width: 2,
          ),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceVariant,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryGreen.withOpacity(0.2),
        disabledColor: surfaceDark,
        labelStyle: TextStyle(color: textPrimary),
        secondaryLabelStyle: TextStyle(color: black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Floating Action Button with Neon Glow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 8,
        indicatorColor: primaryGreen.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: primaryGreen, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      
      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceDark,
        selectedIconTheme: IconThemeData(color: primaryGreen, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 24),
        selectedLabelTextStyle: TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: textSecondary, fontSize: 12),
      ),
      
      // Typography - Webtoon Style (Bold, Rounded)
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 57, fontWeight: FontWeight.w800, letterSpacing: -0.25),
        displayMedium: TextStyle(color: textPrimary, fontSize: 45, fontWeight: FontWeight.w800),
        displaySmall: TextStyle(color: textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
        titleSmall: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        labelMedium: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        labelSmall: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: surfaceVariant,
        circularTrackColor: surfaceVariant,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return darkGrey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen.withOpacity(0.5);
          }
          return surfaceVariant;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(black),
        side: BorderSide(color: border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return border;
        }),
      ),
    );
  }
  
  // Legacy light theme (kept for compatibility, but not used)
  static ThemeData get lightTheme => darkTheme;
}

