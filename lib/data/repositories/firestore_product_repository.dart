import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_repository.dart';

class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productRef => _firestore.collection('products');

  @override
  Stream<List<Product>> watchProducts() {
    return _productRef.snapshots().map((snapshots){
      return snapshots.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<Product?> getProduct(String id) async {
    final doc = await _productRef.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> addProduct(Product product) async {
    await _productRef.doc(product.id).set(product.toMap());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _productRef.doc(product.id).update(product.toMap());
  }

  @override
  Future<void> deleteProduct(String id ) async{
    await _productRef.doc(id).delete();
  }
}