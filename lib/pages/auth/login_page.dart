import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart'
    show AppDatabase; // Keep AppDatabase visible

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late AppDatabase _db;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = Provider.of<AppDatabase>(context);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email dan Password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Offline Authentication: Check local database
      final users =
          await (_db.select(_db.profiles)
                ..where((t) => t.email.equals(email))
                ..limit(1))
              .get();

      if (users.isEmpty) {
        _showError("Akun tidak ditemukan. Silakan registrasi terlebih dahulu.");
        return;
      }

      final user = users.first;

      // Basic password validation for local POC
      if (user.password != password) {
        _showError("Password salah.");
        return;
      }

      if (mounted) {
        final adminCtrl = Provider.of<AdminController>(context, listen: false);
        await adminCtrl.loadInitialData(); // Load store and profile info
        if (!mounted) return;

        String role = user.role;
        if (role == 'admin' || role == 'owner') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/kasir');
        }
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      _showError("Terjadi kesalahan sistem: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWideLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left Side: Branding
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFFFF0E6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logoSteakAsri.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Steak Asri POS",
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800000),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Manajemen Restoran Lebih Mudah & Efisien",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Login Form
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Selamat Datang!",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Silakan masuk ke akun Anda",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF800000), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/logoSteakAsri.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Headings
              Text(
                "Masuk Akun",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF800000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Selamat datang di aplikasi steak asri manajemen pos",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 48),

              // Form
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(controller: _emailController, hint: "Email"),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: "Password",
          isObscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFA67C7C),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 32),

        // Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA5700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Masuk",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Belum ada akun ? ",
              style: GoogleFonts.poppins(color: const Color(0xFFA67C7C)),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                "Buat akun",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF800000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isObscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFFA67C7C).withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: const Color(0xFFFFF0E6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEA5700), width: 1.5),
        ),
      ),
    );
  }
}
