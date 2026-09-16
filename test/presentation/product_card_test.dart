import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_lite/data/models/product.dart';
import 'package:inventory_lite/presentation/widgets/product_card.dart';

void main() {
  Widget buildTestWidget(Product product) {
    return MaterialApp(
      home: Scaffold(
        body: ProductCard(product: product, categoryName: 'Alimentation'),
      ),
    );
  }

  testWidgets('affiche correctement un produit disponible', (
    WidgetTester tester,
  ) async {
    final product = Product(
      id: 'p1',
      name: 'Sac de riz 25 kg',
      categoryId: 'food',
      price: 18000,
      currentStock: 15,
      barcode: '611123456789',
    );

    await tester.pumpWidget(buildTestWidget(product));

    expect(find.text('Sac de riz 25 kg'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('18000 FCFA'), findsOneWidget);
    expect(find.text('Code : 611123456789'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('affiche le statut faible lorsque le stock est bas', (
    WidgetTester tester,
  ) async {
    final product = Product(
      id: 'p2',
      name: 'Huile Dinor 1 L',
      categoryId: 'food',
      price: 1250,
      currentStock: 2,
    );

    await tester.pumpWidget(buildTestWidget(product));

    expect(find.text('Huile Dinor 1 L'), findsOneWidget);
    expect(find.text('Faible'), findsOneWidget);
  });

  testWidgets('affiche le statut rupture lorsque le stock est à zéro', (
    WidgetTester tester,
  ) async {
    final product = Product(
      id: 'p6',
      name: 'Détergent 1 kg',
      categoryId: 'household',
      price: 1750,
      currentStock: 0,
    );

    await tester.pumpWidget(buildTestWidget(product));

    expect(find.text('Détergent 1 kg'), findsOneWidget);
    expect(find.text('Rupture'), findsOneWidget);
  });
}
