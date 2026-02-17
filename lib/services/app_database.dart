import 'package:drift/drift.dart';

import 'database/connection/connection.dart';

part 'app_database.g.dart';

// --- TABLES ---

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get address => text().nullable()(); // Added
  TextColumn get phoneNumber => text().nullable()(); // Added
  TextColumn get logoUrl => text().nullable()();
  TextColumn get description => text().nullable()(); // Added
  TextColumn get operationalHours => text().nullable()(); // Added (JSON)
  IntColumn get shiftDurationHours =>
      integer().withDefault(const Constant(9))(); // Added
  TextColumn get shiftStartTime =>
      text().withDefault(const Constant('09:00:00'))(); // Added
  BoolColumn get isAttendanceEnabled =>
      boolean().withDefault(const Constant(true))(); // Added
  TextColumn get adminName => text().nullable()();
  TextColumn get adminAvatar => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable().unique()(); // Added
  TextColumn get password => text().nullable()(); // Added
  TextColumn get fullName => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('staff'))();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();
  TextColumn get avatarUrl => text().nullable()(); // Added
  TextColumn get permissions => text().nullable()(); // Added (JSON)

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()(); // Keep for sync

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  RealColumn get buyPrice => real().nullable()(); // Added match SQL
  RealColumn get basePrice => real().nullable()(); // Keep for backward compat
  RealColumn get salePrice => real().nullable()();
  IntColumn get stockQuantity => integer().nullable()();
  BoolColumn get isStockManaged =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get sku => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductOptions extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get optionName => text().nullable()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductOptionValues extends Table {
  TextColumn get id => text()();
  TextColumn get optionId => text().nullable()();
  TextColumn get valueName => text().nullable()();
  RealColumn get priceAdjustment => real().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get totalAmount => real().nullable()();
  RealColumn get cashReceived => real().nullable()(); // Not in SQL but useful
  RealColumn get change => real().nullable()(); // Not in SQL but useful
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))(); // Added
  TextColumn get source =>
      text().withDefault(const Constant('pos_offline'))(); // Added
  TextColumn get customerName => text().nullable()(); // Added
  TextColumn get tableNumber => text().nullable()(); // Added
  TextColumn get notes => text().nullable()(); // Added
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get productName => text().nullable()(); // Not in SQL?
  IntColumn get quantity => integer().nullable()();
  RealColumn get unitPrice => real().nullable()();
  RealColumn get priceAtTime => real().nullable()(); // Added match SQL
  RealColumn get totalPrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get selectedOptionsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()(); // Added

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get clockIn => dateTime().nullable()();
  DateTimeColumn get clockOut => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get status => text().nullable()(); // working, break, finished
  BoolColumn get isOvertime => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Promotions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text()(); // discount, buy_x_get_y, bundle
  TextColumn get discountType =>
      text().withDefault(const Constant('percentage'))(); // percentage, fixed
  TextColumn get description => text().nullable()();
  RealColumn get value => real().nullable()(); // % or fixed amount
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get storeId => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PromotionItems extends Table {
  TextColumn get id => text()();
  TextColumn get promotionId => text().nullable()();
  TextColumn get productId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get role => text()(); // BUY, GET, TARGET
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- DATABASE CLASS ---

@DriftDatabase(
  tables: [
    Stores,
    Profiles,
    Categories,
    Products,
    ProductOptions,
    ProductOptionValues,
    Transactions,
    TransactionItems,
    AttendanceLogs,
    Promotions,
    PromotionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(promotions);
        await m.createTable(promotionItems);
      } else if (from < 3) {
        // Only add column if table was already created in version 2
        await m.addColumn(promotions, promotions.discountType);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return connect();
}
