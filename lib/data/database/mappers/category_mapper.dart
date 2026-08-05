import '../../../core/entities/category.dart';
// Row classes are generated in app_database.g.dart (part of app_database.dart).
import '../app_database.dart';

/// Converts between the drift row and the domain [Category] entity.
class CategoryMapper {
  Category toEntity(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  // Writes go through companions built in the repository, so there is no
  // entity -> row mapping here.
}
