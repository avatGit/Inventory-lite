import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_lite/data/models/stock_movement.dart';
import 'package:inventory_lite/data/repositories/firestore_stock_movement_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreStockMovementRepository repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreStockMovementRepository(firestore: fakeFirestore);
    await fakeFirestore.collection('products').doc('p1').set({
      'name': 'Riz',
      'categoryId': 'food',
      'price': 1000,
      'currentStock': 10,
    });
  });

  Future<int> getCurrentStock(String id) async {
    final doc = await fakeFirestore.collection('products').doc(id).get();
    return (doc.data()?['currentStock'] as num?)?.toInt() ?? 0;
  }

  test('addMovement increases stock correctly', () async {
    final movement = StockMovement(
      id: '',
      productId: 'p1',
      type: MovementType.inStock,
      quantity: 5,
      date: DateTime.now(),
      note: 'Test',
    );

    await repository.addMovement(movement);

    expect(await getCurrentStock('p1'), 15);
    final movements = await fakeFirestore.collection('stock_movements').get();
    expect(movements.docs.length, 1);
  });

  test('addMovement throws if stock goes below zero', () async {
    final movement = StockMovement(
      id: '',
      productId: 'p1',
      type: MovementType.outStock,
      quantity: 99,
      date: DateTime.now(),
      note: 'Test',
    );

    expect(() => repository.addMovement(movement), throwsA(isA<Exception>()));
    expect(
      await getCurrentStock('p1'),
      10,
    ); // Le stock ne doit pas avoir changé
  });
}
