import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// โหมดธีมของแอพ (สว่าง/มืด) — จำค่าที่เลือกไว้ในเครื่อง เปิดแอพใหม่ก็ยังเป็นโหมดเดิม
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light; // ค่าเริ่มต้น = ธีมสว่าง
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_key) == 'dark') state = ThemeMode.dark;
    } catch (_) {
      // อ่านค่าที่จำไว้ไม่ได้ ก็ใช้ธีมสว่างตามเดิม
    }
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, dark ? 'dark' : 'light');
    } catch (_) {
      // จำค่าไม่ได้ก็ไม่เป็นไร ธีมยังเปลี่ยนในรอบนี้
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
