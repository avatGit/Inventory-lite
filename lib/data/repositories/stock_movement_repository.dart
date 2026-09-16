import '../models/stock_movement.dart';

abstract class StockMovementRepository {
  /// watches all stock movement for a specific product
  Stream<List<StockMovement>> watchMovementsForProduct(String productId);

  /// Adds a stock movement AND updates the product's currentStock atomically
  Future<void> addMovement(StockMovement movement);

  Stream<List<StockMovement>> watchRecentMovements({int limit = 10});
}
