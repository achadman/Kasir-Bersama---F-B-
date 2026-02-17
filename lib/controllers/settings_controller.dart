import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController {
  // Singleton instance
  static final SettingsController instance = SettingsController._internal();

  factory SettingsController() {
    return instance;
  }

  SettingsController._internal() {
    _loadSettings();
  }

  // Language Setting
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('id'));
  static const String _localeKey = 'app_locale';

  // Text Scale Setting (Limit to 1.3 for safety)
  final ValueNotifier<double> textScale = ValueNotifier(1.0);
  static const String _textScaleKey = 'text_scale';
  static const double maxTextScale = 1.3;

  // Layout preference
  final ValueNotifier<bool> isGridView = ValueNotifier(true);
  static const String _isGridViewKey = 'is_grid_view';

  // Simple Localization Map
  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'app_settings': 'PENGATURAN APLIKASI',
      'language': 'Bahasa',
      'text_size': 'Ukuran Teks',
      'dark_mode': 'Mode Gelap',
      'save': 'Simpan',
      'cancel': 'Batal',
      'logout': 'Keluar Sesi',
      'confirm_logout': 'Konfirmasi Keluar',
      'logout_message': 'Apakah Anda yakin ingin keluar?',
      'edit_name': 'Ubah Nama',
      'edit_store_name': 'Ubah Nama Toko',
      'admin_account': 'AKUN ADMIN',
      'branding': 'BRANDING TOKO',
    },
    'en': {
      'app_settings': 'APP SETTINGS',
      'language': 'Language',
      'text_size': 'Text Size',
      'dark_mode': 'Dark Mode',
      'save': 'Save',
      'cancel': 'Cancel',
      'logout': 'Logout',
      'confirm_logout': 'Confirm Logout',
      'logout_message': 'Are you sure you want to logout?',
      'edit_name': 'Edit Name',
      'edit_store_name': 'Edit Store Name',
      'admin_account': 'ADMIN ACCOUNT',
      'branding': 'STORE BRANDING',
    },
  };

  String getString(String key) {
    return _localizedValues[locale.value.languageCode]?[key] ?? key;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Locale
    final langCode = prefs.getString(_localeKey) ?? 'id';
    locale.value = Locale(langCode);

    // Load Text Scale
    double scale = prefs.getDouble(_textScaleKey) ?? 1.0;
    if (scale > maxTextScale) scale = maxTextScale;
    textScale.value = scale;

    // Load Grid View Preference
    isGridView.value = prefs.getBool(_isGridViewKey) ?? true;
  }

  Future<void> setLocale(String languageCode) async {
    locale.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  Future<void> setTextScale(double scale) async {
    final safeScale = scale.clamp(0.8, maxTextScale);
    textScale.value = safeScale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, safeScale);
  }

  Future<void> setGridView(bool value) async {
    isGridView.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, value);
  }

  bool get isIndonesian => locale.value.languageCode == 'id';
}
