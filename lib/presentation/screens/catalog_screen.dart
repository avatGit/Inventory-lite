import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/catalog_providers.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue'), centerTitle: false),
      body: Column(
        children: [
          _SearchField(ref: ref),
          _CategoryFilter(
            categoriesAsync: categoriesAsync,
            selectedCategory: selectedCategory,
            onCategorySelected: (categoryId) {
              ref.read(selectedCategoryProvider.notifier).select(categoryId);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(
                onRetry: () {
                  ref.invalidate(productsProvider);
                },
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final categoryName = ref.watch(
                      categoryNameProvider(product.categoryId),
                    );

                    return ProductCard(
                      product: product,
                      categoryName: categoryName,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final WidgetRef ref;

  const _SearchField({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).setQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Effacer la recherche',
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final AsyncValue categoriesAsync;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryFilter({
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: categoriesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, stackTrace) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Impossible de charger les catégories'),
          ),
        ),
        data: (categories) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(
                label: 'Tous',
                selected: selectedCategory == 'all',
                onSelected: () => onCategorySelected('all'),
              ),
              ...categories.map(
                (category) => _CategoryChip(
                  label: category.name,
                  selected: selectedCategory == category.id,
                  onSelected: () => onCategorySelected(category.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56),
            SizedBox(height: 12),
            Text(
              'Aucun produit trouvé',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Modifiez votre recherche ou votre filtre.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger le catalogue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
