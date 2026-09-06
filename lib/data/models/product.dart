class Product {
  final String id;
  final String name;
  final String categoryId;
  final int price; // int for FCFA
  final int currentStock;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.currentStock,
    this.barcode,
  });

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? price,
    int? currentStock,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      currentStock: currentStock ?? this.currentStock,
      barcode: barcode ?? this.barcode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'currentStock': currentStock,
      'barcode': barcode,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      price: map['price']?.toInt() ?? 0,
      currentStock: map['currentStock']?.toInt() ?? 0,
      barcode: map['barcode'],
    );
  }
}
