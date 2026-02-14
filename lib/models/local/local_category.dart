import 'package:isar/isar.dart';

part 'local_category.g.dart';

@collection
class LocalCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String supabaseId;

  late String name;
  String? iconUrl;
  @Index()
  String? storeId;

  DateTime? lastUpdated;
}
