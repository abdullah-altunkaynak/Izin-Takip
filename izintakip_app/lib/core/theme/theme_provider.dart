import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = "theme_mode"; // system light dark

final themeControllerProvider =
StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_themeKey) ?? "system";
    state = switch (v) {
      "light" => ThemeMode.light,
      "dark" => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final sp = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => "light",
      ThemeMode.dark => "dark",
      _ => "system",
    };
    await sp.setString(_themeKey, v);
  }
}
