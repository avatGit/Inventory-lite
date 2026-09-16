import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_movement.dart';
import 'stock_movement_repository.dart';

class FirestoreStockMovementRepository implements StockMovementRepository {
  final FirebaseFirestore _firestore;

  FirestoreStockMovementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      _firestore.collection('stock_movements');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Stream<List<StockMovement>> watchMovementsForProduct(String productId) {
    return _movementsRef
        .where('productId', isEqualTo: productId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return StockMovement.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> addMovement(StockMovement movement) async {
    final productRef = _productsRef.doc(movement.productId);
    final movementRef = _movementsRef
        .doc(); // generate a new ID for the movement

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. read the target product document
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception(
            'Produit introuvable. Impossible d\'ajouter le mouvement',
          );
        }

        // 2. Calculate the new currentStock (Defensive casting)
        final productData = productDoc.data()!;
        final int currentStock =
            (productData['currentStock'] as num?)?.toInt() ?? 0;

        int newStock = currentStock;
        if (movement.type == MovementType.inStock) {
          newStock += movement.quantity;
        } else if (movement.type == MovementType.outStock) {
          newStock -= movement.quantity;
        }

        // Prevent negative stock
        if (newStock < 0) {
          throw Exception('Stock insuffisant pour cette sortie');
        }

        // 3. Update the product's currentStock atomically
        transaction.update(productRef, {'currentStock': newStock});

        // 4. create the new movement document atomically
        transaction.set(movementRef, movement.toMap());
      });
    } catch (e) {
      // Re-throw or handle as needed by the UI layer
      throw Exception('Echec de l\'enregistrement du mouvement" $e');
    }
  }

  @override
  Stream<List<StockMovement>> watchRecentMovements({int limit = 10}) {
    return _movementsRef
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return StockMovement.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
