class ProductModel {
  String id;
  String name;
  String category;
  double price;
  int stock;
  int? maxStock;
  List<String> toppings;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.maxStock,
    required this.toppings,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      maxStock: data['max_stock'] != null
          ? (data['max_stock'] as num).toInt()
          : null,
      toppings:
          (data['toppings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'max_stock': maxStock,
      'toppings': toppings,
    };
  }
}
