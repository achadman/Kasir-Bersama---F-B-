import 'app_database.dart';
import 'package:drift/drift.dart';

class ShiftService {
  final AppDatabase db;

  ShiftService(this.db);

  /// Fetch shift history overlapping with a date range (optional).
  Future<List<Map<String, dynamic>>> getShiftHistory(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = db.select(db.attendanceLogs).join([
      leftOuterJoin(
        db.profiles,
        db.profiles.id.equalsExp(db.attendanceLogs.userId),
      ),
    ])..where(db.attendanceLogs.storeId.equals(storeId));

    if (startDate != null) {
      query.where(db.attendanceLogs.clockIn.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(db.attendanceLogs.clockIn.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([OrderingTerm.desc(db.attendanceLogs.clockIn)]);

    final results = await query.get();

    return results.map((row) {
      final log = row.readTable(db.attendanceLogs);
      final profile = row.readTableOrNull(db.profiles);

      final map = log.toJson();
      map['profiles'] = {
        'full_name': profile?.fullName,
        'avatar_url': profile
            ?.fullName, // Assuming avatar_url maps to something or just use name if missing
        'role': profile?.role,
      };
      return map;
    }).toList();
  }
}
