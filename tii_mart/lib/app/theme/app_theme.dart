import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// สีตามธีมที่ออกแบบไว้ใน wireframe
class AppColors {
  static const background = Color(0xFFF2EFE7); // main color
  static const navbar = Color(0xFF66A3BF); // navbar
  static const primary = Color(0xFF3368A0); // button / text
  static const card = Color(0xFFFFFFFF); // card / box

  // ===== ธีมมืด =====
  static const darkBackground = Color(0xFF12171A);
  static const darkNavbar = Color(0xFF1E3340);
  static const darkCard = Color(0xFF1F262B);
  static const darkPrimary = Color(0xFF8DB8E8); // ปุ่ม/ตัวอักษรเด่นบนพื้นมืด
  static const darkPlaceholder = Color(0xFF343C42);
}

/// ตัวช่วยเลือกสีตามธีมปัจจุบัน (ธีมสว่างได้สีเดิมทุกค่า)
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// พื้นหลังช่องว่างของรูป / เส้นขอบอ่อน: สว่างใช้สีเดิมที่ส่งมา มืดใช้สีเทาเข้ม
  Color placeholder(Color light) => isDark ? AppColors.darkPlaceholder : light;

  /// สีดำโปร่ง (ธีมสว่าง) ↔ สีขาวโปร่ง (ธีมมืด)
  Color get ink12 => isDark ? Colors.white12 : Colors.black12;
  Color get ink26 => isDark ? Colors.white24 : Colors.black26;
  Color get ink38 => isDark ? Colors.white38 : Colors.black38;
  Color get ink45 => isDark ? Colors.white54 : Colors.black45;
  Color get ink54 => isDark ? Colors.white60 : Colors.black54;

  /// สีสื่อความหมาย (แดง/เขียว/ส้ม) ธีมมืดทำให้สว่างขึ้นให้อ่านออก
  Color tone(Color c) => isDark ? Color.lerp(c, Colors.white, 0.45)! : c;
}

class AppTheme {
  // ===== เปลี่ยนฟอนต์ทั้งแอพที่นี่ที่เดียว =====
  // หัวข้อ/ปุ่ม: Prompt  |  เนื้อหา: Sarabun
  // ตัวเลือกอื่น: GoogleFonts.kanit, mitr, notoSansThai, ibmPlexSansThai, sarabun
  static TextStyle heading({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.prompt(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static TextStyle body({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.sarabun(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static TextTheme _textTheme([Brightness brightness = Brightness.light]) {
    final dark = brightness == Brightness.dark;
    final base = GoogleFonts.sarabunTextTheme(
      ThemeData(useMaterial3: true, brightness: brightness).textTheme,
    );
    return base.copyWith(
      headlineMedium: heading(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: dark ? AppColors.darkPrimary : AppColors.primary,
      ),
      headlineSmall: heading(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: heading(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: heading(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: heading(fontSize: 16, fontWeight: FontWeight.w500),
      // ขนาดตัวอักษรใหญ่ขึ้นเล็กน้อย รองรับผู้สูงอายุ
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 16),
      bodySmall: base.bodySmall?.copyWith(fontSize: 14),
      labelLarge: heading(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navbar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle:
            heading(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0x4D66A3BF), // สี navbar โปร่งใส 30%
      ),
      textTheme: _textTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: heading(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: heading(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      onPrimary: const Color(0xFF0B1E33),
      surface: AppColors.darkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      cardTheme: const CardThemeData(color: AppColors.darkCard),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkNavbar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle:
            heading(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0x4D66A3BF),
      ),
      textTheme: _textTheme(Brightness.dark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: const Color(0xFF0B1E33),
          disabledBackgroundColor: AppColors.darkPrimary,
          disabledForegroundColor: const Color(0xFF0B1E33),
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: heading(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: heading(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
