class Product {
  final String id;
  final String name;
  final double basePrice;
  final double salePrice;
  final int stockQuantity;
  final bool isStockManaged;
  final bool isAvailable;
  final String? sku;
  final String? imageUrl;
  final String? categoryId;
  final String? storeId;
  final bool isDeleted;
  final DateTime? lastUpdated;

  Product({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.salePrice,
    this.stockQuantity = 0,
    this.isStockManaged = true,
    this.isAvailable = true,
    this.sku,
    this.imageUrl,
    this.categoryId,
    this.storeId,
    this.isDeleted = false,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'base_price': basePrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'is_stock_managed': isStockManaged ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'sku': sku,
      'image_url': imageUrl,
      'category_id': categoryId,
      'store_id': storeId,
      'is_deleted': isDeleted ? 1 : 0,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      basePrice: (map['base_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'] ?? 0,
      isStockManaged: map['is_stock_managed'] == 1,
      isAvailable: map['is_available'] == 1,
      sku: map['sku'],
      imageUrl: map['image_url'],
      categoryId: map['category_id'],
      storeId: map['store_id'],
      isDeleted: map['is_deleted'] == 1,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
    );
  }
}
