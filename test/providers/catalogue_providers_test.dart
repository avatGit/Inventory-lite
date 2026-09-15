import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory_lite/data/models/category.dart';
import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/data/repositories/category_repository.dart';
import 'package:inventory_lite/data/repositories/product_repository.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';

// ---------------------------------------------------------------------------
// Fake Repositories (No Firestore dependency)
// ---------------------------------------------------------------------------

class FakeProductRepository implements ProductRepository {
  final StreamController<List<Product>> _controller =
      StreamController<List<Product>>.broadcast();

  FakeProductRepository(List<Product> initial) {
    _controller.add(List.unmodifiable(initial));
  }

  @override
  Stream<List<Product>> watchProducts() => _controller.stream;

  @override
  Future<Product?> getProduct(String id) async => null;

  @override
  Future<void> addProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String id) async {}

  void dispose() => _controller.close();
}

class FakeCategoryRepository implements CategoryRepository {
  final StreamController<List<Category>> _controller =
      StreamController<List<Category>>.broadcast();

  FakeCategoryRepository(List<Category> initial) {
    _controller.add(List.unmodifiable(initial));
  }

  @override
  Stream<List<Category>> watchCategories() => _controller.stream;

  @override
  Future<void> addCategory(Category category) async {}

  @override
  Future<void> updateCategory(Category category) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  void dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Seed Data
// ---------------------------------------------------------------------------

final _seedCategories = [
  Category(id: 'all', name: 'Toutes'),
  Category(id: 'food', name: 'Alimentation'),
  Category(id: 'drink', name: 'Boissons'),
];

final _seedProducts = [
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ProviderContainer container;
  late FakeProductRepository fakeProductRepo;
  late FakeCategoryRepository fakeCategoryRepo;

  setUp(() {
    fakeProductRepo = FakeProductRepository(_seedProducts);
    fakeCategoryRepo = FakeCategoryRepository(_seedCategories);

    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(fakeProductRepo),
        categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    fakeProductRepo.dispose();
    fakeCategoryRepo.dispose();
  });

  // Wait for StreamProviders to emit their first value
  Future<void> waitForData() async {
    await container.read(productsProvider.future);
    await container.read(categoriesProvider.future);
  }

  group('filteredProductsProvider', () {
    test('returns all products when no filter and no search query', () async {
      await waitForData();

      final result = container.read(filteredProductsProvider);

      expect(result.hasValue, isTrue);
      expect(result.value!.length, 3);
    });

    group('category filtering', () {
      test('returns only food products when category is "food"', () async {
        await waitForData();

        container.read(selectedCategoryProvider.notifier).select('food');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 2);
        expect(result.value!.every((p) => p.categoryId == 'food'), isTrue);
      });

      test('returns only drink products when category is "drink"', () async {
        await waitForData();

        container.read(selectedCategoryProvider.notifier).select('drink');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 1);
        expect(result.value!.first.name, contains("Pack d'eau"));
      });

      test('returns all products when category is reset to "all"', () async {
        await waitForData();

        container.read(selectedCategoryProvider.notifier).select('food');
        container.read(selectedCategoryProvider.notifier).reset();

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 3);
      });
    });

    group('search query filtering', () {
      test('is case-insensitive: "riz" matches "Sac de riz"', () async {
        await waitForData();

        container.read(searchQueryProvider.notifier).setQuery('riz');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p1');
      });

      test('is case-insensitive: "HUILE" matches "Huile Dinor"', () async {
        await waitForData();

        container.read(searchQueryProvider.notifier).setQuery('HUILE');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p2');
      });

      test('matches by barcode', () async {
        await waitForData();

        container.read(searchQueryProvider.notifier).setQuery('618100987654');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p3');
      });

      test('returns empty list when no product matches', () async {
        await waitForData();

        container.read(searchQueryProvider.notifier).setQuery('xyznonexistent');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.isEmpty, isTrue);
      });

      test('clears search query and restores full list', () async {
        await waitForData();

        container.read(searchQueryProvider.notifier).setQuery('riz');
        container.read(searchQueryProvider.notifier).clear();

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 3);
      });
    });

    group('combined filters (category + search)', () {
      test('filters by category first, then by search query', () async {
        await waitForData();

        container.read(selectedCategoryProvider.notifier).select('food');
        container.read(searchQueryProvider.notifier).setQuery('huile');

        final result = container.read(filteredProductsProvider);

        expect(result.hasValue, isTrue);
        expect(result.value!.length, 1);
        expect(result.value!.first.id, 'p2');
      });

      test(
        'returns empty when search matches a product outside selected category',
        () async {
          await waitForData();

          // "Pack d'eau" is in 'drink', but we filter by 'food'
          container.read(selectedCategoryProvider.notifier).select('food');
          container.read(searchQueryProvider.notifier).setQuery("pack d'eau");

          final result = container.read(filteredProductsProvider);

          expect(result.hasValue, isTrue);
          expect(result.value!.isEmpty, isTrue);
        },
      );
    });
  });
}
