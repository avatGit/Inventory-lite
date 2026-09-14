import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import 'category_repository.dart';

class FirestoreCategoryRepository implements CategoryRepository{
  final firebaseFirestore _firestore;

  FirestoreCategoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesRef => _firestore.collection('categories');

  @override
  Stream<List<Category>> watchCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc){return Category.fromMap(doc.data(), doc.id);}).toList();
    } );
  }

  @override
  Future<void> addCategory(Category category) async {
    // We let Firestore generate the ID, or use category.id if explicitly set.
    // Assuming category.id is meant to be the doc ID:
    await _categoriesRef.doc(category.id).set(category.toMap());
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _categoriesRef.doc(category.id).update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categoriesRef.doc(id).delete();
  }
}