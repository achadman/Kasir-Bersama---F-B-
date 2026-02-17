import 'package:flutter/material.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/platform/file_manager.dart';

class AttendanceReportPage extends StatefulWidget {
  final String storeId;
  const AttendanceReportPage({super.key, required this.storeId});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _filteredLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();

      final query = db.select(db.attendanceLogs).join([
        drift.leftOuterJoin(
          db.profiles,
          db.profiles.id.equalsExp(db.attendanceLogs.userId),
        ),
      ])..where(db.attendanceLogs.storeId.equals(widget.storeId));

      query.orderBy([drift.OrderingTerm.desc(db.attendanceLogs.clockIn)]);

      final results = await query.get();

      final filtered = results
          .where((row) {
            final log = row.readTable(db.attendanceLogs);
            if (log.clockIn == null) return false;
            final clockIn = log.clockIn!;
            return clockIn.year == _selectedDate.year &&
                clockIn.month == _selectedDate.month &&
                clockIn.day == _selectedDate.day;
          })
          .map((row) {
            final log = row.readTable(db.attendanceLogs);
            final profile = row.readTableOrNull(db.profiles);
            final map = log.toJson();
            map['fullName'] = profile?.fullName;
            return map;
          })
          .toList();

      if (mounted) {
        setState(() {
          _filteredLogs = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching attendance logs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Absensi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _fetchLogs();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Data Tanggal: ${DateFormat('dd MMMM yyyy', 'id').format(_selectedDate)}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_filteredLogs.isEmpty
                      ? Center(
                          child: Text(
                            "Tidak ada absensi pada tanggal ini.",
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchLogs,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = _filteredLogs[index];
                              return _buildLogCard(log, isDark);
                            },
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark) {
    DateTime parseSafe(dynamic val) {
      if (val is DateTime) return val.toLocal();
      final str = val.toString();
      final asInt = int.tryParse(str);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
      }
      return DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
    }

    final clockInStr = log['clockIn'];
    if (clockInStr == null) return const SizedBox.shrink();
    final clockIn = parseSafe(clockInStr);

    final clockOutStr = log['clockOut'];
    final clockOut = clockOutStr != null ? parseSafe(clockOutStr) : null;
    final status = log['status'] ?? 'working';
    final photoUrl = log['photoUrl'];
    final name = log['fullName'] ?? "User...";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        status == 'finished'
                            ? "Selesai Shift"
                            : (status == 'break'
                                  ? "Sedang Istirahat"
                                  : "Sedang Bekerja"),
                        style: TextStyle(
                          color: _getStatusColor(
                            status,
                            log['clock_out'] != null,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (photoUrl != null)
                  GestureDetector(
                    onTap: () => _showPhoto(photoUrl),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileManager().getImageProvider(photoUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeInfo("Masuk", DateFormat('HH:mm').format(clockIn)),
                _timeInfo(
                  "Keluar",
                  clockOut != null
                      ? DateFormat('HH:mm').format(clockOut)
                      : "--:--",
                ),
                _timeInfo("Status", status.toUpperCase()),
              ],
            ),
            if (log['notes'] != null) ...[
              const SizedBox(height: 12),
              Text(
                "Catatan: ${log['notes']}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isFinished) {
    if (isFinished) return Colors.green;
    if (status == 'break') return Colors.blue;
    return Colors.orange;
  }

  Widget _timeInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: FileManager().getImageProvider(url),
              fit: BoxFit.contain,
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup"),
            ),
          ],
        ),
      ),
    );
  }
}
