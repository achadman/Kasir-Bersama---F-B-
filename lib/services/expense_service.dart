import 'package:drift/drift.dart';
import 'app_database.dart';
import 'package:uuid/uuid.dart';

class ExpenseService {
  final AppDatabase db;

  ExpenseService(this.db);

  // Get all expenses for a store
  Stream<List<Expense>> watchExpenses(String storeId) {
    return (db.select(db.expenses)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // Get expenses for a specific date range
  Future<List<Expense>> getExpensesForPeriod(
    String storeId,
    DateTime start,
    DateTime end,
  ) {
    return (db.select(db.expenses)..where(
          (t) => t.storeId.equals(storeId) & t.date.isBetweenValues(start, end),
        ))
        .get();
  }

  // Create new expense
  Future<String> createExpense({
    required String storeId,
    required String category,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: id,
            storeId: Value(storeId),
            category: category,
            amount: Value(amount),
            date: Value(date),
            notes: Value(notes),
          ),
        );
    return id;
  }

  // Delete expense
  Future<void> deleteExpense(String id) {
    return (db.delete(db.expenses)..where((t) => t.id.equals(id))).go();
  }

  // Get total expenses for a period
  Future<double> getTotalExpenses(
    String storeId,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await getExpensesForPeriod(storeId, start, end);
    return expenses.fold<double>(0.0, (sum, e) => sum + (e.amount ?? 0));
  }
}
