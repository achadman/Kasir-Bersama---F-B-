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
      'profile_title': 'Profil Saya',
      'change_admin_photo': 'Ganti Foto Admin',
      'employee_list': 'Daftar Karyawan',
      'change_store_logo': 'Ubah Logo Toko',
      'backup_restore': 'Backup & Restore',
      'export_backup': 'Ekspor Backup Full',
      'import_backup': 'Impor Backup',
      'reset_store': 'Reset Toko',
      'danger_zone': 'ZONA BERBAHAYA',
      'reset_subtitle': 'Hapus semua penjualan & reset stok',
      'nav_cashier': 'Kasir',
      'nav_history': 'Riwayat',
      'nav_absent': 'Absen',
      'nav_printer': 'Printer',
      'nav_inventory': 'Produk',
      'nav_category': 'Kategori',
      'nav_analytics': 'Analitik',
      'nav_profit_loss': 'Laba Rugi',
      'nav_promotion': 'Promosi',
      'nav_data': 'Data & Stok',
      'dashboard': 'Dashboard',
      'welcome_back': 'Selamat datang kembali',
      'total_sales': 'Total Penjualan',
      'transactions': 'Transaksi',
      'items': 'Barang',
      'stock': 'Stok',
      'search_hint': 'Cari...',
      'all': 'Semua',
      'income': 'Pendapatan',
      'today_summary': 'RINGKASAN HARI INI',
      'lifetime_revenue': 'PERFORMA PENDAPATAN (LIFETIME)',
      'growth_indicators': 'INDIKATOR PERTUMBUHAN',
      'recent_transactions': 'TRANSAKSI TERAKHIR',
      'view_all': 'Lihat Semua',
      'navigation': 'NAVIGASI',
      'beranda': 'Beranda',
      'absen_staff': 'Absensi Staff',
      'admin_panel': 'Panel Admin',
      'administration': 'ADMINISTRASI',
      'logout_app': 'Keluar Aplikasi',
      'business_analytics': 'Analitik Bisnis',
      'performance_summary': 'RINGKASAN PERFORMA',
      'business_growth': 'PERTUMBUHAN BISNIS',
      'revenue_distribution': 'DISTRIBUSI PENDAPATAN',
      'top_products': 'PRODUK TERLARIS',
      'revenue_chart': 'GRAFIK PENDAPATAN',
      'kelola_produk': 'Kelola Produk',
      'all_categories': 'Semua Kategori',
      'add_product': 'Tambah Produk',
      'import_export': 'Impor/Ekspor',
      'search_product': 'Cari produk...',
      'limited': 'Terbatas',
      'unlimited': 'Tidak Terbatas',
      'no_products': 'Belum ada produk',
      'product_not_found': 'Produk tidak ditemukan',
      'history_performance': 'Riwayat & Performa',
      'export_report': 'Ekspor Laporan',
      'performance_staff': 'PERFORMA STAF',
      'export_history_title': 'Ekspor Riwayat Transaksi',
      'export_pdf': 'Ekspor PDF',
      'export_excel': 'Ekspor Excel',
      'stock_max_reached': 'sudah mencapai batas maksimal di keranjang!',
      'stock_insufficient': 'tidak mencukupi',
      'weekly_trend': 'Trend Mingguan',
      'monthly_trend': 'Trend Bulanan',
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
      'profile_title': 'My Profile',
      'change_admin_photo': 'Change Admin Photo',
      'employee_list': 'Employee List',
      'change_store_logo': 'Change Store Logo',
      'backup_restore': 'Backup & Restore',
      'export_backup': 'Export Full Backup',
      'import_backup': 'Import Backup',
      'reset_store': 'Reset Store',
      'danger_zone': 'DANGER ZONE',
      'reset_subtitle': 'Delete all sales & reset stock',
      'nav_cashier': 'Cashier',
      'nav_history': 'History',
      'nav_absent': 'Attendance',
      'nav_printer': 'Printer',
      'nav_inventory': 'Products',
      'nav_category': 'Categories',
      'nav_analytics': 'Analytics',
      'nav_profit_loss': 'Profit & Loss',
      'nav_promotion': 'Promotions',
      'nav_data': 'Data & Stock',
      'dashboard': 'Dashboard',
      'welcome_back': 'Welcome back',
      'total_sales': 'Total Sales',
      'transactions': 'Transactions',
      'items': 'Items',
      'stock': 'Stock',
      'search_hint': 'Search...',
      'all': 'All',
      'income': 'Income',
      'today_summary': 'TODAY SUMMARY',
      'lifetime_revenue': 'LIFETIME REVENUE PERFORMANCE',
      'growth_indicators': 'GROWTH INDICATORS',
      'recent_transactions': 'RECENT TRANSACTIONS',
      'view_all': 'View All',
      'navigation': 'NAVIGATION',
      'beranda': 'Home',
      'absen_staff': 'Staff Attendance',
      'admin_panel': 'Admin Panel',
      'administration': 'ADMINISTRATION',
      'logout_app': 'Logout App',
      'business_analytics': 'Business Analytics',
      'performance_summary': 'PERFORMANCE SUMMARY',
      'business_growth': 'BUSINESS GROWTH',
      'revenue_distribution': 'REVENUE DISTRIBUTION',
      'top_products': 'TOP PRODUCTS',
      'revenue_chart': 'REVENUE CHART',
      'kelola_produk': 'Manage Products',
      'all_categories': 'All Categories',
      'add_product': 'Add Product',
      'import_export': 'Import/Export',
      'search_product': 'Search products...',
      'limited': 'Limited',
      'unlimited': 'Unlimited',
      'no_products': 'No products yet',
      'product_not_found': 'Product not found',
      'history_performance': 'History & Performance',
      'export_report': 'Export Report',
      'performance_staff': 'STAFF PERFORMANCE',
      'export_history_title': 'Export Transaction History',
      'export_pdf': 'Export PDF',
      'export_excel': 'Export Excel',
      'stock_max_reached': 'already reached maximum limit in cart!',
      'stock_insufficient': 'insufficient',
      'weekly_trend': 'Weekly Trend',
      'monthly_trend': 'Monthly Trend',
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
