import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/laporan_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/user/kasir_page.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/attendance/attendance_page.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/other/splash_page.dart';
import 'pages/admin/history/history_page.dart';
import 'pages/other/printer_settings_page.dart';
import 'controllers/theme_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/analytics_controller.dart';
import 'controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/bluetooth_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_database.dart';
import 'services/google_drive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop configuration
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Kasir Asri POS',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize SQLite Database
  final db = AppDatabase();
  debugPrint("Drift Database created");

  // Initialize Localization
  await initializeDateFormatting('id', null);

  // Initialize Bluetooth Printer
  await BluetoothPrinterService().init();

  // Initialize Google Drive Service
  await GoogleDriveService().init();

  runApp(
    Provider<AppDatabase>(
      create: (context) => db,
      dispose: (context, db) => db.close(),
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    // Artificial delay for smoother splash experience
    final minSplashTime = Future.delayed(const Duration(seconds: 2));

    final localeInit = initializeDateFormatting('id', null); // Added
    final printerInit = BluetoothPrinterService().init();

    await Future.wait([minSplashTime, localeInit, printerInit]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, currentMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsController.instance.locale,
          builder: (context, currentLocale, child) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (context) => AdminController(
                    Provider.of<AppDatabase>(context, listen: false),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (context) => AnalyticsController(
                    Provider.of<AppDatabase>(context, listen: false),
                  ),
                ),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Kasir Asri',
                themeMode: currentMode,
                locale: currentLocale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('id'), Locale('en')],
                builder: (context, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: SettingsController.instance.textScale,
                    builder: (context, currentScale, _) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(currentScale)),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 360),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                },
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFFF4D4D),
                    brightness: Brightness.light,
                  ),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFFF8F9FD),
                  cardColor: Colors.white,
                  textTheme: GoogleFonts.poppinsTextTheme(),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Color(0xFF2D3436)),
                    titleTextStyle: GoogleFonts.poppins(
                      color: const Color(0xFF2D3436),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFFF4D4D),
                    brightness: Brightness.dark,
                    primary: const Color(0xFFFF4D4D),
                  ),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(
                    0xFF121212,
                  ), // Deep black
                  cardColor: const Color(
                    0xFF1E1E1E,
                  ), // Slightly lighter surface
                  textTheme: GoogleFonts.poppinsTextTheme(
                    ThemeData.dark().textTheme,
                  ),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    titleTextStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                home: FutureBuilder(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SplashPage();
                    }

                    final db = Provider.of<AppDatabase>(context, listen: false);
                    // OFFLINE AUTH CHECK: Check if any profile exists
                    return StreamBuilder<List<Profile>>(
                      stream: (db.select(db.profiles)..limit(1)).watch(),
                      builder: (context, profileSnapshot) {
                        if (profileSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (profileSnapshot.hasError) {
                          return Scaffold(
                            body: Center(
                              child: Text(
                                "Database Error: ${profileSnapshot.error}",
                              ),
                            ),
                          );
                        }

                        if (profileSnapshot.hasData &&
                            profileSnapshot.data!.isNotEmpty) {
                          // We have a local user, go to AuthGate (refactored for local)
                          return const LocalAuthGate();
                        }

                        // No local user? Go to onboarding
                        return const OnboardingPage();
                      },
                    );
                  },
                ),

                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/onboarding':
                      page = const OnboardingPage();
                      break;
                    case '/register':
                      page = const RegisterPage();
                      break;
                    case '/login':
                      page = const LoginPage();
                      break;
                    case '/admin':
                      page = const AdminPage();
                      break;
                    case '/kasir':
                      page = const KasirPage();
                      break;
                    case '/laporan':
                      final args = settings.arguments as Map<String, dynamic>?;
                      page = LaporanPage(storeId: args?['storeId'] ?? '');
                      break;
                    case '/attendance':
                      page = const AttendancePage();
                      break;
                    case '/order-history':
                      // Mock local history view
                      page = const HistoryPage(storeId: null);
                      break;
                    case '/printer-settings':
                      page = const PrinterSettingsPage();
                      break;
                    default:
                      return null;
                  }

                  // SAVE LAST ROUTE
                  if (settings.name != null &&
                      [
                        '/admin',
                        '/kasir',
                        '/order-history',
                        '/attendance',
                        '/printer-settings',
                      ].contains(settings.name)) {
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('last_route', settings.name!);
                    });
                  }

                  return CustomPageRoute(
                    builder: (_) => page,
                    settings: settings,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class CustomPageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  @override
  final RouteSettings settings;

  CustomPageRoute({required this.builder, required this.settings})
    : super(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}

// --- GERBANG OTOMATIS BERDASARKAN ROLE (LOKAL) ---
class LocalAuthGate extends StatelessWidget {
  const LocalAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return StreamBuilder<List<dynamic>>(
      stream: Rx.combineLatest2(
        (db.select(db.profiles)..limit(1)).watch(),
        SharedPreferences.getInstance().asStream(),
        (profiles, prefs) => [profiles, prefs],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Auth Gate Error: ${snapshot.error}")),
          );
        }

        final prefs = snapshot.data?[1] as SharedPreferences?;
        final profiles = snapshot.data?[0] as List<Profile>?;

        if (profiles == null || profiles.isEmpty) {
          return const OnboardingPage();
        }

        final profileData = profiles.first;
        final String role = profileData.role;
        final String? lastRoute = prefs?.getString('last_route');

        Widget target;
        bool isAdmin = role == 'admin' || role == 'owner';

        if (lastRoute != null) {
          if (isAdmin &&
              (lastRoute == '/admin' ||
                  lastRoute == '/order-history' ||
                  lastRoute == '/attendance' ||
                  lastRoute == '/printer-settings')) {
            if (lastRoute == '/order-history') {
              target = const HistoryPage(storeId: null);
            } else if (lastRoute == '/attendance') {
              target = const AttendancePage();
            } else if (lastRoute == '/printer-settings') {
              target = const PrinterSettingsPage();
            } else {
              target = const AdminPage();
            }
          } else if (!isAdmin &&
              (lastRoute == '/kasir' ||
                  lastRoute == '/order-history' ||
                  lastRoute == '/attendance' ||
                  lastRoute == '/printer-settings')) {
            if (lastRoute == '/order-history') {
              target = const HistoryPage(storeId: null);
            } else if (lastRoute == '/attendance') {
              target = const AttendancePage();
            } else if (lastRoute == '/printer-settings') {
              target = const PrinterSettingsPage();
            } else {
              target = const KasirPage();
            }
          } else {
            target = isAdmin ? const AdminPage() : const KasirPage();
          }
        } else {
          target = isAdmin ? const AdminPage() : const KasirPage();
        }

        return target;
      },
    );
  }
}
