import 'package:image_picker/image_picker.dart';
import 'platform/file_manager.dart';
import 'package:path/path.dart' as p;
import 'app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class AttendanceService {
  final AppDatabase db;

  AttendanceService(this.db);

  /// Get today's attendance log for a specific user
  Future<Map<String, dynamic>?> getTodayLog(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final query = db.select(db.attendanceLogs)
        ..where(
          (t) =>
              t.userId.equals(userId) &
              t.clockIn.isBiggerOrEqualValue(startOfDay) &
              t.clockIn.isSmallerOrEqualValue(endOfDay),
        )
        ..limit(1);

      final result = await query.getSingleOrNull();

      if (result != null) {
        return result.toJson();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clock In
  Future<void> clockIn(
    String userId,
    String storeId, {
    String? notes,
    XFile? imageFile,
  }) async {
    String? photoUrl;

    if (imageFile != null) {
      final fileName =
          'attendance_${userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      photoUrl = await FileManager().saveFile(imageFile, fileName);
    }

    final id = const Uuid().v4();
    await db
        .into(db.attendanceLogs)
        .insert(
          AttendanceLogsCompanion.insert(
            id: id,
            userId: Value(userId),
            storeId: Value(storeId),
            clockIn: Value(DateTime.now()),
            notes: Value(notes),
            photoUrl: Value(photoUrl),
            status: const Value('working'),
          ),
        );
  }

  /// Update attendance status
  Future<void> updateStatus(String logId, String status) async {
    await (db.update(db.attendanceLogs)..where((t) => t.id.equals(logId)))
        .write(AttendanceLogsCompanion(status: Value(status)));
  }

  /// Clock Out
  Future<void> clockOut(String logId, {String? notes}) async {
    await (db.update(
      db.attendanceLogs,
    )..where((t) => t.id.equals(logId))).write(
      AttendanceLogsCompanion(
        clockOut: Value(DateTime.now()),
        status: const Value('finished'),
        notes: notes != null ? Value(notes) : const Value.absent(),
      ),
    );
  }
}
