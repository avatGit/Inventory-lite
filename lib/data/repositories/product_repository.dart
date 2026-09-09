import '../models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts();

  Future<Product?> getProduct(String id);

  Future<void> addProduct(Product product);

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct(String id);
}