import 'dart:convert';
import 'app_database.dart';
import 'package:drift/drift.dart';

class EmployeeService {
  final AppDatabase db;

  EmployeeService(this.db);

  /// Fetch all employees (cashiers) for a specific store
  Future<List<Map<String, dynamic>>> getEmployees(String storeId) async {
    final results =
        await (db.select(db.profiles)
              ..where(
                (t) => t.storeId.equals(storeId) & t.role.equals('cashier'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
            .get();

    return results.map((e) {
      final map = e.toJson();
      // Handle permissions which might be stored as a JSON string or already a map/object in Drift
      if (map['permissions'] != null && map['permissions'] is String) {
        try {
          map['permissions'] = jsonDecode(map['permissions']);
        } catch (_) {
          map['permissions'] = {};
        }
      }
      return map;
    }).toList();
  }

  /// Watch employees for real-time updates
  Stream<List<Map<String, dynamic>>> watchEmployees(String storeId) {
    return (db.select(db.profiles)
          ..where((t) => t.storeId.equals(storeId) & t.role.equals('cashier'))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch()
        .map((results) {
          return results.map((e) {
            final map = e.toJson();
            if (map['permissions'] != null && map['permissions'] is String) {
              try {
                map['permissions'] = jsonDecode(map['permissions']);
              } catch (_) {
                map['permissions'] = {};
              }
            }
            return map;
          }).toList();
        });
  }

  /// Create a new cashier account locally
  Future<void> createCashierAccount({
    required String id,
    required String email,
    required String password,
    required String fullName,
    required String storeId,
    Map<String, bool>? permissions,
  }) async {
    final defaultPermissions =
        permissions ??
        {
          'manage_inventory': false,
          'manage_categories': false,
          'pos_access': true,
          'view_history': true,
          'view_reports': false,
          'manage_printer': true,
          'manage_promotions': false,
          'manage_customers': false,
        };

    await db
        .into(db.profiles)
        .insert(
          ProfilesCompanion.insert(
            id: id,
            email: Value(email),
            password: Value(password),
            fullName: Value(fullName),
            role: const Value('cashier'),
            storeId: Value(storeId),
            permissions: Value(jsonEncode(defaultPermissions)),
            lastUpdated: Value(DateTime.now()),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  /// Remove an employee from the local database
  Future<void> removeEmployee(String userId) async {
    await (db.delete(db.profiles)..where((t) => t.id.equals(userId))).go();
  }
}
