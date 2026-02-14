import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/laporan_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/user/kasir_page.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/attendance/attendance_page.dart';

import 'pages/other/splash_page.dart';
import 'pages/admin/history/history_page.dart';
import 'pages/other/printer_settings_page.dart';
import 'controllers/theme_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/analytics_controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/bluetooth_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/isar_service.dart';
import 'services/sync_service.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pyesewttbjqtniixrhvc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5ZXNld3R0YmpxdG5paXhyaHZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4NTI5ODAsImV4cCI6MjA4NTQyODk4MH0.Z71ogOpR-oD_WXClMXGlf7UUHNEZ09B63_TyrDboP4c',
  );

  // Initialize Local DB
  final isarService = IsarService();
  await isarService.init();

  // Initialize Sync Service
  SyncService().init();

  runApp(const RootApp());
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
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AdminController()),
            ChangeNotifierProvider(create: (_) => AnalyticsController()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SteakAsriApp',
            themeMode: currentMode,
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
              scaffoldBackgroundColor: const Color(0xFF121212), // Deep black
              cardColor: const Color(0xFF1E1E1E), // Slightly lighter surface
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
                // JIKA INITIALIZATION SELESAI, CEK AUTH
                return StreamBuilder<AuthState>(
                  stream: Supabase.instance.client.auth.onAuthStateChange,
                  initialData: AuthState(
                    AuthChangeEvent.initialSession,
                    Supabase.instance.client.auth.currentSession,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        snapshot.data == null) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.data?.session != null) {
                      return const AuthGate();
                    }

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
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) {
                    page = const LoginPage();
                  } else {
                    page = const HistoryPage(storeId: null);
                  }
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

              return CustomPageRoute(builder: (_) => page, settings: settings);
            },
          ),
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

// --- GERBANG OTOMATIS BERDASARKAN ROLE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        supabase
            .from('profiles')
            .select('role')
            .eq('id', supabase.auth.currentUser?.id ?? '')
            .maybeSingle(),
        SharedPreferences.getInstance(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data![0] == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text("Gagal memuat profil"),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    child: const Text("Coba Lagi"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('last_route');
                      await supabase.auth.signOut();
                    },
                    child: const Text("Keluar"),
                  ),
                ],
              ),
            ),
          );
        }

        final profileData = snapshot.data![0] as Map<String, dynamic>;
        final prefs = snapshot.data![1] as SharedPreferences;

        final String role = profileData['role'];
        final String? lastRoute = prefs.getString('last_route');

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
