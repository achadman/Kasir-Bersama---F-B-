import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late AppDatabase _db;
  final _uuid = const Uuid();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = Provider.of<AppDatabase>(context);
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Semua field harus diisi");
      return;
    }

    if (password != confirmPassword) {
      _showError("Password dan Konfirmasi Password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create Local Store
      final storeId = _uuid.v4();
      await _db
          .into(_db.stores)
          .insert(
            StoresCompanion.insert(
              id: storeId,
              name: const drift.Value('Toko Saya'),
              adminName: drift.Value(email.split('@').first),
              createdAt: drift.Value(DateTime.now()),
            ),
          );

      // 2. Create Local Profile
      final userId = _uuid.v4();
      await _db
          .into(_db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: userId,
              email: drift.Value(email),
              password: drift.Value(password),
              fullName: drift.Value(email.split('@').first),
              role: const drift.Value('owner'),
              storeId: drift.Value(storeId),
              lastUpdated: drift.Value(DateTime.now()),
              createdAt: drift.Value(DateTime.now()),
            ),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registrasi Berhasil! Silakan Login."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Register Error: $e");
      _showError("Kesalahan: $e");
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
                  "Bergabung Bersama Kami",
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800000),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Mulai kelola bisnis kuliner Anda hari ini",
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
        // Right Side: Register Form
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
                      "Buat Akun Baru",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Lengkapi data diri Anda untuk mendaftar",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildRegisterForm(),
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
                "Buat Akun",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF800000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Selamat Datang Di Aplikasi Steak Asri Manajemen Pos",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 48),

              // Form
              _buildRegisterForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: "Confirm Password",
          isObscure: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFA67C7C),
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
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
            onPressed: _isLoading ? null : _register,
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
                    "Buat Akun",
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
              "Sudah Punya akun ? ",
              style: GoogleFonts.poppins(color: const Color(0xFFA67C7C)),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Masuk",
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
          vertical: 16,
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
