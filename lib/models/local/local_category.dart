class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final String? storeId;
  final DateTime? lastUpdated;

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.storeId,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'store_id': storeId,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconUrl: map['icon_url'],
      storeId: map['store_id'],
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
    );
  }
}
