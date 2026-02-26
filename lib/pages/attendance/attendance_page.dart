import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import '../../services/app_database.dart';
import '../../services/attendance_service.dart';
import '../../widgets/kasir_drawer.dart';
import '../user/widgets/kasir_side_navigation.dart';
import 'package:provider/provider.dart';
import '../../services/platform/file_manager.dart';
import '../../controllers/admin_controller.dart';

class AttendancePage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  const AttendancePage({
    super.key,
    this.showSidebar = true,
    this.onMenuPressed,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late AttendanceService _attendanceService;

  String? _userId;
  String? _storeId;
  String? _userName;
  Map<String, dynamic>? _todayLog;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _startClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<AppDatabase>();
      _attendanceService = AttendanceService(db);
      _loadData();
    });
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final admin = context.read<AdminController>();
      if (admin.userId == null) return;

      _userId = admin.userId;
      _storeId = admin.storeId;

      // Get Today's Log
      final log = await _attendanceService.getTodayLog(_userId!);
      final history = await _attendanceService.getHistory(_userId!);

      if (mounted) {
        setState(() {
          _todayLog = log;
          _history = history;
          _userName = admin.userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading attendance: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _handleClockIn() async {
    if (_storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Store ID not found. Contact Admin."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _attendanceService.clockIn(
        _userId!,
        _storeId!,
        imageFile: _imageFile,
      );
      await _loadData();
      if (mounted) {
        setState(() => _imageFile = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil Clock In! Selamat bekerja.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error Clock In: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMarkAbsence() async {
    // Show a dialog for absence reason
    final reasonController = TextEditingController();
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Keterangan Tidak Hadir"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: reasonController,
            placeholder: "Alasan (Sakit / Izin / dll)",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Kirim"),
            onPressed: () async {
              Navigator.pop(ctx);
              if (reasonController.text.trim().isEmpty) return;

              setState(() => _isLoading = true);
              try {
                // We'll treat absence as a special clock-in with notes and immediate clock-out or just a note
                // For simplicity, let's just use notes for now.
                await _attendanceService.clockIn(
                  _userId!,
                  _storeId ?? "unknown",
                  notes: "TIDAK HADIR: ${reasonController.text}",
                );
                // Immediately clock out too
                final log = await _attendanceService.getTodayLog(_userId!);
                if (log != null) {
                  await _attendanceService.clockOut(
                    log['id'],
                    notes: "TIDAK HADIR: ${reasonController.text}",
                  );
                }
                await _loadData();
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleBreak() async {
    if (_todayLog == null) return;
    final currentStatus = _todayLog!['status'] ?? 'working';
    final newStatus = currentStatus == 'working' ? 'break' : 'working';

    setState(() => _isLoading = true);
    try {
      await _attendanceService.updateStatus(_todayLog!['id'], newStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'break'
                  ? "Berhenti sementara..."
                  : "Kembali bekerja!",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal update status: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_todayLog == null) return;

    setState(() => _isLoading = true);
    try {
      await _attendanceService.clockOut(_todayLog!['id']);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil Clock Out! Sampai jumpa besok."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error Clock Out: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);

    String statusText = "Belum Masuk";
    Color statusColor = Colors.grey;

    if (_todayLog != null) {
      final status = _todayLog!['status'] ?? 'working';
      final clockOutVal = _todayLog!['clockOut'] ?? _todayLog!['clock_out'];
      if (clockOutVal != null) {
        statusText = "Selesai Bekerja";
        statusColor = Colors.green;
      } else if (status == 'break') {
        statusText = "Berhenti Sementara";
        statusColor = Colors.blue;
      } else {
        statusText = "Sedang Bekerja";
        statusColor = Colors.orange;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      drawer: widget.showSidebar
          ? const KasirDrawer(currentRoute: '/attendance')
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 720;

          final mainContent = _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100), // Space for AppBar
                        // Digital Clock
                        Text(
                          DateFormat('HH:mm:ss').format(_currentTime),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id',
                          ).format(_currentTime),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Status Card
                        _buildStatusCard(
                          theme,
                          textColor,
                          statusText,
                          statusColor,
                        ),
                        const SizedBox(height: 48),
                        // Actions Section
                        _buildActionsSection(),
                        const SizedBox(height: 48),
                        // History Section
                        _buildHistorySection(isDark),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                );

          final content = Scaffold(
            backgroundColor: Colors.transparent, // Inherit from parent
            appBar: AppBar(
              title: Text(
                "Absensi Staff",
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: isWideScreen
                  ? const SizedBox.shrink()
                  : Builder(
                      builder: (context) => IconButton(
                        icon: Icon(CupertinoIcons.bars, color: textColor),
                        onPressed: () {
                          if (widget.onMenuPressed != null) {
                            widget.onMenuPressed!();
                          } else {
                            Scaffold.of(context).openDrawer();
                          }
                        },
                      ),
                    ),
            ),
            body: mainContent,
          );

          if (isWideScreen && widget.showSidebar) {
            return Row(
              children: [
                const KasirSideNavigation(currentRoute: '/attendance'),
                Expanded(child: content),
              ],
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    Color textColor,
    String statusText,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _userName ?? "Staff",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Status Hari Ini",
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          if (_todayLog != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeStat(
                  "Masuk",
                  _todayLog!['clockIn'] ?? _todayLog!['clock_in'],
                  textColor,
                ),
                _buildTimeStat(
                  "Keluar",
                  _todayLog!['clockOut'] ?? _todayLog!['clock_out'],
                  textColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    if (_todayLog == null) {
      return Column(
        children: [
          if (_imageFile != null)
            _buildPhotoPreview()
          else
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(CupertinoIcons.camera),
              label: const Text("Lampirkan Foto (Opsional)"),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "HADIR",
                  Colors.green,
                  CupertinoIcons.checkmark_circle,
                  _handleClockIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  "TIDAK HADIR",
                  Colors.orange,
                  CupertinoIcons.xmark_circle,
                  _handleMarkAbsence,
                ),
              ),
            ],
          ),
        ],
      );
    } else if ((_todayLog!['clockOut'] ?? _todayLog!['clock_out']) == null) {
      return Column(
        children: [
          _buildActionButton(
            _todayLog!['status'] == 'break'
                ? "MASUK KEMBALI"
                : "BERHENTI SEMENTARA",
            _todayLog!['status'] == 'break' ? Colors.blue : Colors.grey[700]!,
            _todayLog!['status'] == 'break'
                ? CupertinoIcons.play_circle
                : CupertinoIcons.pause_circle,
            _handleToggleBreak,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            "CLOCK OUT",
            Colors.red,
            CupertinoIcons.square_arrow_right,
            _handleClockOut,
          ),
        ],
      );
    } else {
      return Text(
        "Shift hari ini telah selesai.",
        style: GoogleFonts.inter(color: Colors.grey),
      );
    }
  }

  Widget _buildPhotoPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: FileManager().getImageProvider(_imageFile!.path),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => setState(() => _imageFile = null),
          child: const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.red,
            child: Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeStat(String label, dynamic timestamp, Color textColor) {
    String time = "--:--";
    if (timestamp != null &&
        timestamp.toString() != "null" &&
        timestamp.toString().isNotEmpty) {
      try {
        if (timestamp is DateTime) {
          time = DateFormat('HH:mm').format(timestamp.toLocal());
        } else if (timestamp is int) {
          // Drift often exports DateTime as Unix timestamp IN SECONDS or MILLISECONDS
          // SQLite stores it as an int.
          final date = DateTime.fromMillisecondsSinceEpoch(
            timestamp < 10000000000 ? timestamp * 1000 : timestamp,
          );
          time = DateFormat('HH:mm').format(date.toLocal());
        } else {
          final parsed = DateTime.tryParse(timestamp.toString());
          if (parsed != null) {
            time = DateFormat('HH:mm').format(parsed.toLocal());
          } else {
            // Check if string is actually a number
            final numeric = int.tryParse(timestamp.toString());
            if (numeric != null) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                numeric < 10000000000 ? numeric * 1000 : numeric,
              );
              time = DateFormat('HH:mm').format(date.toLocal());
            }
          }
        }
      } catch (e) {
        debugPrint("Error parsing time: $e");
      }
    }
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Text(
            "RIWAYAT ABSENSI",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final log = _history[index];
            final clockIn = log['clockIn'] ?? log['clock_in'];
            final clockOut = log['clockOut'] ?? log['clock_out'];

            DateTime date = DateTime.now();
            if (clockIn != null) {
              if (clockIn is int) {
                date = DateTime.fromMillisecondsSinceEpoch(
                  clockIn < 10000000000 ? clockIn * 1000 : clockIn,
                );
              } else {
                date = DateTime.tryParse(clockIn.toString()) ?? DateTime.now();
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMM yyyy', 'id').format(date),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMiniTime(
                              "Masuk",
                              clockIn,
                              Colors.green,
                              isDark,
                            ),
                            const SizedBox(width: 16),
                            _buildMiniTime(
                              "Keluar",
                              clockOut,
                              Colors.red,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniTime(
    String label,
    dynamic timestamp,
    Color col,
    bool isDark,
  ) {
    String time = "--:--";
    if (timestamp != null) {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          timestamp < 10000000000 ? timestamp * 1000 : timestamp,
        );
        time = DateFormat('HH:mm').format(date.toLocal());
      } else {
        final parsed = DateTime.tryParse(timestamp.toString());
        if (parsed != null) {
          time = DateFormat('HH:mm').format(parsed.toLocal());
        }
      }
    }

    return Row(
      children: [
        Text(
          "$label: ",
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: time == "--:--"
                ? Colors.grey
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ],
    );
  }
}
