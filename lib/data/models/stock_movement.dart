import 'package:cloud_firestore/cloud_firestore.dart';

enum MovementType { inStock, outStock }

class StockMovement {
  final String id;
  final String productId;
  final MovementType type;
  final int quantity;
  final DateTime date;
  final String? note;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'type': type.name,
      'quantity': quantity,

      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map, String documentId) {
    return StockMovement(
      id: documentId,
      productId: map['productId'] ?? '',
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.inStock,
      ),
      quantity: map['quantity']?.toInt() ?? 0,

      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      note: map['note'],
    );
  }
}
