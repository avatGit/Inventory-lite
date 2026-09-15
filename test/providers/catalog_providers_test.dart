import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory_lite/data/models/category.dart';
import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/data/repositories/category_repository.dart';
import 'package:inventory_lite/data/repositories/product_repository.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';

// ---------------------------------------------------------------------------
// 1. Fake Repository avec générateur async* (Évaluation paresseuse)
// ---------------------------------------------------------------------------

class FakeProductRepository implements ProductRepository {
  @override
  Stream<List<Product>> watchProducts() async* {
    // Le 'yield' ne s'exécute QUE lorsque Riverpod s'abonne au stream.
    // Cela élimine définitivement la race condition.
    yield [
      Product(
        id: 'p1',
        name: 'Sac de riz 25 kg',
        categoryId: 'food',
        price: 18000,
        currentStock: 15,
        barcode: '611123456789',
      ),
      Product(
        id: 'p2',
        name: 'Huile Dinor 1 L',
        categoryId: 'food',
        price: 1250,
        currentStock: 2,
        barcode: '618000123456',
      ),
      Product(
        id: 'p3',
        name: "Pack d'eau 1,5 L",
        categoryId: 'drink',
        price: 2500,
        currentStock: 24,
        barcode: '618100987654',
      ),
    ];
  }

  @override
  Future<Product?> getProduct(String id) async => null;

  @override
  Future<void> addProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String id) async {}
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories() async* {
    yield [
      Category(id: 'all', name: 'Toutes'),
      Category(id: 'food', name: 'Alimentation'),
      Category(id: 'drink', name: 'Boissons'),
    ];
  }

  @override
  Future<void> addCategory(Category category) async {}

  @override
  Future<void> updateCategory(Category category) async {}

  @override
  Future<void> deleteCategory(String id) async {}
}

// ---------------------------------------------------------------------------
// 2. Tests
// ---------------------------------------------------------------------------

void main() {
  late ProviderContainer container;

  setUp(() {
    // Initialisation du container avec les overrides
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(FakeProductRepository()),
        categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
      ],
    );

    // Garantie de nettoyage, même en cas d'échec du test
    addTearDown(container.dispose);

    // Force Riverpod à monter le provider et à initier l'abonnement au stream
    container.listen(filteredProductsProvider, (_, __) {});
  });

  test('filteredProductsProvider returns data correctly', () async {
    // 3. Attendre l'initialisation du Stream
    // Cela force le test à attendre que le stream async* ait émis son premier événement
    // et que Riverpod ait mis en cache l'état (passage de loading à data).
    await container.read(productsProvider.future);
    await container.read(categoriesProvider.future);

    // 4. Exécuter et Assert
    final result = container.read(filteredProductsProvider);

    expect(
      result.hasValue,
      isTrue,
      reason: 'Attendu AsyncData, mais reçu: $result',
    );
    expect(result.value, hasLength(3));

    // Test du filtrage par catégorie
    container.read(selectedCategoryProvider.notifier).select('food');

    // Petit délai pour laisser le provider calculé se mettre à jour
    await Future.delayed(Duration.zero);

    final filteredResult = container.read(filteredProductsProvider);
    expect(filteredResult.hasValue, isTrue);
    expect(filteredResult.value, hasLength(2));
    expect(filteredResult.value!.every((p) => p.categoryId == 'food'), isTrue);
  });

  test('search query filtering is case-insensitive', () async {
    await container.read(productsProvider.future);
    await container.read(categoriesProvider.future);

    container.read(searchQueryProvider.notifier).setQuery('RIZ');
    await Future.delayed(Duration.zero);

    final result = container.read(filteredProductsProvider);
    expect(result.hasValue, isTrue);
    expect(result.value, hasLength(1));
    expect(result.value!.first.id, 'p1');
  });

  test('returns empty list when no product matches', () async {
    await container.read(productsProvider.future);
    await container.read(categoriesProvider.future);

    container.read(searchQueryProvider.notifier).setQuery('inexistant');
    await Future.delayed(Duration.zero);

    final result = container.read(filteredProductsProvider);
    expect(result.hasValue, isTrue);
    expect(result.value, isEmpty);
  });
}
