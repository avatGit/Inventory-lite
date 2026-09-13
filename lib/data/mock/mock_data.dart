import '../models/category.dart';
import '../models/product.dart';

/// Temporary local data used for development and tests.
final List<Category> mockCategories = [
  Category(id: 'all', name: 'Toutes'),
  Category(id: 'food', name: 'Alimentation'),
  Category(id: 'drink', name: 'Boissons'),
  Category(id: 'hygiene', name: 'Hygiène'),
  Category(id: 'household', name: 'Maison'),
];

final List<Product> mockProducts = [
  Product(
    id: 'p1',
    name: 'Sac de riz 25 kg',
    categoryId: 'food',
    price: 18000,
    currentStock: 15,
    barcode: '611123456789',
  ),
  Product(
    id: 'p2',
    name: 'Huile Dinor 1 L',
    categoryId: 'food',
    price: 1250,
    currentStock: 2,
    barcode: '618000123456',
  ),
  Product(
    id: 'p3',
    name: "Pack d'eau 1,5 L",
    categoryId: 'drink',
    price: 2500,
    currentStock: 24,
    barcode: '618100987654',
  ),
  Product(
    id: 'p4',
    name: 'Savon de toilette',
    categoryId: 'hygiene',
    price: 500,
    currentStock: 8,
    barcode: '619200112233',
  ),
  Product(
    id: 'p5',
    name: 'Lait en poudre 500 g',
    categoryId: 'food',
    price: 3200,
    currentStock: 12,
    barcode: '620300445566',
  ),
  Product(
    id: 'p6',
    name: 'Détergent 1 kg',
    categoryId: 'household',
    price: 1750,
    currentStock: 0,
    barcode: '621400778899',
  ),
];