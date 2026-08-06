import 'package:equatable/equatable.dart';

/// Product grouping. A pure value object.
class Category extends Equatable {
  const Category({required this.id, required this.name, this.nameAr, this.createdAt});

  final int id;
  final String name;

  /// Optional Arabic label; `null` = English-only (the UI falls back to
  /// [name]).
  final String? nameAr;
  final DateTime? createdAt;

  static const Object _unset = Object();

  // Note: unlike Product's imagePath, createdAt uses plain `??` semantics and
  // cannot be cleared to null via copyWith — intentional (it is set once at
  // creation and never removed). nameAr CAN be cleared (the admin can drop
  // the Arabic label), so it uses the sentinel pattern.
  Category copyWith({String? name, Object? nameAr = _unset, DateTime? createdAt}) {
    assert(identical(nameAr, _unset) || nameAr is String?,
        'nameAr must be a String? or omitted');
    return Category(
      id: id,
      name: name ?? this.name,
      nameAr: identical(nameAr, _unset) ? this.nameAr : nameAr as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, nameAr, createdAt];
}
