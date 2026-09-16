import 'package:flutter/material.dart';

import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;

  const ProductCard({
    super.key,
    required this.product,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final stockStatus = _getStockStatus(product.currentStock);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (product.barcode != null &&
                      product.barcode!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Code : ${product.barcode}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StockBadge(
              label: stockStatus.label,
              color: stockStatus.color,
              quantity: product.currentStock,
            ),
          ],
        ),
      ),
    );
  }

  _StockStatus _getStockStatus(int stock) {
    if (stock <= 0) {
      return const _StockStatus(label: 'Rupture', color: Colors.red);
    }

    if (stock <= 5) {
      return const _StockStatus(label: 'Faible', color: Colors.orange);
    }

    return const _StockStatus(label: 'Disponible', color: Colors.green);
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;
  final int quantity;

  const _StockBadge({
    required this.label,
    required this.color,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Qté : $quantity',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _StockStatus {
  final String label;
  final Color color;

  const _StockStatus({required this.label, required this.color});
}
