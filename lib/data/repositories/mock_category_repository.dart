import '../mock/mock_data.dart';
import '../models/category.dart';
import 'category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  final List<Category> _categories = List<Category>.from(mockCategories);

  @override
  Stream<List<Category>> watchCategories() async* {
    yield List<Category>.unmodifiable(_categories);
  }

  @override
  Future<void> addCategory(Category category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere(
      (item) => item.id == category.id,
    );

    if (index == -1) {
      return;
    }

    _categories[index] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (id == 'all') {
      return;
    }

    _categories.removeWhere((category) => category.id == id);
  }
}