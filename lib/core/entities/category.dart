import 'package:equatable/equatable.dart';

/// Product grouping. A pure value object.
class Category extends Equatable {
  const Category({required this.id, required this.name, this.createdAt});

  final int id;
  final String name;
  final DateTime? createdAt;

  // Note: unlike Product's imagePath, createdAt uses plain `??` semantics and
  // cannot be cleared to null via copyWith — intentional (it is set once at
  // creation and never removed).
  Category copyWith({String? name, DateTime? createdAt}) {
    return Category(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
