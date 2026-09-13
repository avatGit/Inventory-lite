import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_product_repository.dart';
import '../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return MockCategoryRepository();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String categoryId) {
    state = categoryId;
  }

  void reset() {
    state = 'all';
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty && selectedCategory == 'all') {
      return products;
    }

    return products.where((product) {
      final matchesCategory =
          selectedCategory == 'all' ||
          product.categoryId == selectedCategory;

      if (!matchesCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = product.name.toLowerCase();
      final barcode = product.barcode?.toLowerCase() ?? '';

      return name.contains(query) || barcode.contains(query);
    }).toList(growable: false);
  });
});

final categoryNameProvider = Provider.family<String, String>(
  (ref, categoryId) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.maybeWhen(
      data: (categories) {
        for (final category in categories) {
          if (category.id == categoryId) {
            return category.name;
          }
        }

        return 'Sans catégorie';
      },
      orElse: () => 'Sans catégorie',
    );
  },
);
