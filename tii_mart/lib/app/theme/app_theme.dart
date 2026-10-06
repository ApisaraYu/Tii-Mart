import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// สีตามธีมที่ออกแบบไว้ใน wireframe
class AppColors {
  static const background = Color(0xFFF2EFE7); // main color
  static const navbar = Color(0xFF66A3BF); // navbar
  static const primary = Color(0xFF3368A0); // button / text
  static const card = Color(0xFFFFFFFF); // card / box
}

class AppTheme {
  // ===== เปลี่ยนฟอนต์ทั้งแอพที่นี่ที่เดียว =====
  // หัวข้อ/ปุ่ม: Prompt  |  เนื้อหา: Sarabun
  // ตัวเลือกอื่น: GoogleFonts.kanit, mitr, notoSansThai, ibmPlexSansThai, sarabun
  static TextStyle heading({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.prompt(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static TextStyle body({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.sarabun(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static TextTheme _textTheme() {
    final base =
        GoogleFonts.sarabunTextTheme(ThemeData(useMaterial3: true).textTheme);
    return base.copyWith(
      headlineMedium: heading(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
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
}
