class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Category copyWith({String? id, String? name}) {
    return Category(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  factory Category.fromMap(Map<String, dynamic> map, String documentId) {
    return Category(id: documentId, name: map['name'] ?? '');
  }
}
