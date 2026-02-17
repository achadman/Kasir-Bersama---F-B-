import 'dart:convert';

class TransactionModel {
  final String id;
  final double totalAmount;
  final double cashReceived;
  final double change;
  final String paymentMethod;
  final String cashierId;
  final String storeId;
  final DateTime createdAt;
  final List<TransactionItem> items;

  TransactionModel({
    required this.id,
    required this.totalAmount,
    required this.cashReceived,
    required this.change,
    required this.paymentMethod,
    required this.cashierId,
    required this.storeId,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'cash_received': cashReceived,
      'change': change,
      'payment_method': paymentMethod,
      'cashier_id': cashierId,
      'store_id': storeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, [
    List<Map<String, dynamic>> itemsList = const [],
  ]) {
    return TransactionModel(
      id: map['id'],
      totalAmount: (map['total_amount'] as num).toDouble(),
      cashReceived: (map['cash_received'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      cashierId: map['cashier_id'],
      storeId: map['store_id'],
      createdAt: DateTime.parse(map['created_at']),
      items: itemsList.map((item) => TransactionItem.fromMap(item)).toList(),
    );
  }
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final List<dynamic> selectedOptions;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.selectedOptions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'selected_options_json': jsonEncode(selectedOptions),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      notes: map['notes'],
      selectedOptions: map['selected_options_json'] != null
          ? jsonDecode(map['selected_options_json'])
          : [],
    );
  }
}
