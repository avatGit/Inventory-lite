import '../mock/mock_data.dart';
import '../models/product.dart';
import 'product_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products = List<Product>.from(mockProducts);

  @override
  Stream<List<Product>> watchProducts() async* {
    yield List<Product>.unmodifiable(_products);
  }

  @override
  Future<Product?> getProduct(String id) async {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  @override
  Future<void> addProduct(Product product) async {
    _products.add(product);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere(
      (item) => item.id == product.id,
    );

    if (index == -1) {
      return;
    }

    _products[index] = product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((product) => product.id == id);
  }
}