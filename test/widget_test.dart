import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory_lite/main.dart';
import 'package:inventory_lite/providers/catalog_providers.dart';

void main() {
  testWidgets('InventoryLite app displays catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsProvider.overrideWith((ref) => Stream.value([])),
          categoriesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const InventoryLiteApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Aucun produit trouvé'), findsOneWidget);
  });
}
