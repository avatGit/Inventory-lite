import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_lite/data/models/stock_movement.dart';
import 'package:inventory_lite/data/repositories/firestore_stock_movement_repository.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreStockMovementRepository repository;

  // Seed a product document before each test
  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreStockMovementRepository(firestore: fakeFirestore);

    await fakeFirestore.collection('products').doc('p1').set({
      'name': 'Sac de riz 25 kg',
      'categoryId': 'food',
      'price': 18000,
      'currentStock': 10,
    });
  });

  // Helper to read current stock from fake Firestore
  Future<int> getCurrentStock(String productId) async {
    final doc = await fakeFirestore.collection('products').doc(productId).get();
    return (doc.data()?['currentStock'] as num?)?.toInt() ?? 0;
  }

  // Helper to count movement documents
  Future<int> getMovementCount() async {
    final snapshot = await fakeFirestore.collection('stock_movements').get();
    return snapshot.docs.length;
  }

  group('FirestoreStockMovementRepository - addMovement', () {
    group('inStock (entrée de stock)', () {
      test('increases product currentStock by movement quantity', () async {
        final movement = StockMovement(
          id: '',
          productId: 'p1',
          type: MovementType.inStock,
          quantity: 5,
          date: DateTime.now(),
          note: 'Réapprovisionnement',
        );

        await repository.addMovement(movement);

        expect(await getCurrentStock('p1'), 15); // 10 + 5
        expect(await getMovementCount(), 1);
      });

      test('creates a movement document with correct fields', () async {
        final now = DateTime.now();
        final movement = StockMovement(
          id: '',
          productId: 'p1',
          type: MovementType.inStock,
          quantity: 3,
          date: now,
          note: 'Livraison fournisseur',
        );

        await repository.addMovement(movement);

        final movements = await fakeFirestore
            .collection('stock_movements')
            .get();
        final movementDoc = movements.docs.first.data();

        expect(movementDoc['productId'], 'p1');
        expect(movementDoc['type'], 'inStock');
        expect(movementDoc['quantity'], 3);
        expect(movementDoc['note'], 'Livraison fournisseur');
        // Verify date is stored as a Firestore Timestamp
        expect(movementDoc['date'], isA<Timestamp>());
      });
    });

    group('outStock (sortie de stock)', () {
      test('decreases product currentStock by movement quantity', () async {
        final movement = StockMovement(
          id: '',
          productId: 'p1',
          type: MovementType.outStock,
          quantity: 4,
          date: DateTime.now(),
          note: 'Vente client',
        );

        await repository.addMovement(movement);

        expect(await getCurrentStock('p1'), 6); // 10 - 4
        expect(await getMovementCount(), 1);
      });

      test('allows stock to reach exactly zero', () async {
        final movement = StockMovement(
          id: '',
          productId: 'p1',
          type: MovementType.outStock,
          quantity: 10,
          date: DateTime.now(),
          note: 'Liquidation totale',
        );

        await repository.addMovement(movement);

        expect(await getCurrentStock('p1'), 0);
        expect(await getMovementCount(), 1);
      });
    });

    group('atomic transaction safety', () {
      test('throws exception when stock would go below zero', () async {
        final movement = StockMovement(
          id: '',
          productId: 'p1',
          type: MovementType.outStock,
          quantity: 99,
          // Only 10 in stock
          date: DateTime.now(),
          note: 'Tentative impossible',
        );

        expect(
          () => repository.addMovement(movement),
          throwsA(isA<Exception>()),
        );
      });

      test(
        'does NOT create movement document when transaction fails',
        () async {
          final movement = StockMovement(
            id: '',
            productId: 'p1',
            type: MovementType.outStock,
            quantity: 99,
            date: DateTime.now(),
            note: 'Devrait échouer',
          );

          try {
            await repository.addMovement(movement);
          } catch (_) {}

          // Atomicity: neither the stock update nor the movement should exist
          expect(await getCurrentStock('p1'), 10); // Unchanged
          expect(await getMovementCount(), 0); // No document created
        },
      );

      test('throws exception when product does not exist', () async {
        final movement = StockMovement(
          id: '',
          productId: 'nonexistent_product',
          type: MovementType.inStock,
          quantity: 5,
          date: DateTime.now(),
          note: 'Produit fantôme',
        );

        expect(
          () => repository.addMovement(movement),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('defensive data handling', () {
      test(
        'handles missing currentStock field gracefully (defaults to 0)',
        () async {
          // Create a product without the currentStock field
          await fakeFirestore.collection('products').doc('p2').set({
            'name': 'Produit sans stock',
            'categoryId': 'food',
            'price': 500,
          });

          final movement = StockMovement(
            id: '',
            productId: 'p2',
            type: MovementType.inStock,
            quantity: 7,
            date: DateTime.now(),
            note: 'Premier approvisionnement',
          );

          await repository.addMovement(movement);

          expect(await getCurrentStock('p2'), 7); // 0 + 7
        },
      );
    });
  });
}
