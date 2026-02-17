import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../services/platform/file_manager.dart';

import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import 'employee_page.dart';
import 'package:flutter/cupertino.dart';
import '../../controllers/settings_controller.dart';
import '../../services/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  const ProfilePage({super.key, required this.storeId, this.onMenuPressed});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  String? _fullName;
  String? _avatarUrl;
  String? _storeName;
  String? _storeLogo;
  final Color _primaryColor = const Color(0xFFEA5700);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final adminCtrl = context.read<AdminController>();
    final db = context.read<AppDatabase>();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (mounted) {
        setState(() {
          _fullName = adminCtrl.userName;
          _avatarUrl = adminCtrl.profileUrl;
          _storeName = adminCtrl.storeName;
          _storeLogo = adminCtrl.storeLogo;
        });

        // Load Store Info (already in controller, but if we need a fresh DB hit)
        final storeData =
            await (db.select(db.stores)
                  ..where((t) => t.id.equals(widget.storeId))
                  ..limit(1))
                .getSingleOrNull();

        if (mounted && storeData != null) {
          setState(() {
            _storeName = storeData.name;
            _storeLogo = storeData.logoUrl;
            _avatarUrl = storeData.adminAvatar;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final adminCtrl = context.read<AdminController>();
      final userId = adminCtrl.userId;

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final savedPath = await FileManager().saveFile(image, fileName);

      await adminCtrl.updateProfile(avatarUrl: savedPath);

      setState(() {
        _avatarUrl = savedPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Avatar Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _fullName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Ubah Nama",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: "Nama Lengkap",
            fillColor: Colors.grey.withValues(alpha: 0.1),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final adminCtrl = context.read<AdminController>();
        await adminCtrl.updateProfile(name: newName);
        setState(() => _fullName = newName);
      } catch (e) {
        debugPrint("Update Name Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStoreLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final fileName =
          'store_${widget.storeId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final savedPath = await FileManager().saveFile(image, fileName);

      if (!mounted) return;
      final adminCtrl = context.read<AdminController>();
      await adminCtrl.updateStoreBranding(logoUrl: savedPath);

      setState(() => _storeLogo = savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logo toko diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Store Logo Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editStoreName() async {
    final controller = TextEditingController(text: _storeName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Ubah Nama Toko",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: "Nama Toko (Contoh: Steak Asri)",
            fillColor: Colors.grey.withValues(alpha: 0.1),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final adminCtrl = context.read<AdminController>();
        await adminCtrl.updateStoreBranding(name: newName);
        setState(() => _storeName = newName);
      } catch (e) {
        debugPrint("Update Store Name Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmResetStore() async {
    final controller = TextEditingController();
    bool deleteProducts = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "RESET TOKO?",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tindakan ini akan MENGHAPUS SEMUA RIWAYAT PENJUALAN dan LAPORAN. Data yang dihapus tidak dapat dikembalikan.",
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: deleteProducts,
                    onChanged: (val) => setState(() => deleteProducts = val!),
                    title: Text(
                      "Hapus juga semua produk?",
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Ketik "RESET" untuk konfirmasi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                  child: const Text(
                    "HAPUS DATA",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == "RESET") {
        if (!mounted) return;
        setState(() => _isLoading = true);
        try {
          final adminCtrl = context.read<AdminController>();
          await adminCtrl.resetStore(deleteProducts: deleteProducts);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Toko berhasil di-reset."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _backupData() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      await BackupService(db).createFullBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backup berhasil dibuat & dibagikan!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal backup: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreData() async {
    // 1. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    if (!mounted) return;

    // 2. Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "RESTORE DATA?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 10),
            Text(
              "Perhatian: Tindakan ini akan MENGGANTI SEMUA DATA yang ada di aplikasi ini dengan data dari file backup.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 10),
            Text(
              "Aplikasi akan otomatis RESTART setelah proses selesai.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "TIMPA & RESTORE",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = context.read<AppDatabase>();
      await BackupService(db).restoreFullBackup(path);

      // 6. Show Success & Restart/Prompt
      if (mounted) {
        setState(() => _isLoading = false);

        // Check if Desktop
        final isDesktop =
            Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS;

        if (isDesktop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Restore Berhasil"),
              content: const Text(
                "Data berhasil dipulihkan.\n\nSilakan RESTART aplikasi secara manual untuk melihat perubahan.",
              ),
              actions: [
                TextButton(
                  onPressed: () => exit(0), // Quit the app
                  child: const Text("Keluar Aplikasi"),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Will restart automatically
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Restore Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Gagal Restore"),
            content: Text("Error: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();

            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }

            return IconButton(
              icon: Icon(
                CupertinoIcons.bars,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF2D3436),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(adminCtrl),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    SettingsController.instance.getString('admin_account'),
                  ),
                  _buildMenuSection([
                    _ProfileMenuItem(
                      label: SettingsController.instance.getString('edit_name'),
                      icon: CupertinoIcons.person,
                      onTap: _editName,
                    ),
                    _ProfileMenuItem(
                      label: "Ganti Foto Admin",
                      icon: CupertinoIcons.camera,
                      onTap: _updateAvatar,
                    ),
                    _ProfileMenuItem(
                      label: "Daftar Karyawan",
                      icon: CupertinoIcons.person_3,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeePage(storeId: widget.storeId),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    SettingsController.instance.getString('branding'),
                  ),
                  _buildMenuSection([
                    _ProfileMenuItem(
                      label: SettingsController.instance.getString(
                        'edit_store_name',
                      ),
                      icon: CupertinoIcons.tag,
                      onTap: _editStoreName,
                    ),
                    _ProfileMenuItem(
                      label: "Ubah Logo Toko",
                      icon: CupertinoIcons.photo,
                      onTap: _updateStoreLogo,
                      trailing: _storeLogo != null
                          ? Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: FileManager().getImageProvider(
                                    _storeLogo!,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    SettingsController.instance.getString('app_settings'),
                  ),
                  _buildAppSettings(),
                  const SizedBox(height: 20),
                  _buildThemeToggle(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Backup & Restore"),
                  _buildMenuSection([
                    _ProfileMenuItem(
                      label: "Export Full Backup",
                      icon: CupertinoIcons.cloud_upload,
                      onTap: _backupData,
                      trailing: const Icon(
                        CupertinoIcons.share,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    _ProfileMenuItem(
                      label: "Import Backup",
                      icon: CupertinoIcons.cloud_download,
                      onTap: _restoreData,
                      trailing: const Icon(
                        CupertinoIcons.add,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  _buildSectionTitle("DANGER ZONE"), // Zona Berbahaya
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(
                        "Reset Toko",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      subtitle: Text(
                        "Hapus semua penjualan & reset stok",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red[300],
                        ),
                      ),
                      onTap: _confirmResetStore,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.power,
                          color: Colors.red,
                        ),
                        label: Text(
                          SettingsController.instance.getString('logout'),
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 50,
                  ), // Margin for Android navigation bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AdminController adminCtrl) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _avatarUrl != null
                    ? FileManager().getImageProvider(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _updateAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _fullName ?? 'User',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2D3436),
          ),
        ),
        Text(
          "Admin Local Session",
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Status Akun: Owner",
            style: GoogleFonts.inter(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(List<_ProfileMenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.2
                  : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: _primaryColor, size: 22),
                ),
                title: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2D3436),
                  ),
                ),
                trailing:
                    item.trailing ??
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: Colors.grey,
                    ),
                onTap: item.onTap,
              ),
              if (idx < items.length - 1)
                const Divider(indent: 70, endIndent: 20, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppSettings() {
    final settings = SettingsController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Language Setting
          ValueListenableBuilder<Locale>(
            valueListenable: settings.locale,
            builder: (context, locale, child) {
              final isIndo = locale.languageCode == 'id';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.globe,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: Text(
                  settings.getString('language'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    settings.setLocale(isIndo ? 'en' : 'id');
                  },
                  child: Text(
                    isIndo ? "Bhs. Indonesia" : "English",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(indent: 70, endIndent: 20, height: 1),
          // Text Scale Setting
          ValueListenableBuilder<double>(
            valueListenable: settings.textScale,
            builder: (context, scale, child) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.textformat,
                    color: Colors.teal,
                    size: 22,
                  ),
                ),
                title: Text(
                  settings.getString('text_size'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                subtitle: Slider(
                  value: scale,
                  min: 0.8,
                  max: SettingsController.maxTextScale,
                  divisions: 5,
                  activeColor: Colors.teal,
                  onChanged: (val) {
                    settings.setTextScale(val);
                  },
                ),
                trailing: Text(
                  "${(scale * 100).toInt()}%",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              );
            },
          ),
          const Divider(indent: 70, endIndent: 20, height: 1),
          // Dark Mode Setting
          _buildThemeToggleInside(),
        ],
      ),
    );
  }

  Widget _buildThemeToggleInside() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, child) {
        final isDarkMode = mode == ThemeMode.dark;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.indigo : Colors.orange).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode
                  ? CupertinoIcons.moon_fill
                  : CupertinoIcons.sun_max_fill,
              color: isDarkMode ? Colors.indigo : Colors.orange,
              size: 22,
            ),
          ),
          title: Text(
            SettingsController.instance.getString('dark_mode'),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
          trailing: CupertinoSwitch(
            value: isDarkMode,
            onChanged: (val) => ThemeController.instance.toggleTheme(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Placeholder for compatibility, logic moved inside _buildAppSettings
  Widget _buildThemeToggle() {
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  _ProfileMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
}
