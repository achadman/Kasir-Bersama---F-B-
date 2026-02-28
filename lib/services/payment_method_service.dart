import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class PaymentMethodService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PaymentMethodService(this._db);

  Stream<List<PaymentMethod>> watchActivePaymentMethods(String storeId) {
    return (_db.select(_db.paymentMethods)
          ..where((t) => t.storeId.equals(storeId))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<PaymentMethod>> getPaymentMethods(String storeId) async {
    return (_db.select(_db.paymentMethods)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> createPaymentMethod({
    required String storeId,
    required String name,
    required String type,
    String? details,
    String? username,
    String? qrisUrl,
  }) async {
    await _db
        .into(_db.paymentMethods)
        .insert(
          PaymentMethodsCompanion.insert(
            id: _uuid.v4(),
            storeId: Value(storeId),
            name: name,
            type: type,
            details: Value(details),
            username: Value(username),
            qrisUrl: Value(qrisUrl),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updatePaymentMethod(PaymentMethod method) async {
    await _db.update(_db.paymentMethods).replace(method);
  }

  Future<void> togglePaymentMethodActive(String id, bool isActive) async {
    await (_db.update(_db.paymentMethods)..where((t) => t.id.equals(id))).write(
      PaymentMethodsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> deletePaymentMethod(String id) async {
    await (_db.delete(_db.paymentMethods)..where((t) => t.id.equals(id))).go();
  }
}
