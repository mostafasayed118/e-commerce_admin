import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';

import '../helpers/drift_settle.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// The detail screen is reached through the real app (memory DB + seed), the
/// same proven pump pattern as the catalog flow test — its watch stream is
/// delivered by settleDrift. Seeded 'Classic Tee' is 25% off.
void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('the discount badge renders localized digits in both locales',
      (WidgetTester tester) async {
    await pumpFullApp(tester);

    // English first: the hardcoded badge renders Western digits.
    await tester.tap(find.text('Classic Tee'));
    await tester.pump();
    await settleDrift(tester); // detail screen's watchProductById stream
    await tester.pumpAndSettle();
    expect(find.text('-25%'), findsOneWidget);

    // Flip the in-app locale: the same badge converts to Eastern digits.
    await getIt<LocaleCubit>().setLocaleCode('ar');
    await tester.pumpAndSettle();
    expect(find.text('-٢٥%'), findsOneWidget);
    expect(find.text('-25%'), findsNothing);

    await unmountApp(tester);
  });
}
