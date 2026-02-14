import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/theme_controller.dart';
import '../pages/other/printer_settings_page.dart';

class KasirDrawer extends StatefulWidget {
  final String currentRoute;
  const KasirDrawer({super.key, required this.currentRoute});

  @override
  State<KasirDrawer> createState() => _KasirDrawerState();
}

class _KasirDrawerState extends State<KasirDrawer> {
  final supabase = Supabase.instance.client;
  String? _avatarUrl;
  String _fullName = "Kasir";
  String? _userId;
  String? _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _userId = user.id;

    final data = await supabase
        .from('profiles')
        .select('full_name, role, avatar_url, store_id')
        .eq('id', user.id)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() {
        _fullName = data['full_name'] ?? "Kasir";
        _avatarUrl = data['avatar_url'];
        _role = data['role'];
        _role = data['role'];
      });
    }
  }

  Future<void> _updateName() async {
    if (_userId == null) return;
    final controller = TextEditingController(text: _fullName);

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Ubah Nama"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "Nama Lengkap",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: const Text("Simpan"),
            onPressed: () async {
              Navigator.pop(ctx);
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await supabase
                    .from('profiles')
                    .update({'full_name': newName})
                    .eq('id', _userId!);
                setState(() => _fullName = newName);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhoto() async {
    if (_userId == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final fileExt = pickedFile.name.split('.').last;
        final fileName = '$_userId/avatar.$fileExt';
        final bytes = await pickedFile.readAsBytes();

        await supabase.storage
            .from('profiles')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = supabase.storage
            .from('profiles')
            .getPublicUrl(fileName);

        await supabase
            .from('profiles')
            .update({'avatar_url': publicUrl})
            .eq('id', _userId!);

        if (mounted) {
          setState(() {
            _avatarUrl = publicUrl;
          });
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal upload foto: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    const accentColor = Color(0xFFFF4D4D); // Vibrant Red for Kasir

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  _buildSectionTitle("NAVIGASI"),
                  _buildModernItem(
                    icon: CupertinoIcons.home,
                    label: "Beranda",
                    isSelected: widget.currentRoute == '/kasir',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != '/kasir') {
                        Navigator.pushReplacementNamed(context, '/kasir');
                      }
                    },
                  ),
                  _buildModernItem(
                    icon: CupertinoIcons.clock,
                    label: "Absensi Staff",
                    isSelected: widget.currentRoute == '/attendance',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.currentRoute != '/attendance') {
                        Navigator.pushReplacementNamed(context, '/attendance');
                      }
                    },
                  ),
                  _buildModernItem(
                    icon: CupertinoIcons.doc_text,
                    label: "Riwayat Pesanan",
                    isSelected: widget.currentRoute == '/order-history',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/order-history');
                    },
                  ),
                  _buildModernItem(
                    icon: CupertinoIcons.printer,
                    label: "Pengaturan Printer",
                    isSelected: widget.currentRoute == '/printer-settings',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const PrinterSettingsPage(),
                        ),
                      );
                    },
                  ),
                  if (_role == 'admin' || _role == 'owner') ...[
                    _buildSectionTitle("ADMINISTRASI"),
                    _buildModernItem(
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      label: "Panel Admin",
                      isSelected: false,
                      accentColor: Colors.blue,
                      isSpecial: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/admin');
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildThemeToggle(isDark, accentColor),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    // A slightly different style for Kasir active user
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _updatePhoto,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF4D4D),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: _avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  child: _avatarUrl == null
                      ? Icon(
                          CupertinoIcons.person_solid,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        )
                      : null,
                ),
                if (_isLoading)
                  const Positioned.fill(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D4D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _fullName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _updateName,
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "POS TERMINAL",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF4D4D),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    bool isSpecial = false,
  }) {
    final isDark = ThemeController.instance.isDarkMode;
    final activeColor = isSpecial ? Colors.blue : accentColor;
    final activeBg = activeColor.withValues(alpha: 0.1);
    final textColor = isSelected
        ? activeColor
        : (isDark ? Colors.white70 : const Color(0xFF2D3436));
    final iconColor = isSelected
        ? activeColor
        : (isDark ? Colors.white54 : Colors.grey[500]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
            color: isDark ? Colors.white70 : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            isDark ? "Dark Mode" : "Light Mode",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: accentColor,
            onChanged: (val) {
              ThemeController.instance.toggleTheme();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: InkWell(
        onTap: () async {
          final shouldLogout = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Konfirmasi Keluar"),
              content: const Text(
                "Apakah Anda yakin ingin keluar dari aplikasi?",
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Batal"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text("Keluar"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await supabase.auth.signOut();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.power, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Text(
                "Keluar Aplikasi",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
