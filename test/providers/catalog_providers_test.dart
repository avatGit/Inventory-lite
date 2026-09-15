import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_lite/data/models/category.dart';
import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';

void main() {
  final products = [
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
      name: 'Pack d eau 1,5 L',
      categoryId: 'drink',
      price: 2500,
      currentStock: 24,
      barcode: '618100987654',
    ),
  ];

  final categories = [
    Category(id: 'food', name: 'Alimentation'),
    Category(id: 'drink', name: 'Boissons'),
  ];

  test('filtre les produits par nom', () async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith((ref) => Stream.value(products)),
      ],
    );

    addTearDown(container.dispose);

    final subscription = container.listen(
      filteredProductsProvider,
      (_, _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    container.read(searchQueryProvider.notifier).setQuery('riz');

    await Future<void>.delayed(Duration.zero);

    final result = container.read(filteredProductsProvider);

    expect(result.value, isNotNull);
    expect(result.value, hasLength(1));
    expect(result.value!.first.name, 'Sac de riz 25 kg');

    subscription.close();
  });

  test('filtre les produits par catégorie', () async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith((ref) => Stream.value(products)),
      ],
    );

    addTearDown(container.dispose);

    final subscription = container.listen(
      filteredProductsProvider,
      (_, _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    container.read(selectedCategoryProvider.notifier).select('drink');

    await Future<void>.delayed(Duration.zero);

    final result = container.read(filteredProductsProvider);

    expect(result.value, isNotNull);
    expect(result.value, hasLength(1));
    expect(result.value!.first.name, 'Pack d eau 1,5 L');

    subscription.close();
  });

  test('retourne le nom de la catégorie', () async {
    final container = ProviderContainer(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      ],
    );

    addTearDown(container.dispose);

    final subscription = container.listen(
      categoryNameProvider('food'),
      (_, _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    final categoryName = container.read(categoryNameProvider('food'));

    expect(categoryName, 'Alimentation');

    subscription.close();
  });

  test('retourne Sans catégorie pour une catégorie inconnue', () async {
    final container = ProviderContainer(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      ],
    );

    addTearDown(container.dispose);

    final subscription = container.listen(
      categoryNameProvider('unknown'),
      (_, _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    final categoryName = container.read(categoryNameProvider('unknown'));

    expect(categoryName, 'Sans catégorie');

    subscription.close();
  });
}
