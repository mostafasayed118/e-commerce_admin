import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/features/admin/widgets/admin_fab.dart';

void main() {
  testWidgets('renders the add icon, label, and unique heroTag',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminFab(
            branch: 'products',
            label: 'New product',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('New product'), findsOneWidget);

    // The heroTag convention is the whole point of the shared FAB: the tag
    // is derived from the branch so kept-alive shell branches never collide.
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.heroTag, 'admin-products-fab');
  });

  testWidgets('distinct branches yield distinct heroTags',
      (WidgetTester tester) async {
    // Two FABs coexisting (as the kept-alive shell branches do) must carry
    // distinct tags — the default FloatingActionButton tag would throw
    // "multiple heroes share the same tag" on the next route push.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AdminFab(branch: 'products', label: 'A', onPressed: () {}),
              AdminFab(branch: 'categories', label: 'B', onPressed: () {}),
              AdminFab(branch: 'coupons', label: 'C', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    final tags = tester
        .widgetList<FloatingActionButton>(find.byType(FloatingActionButton))
        .map((fab) => fab.heroTag)
        .toList();
    // Compare set-to-set so the assertion is order-independent.
    expect(tags.toSet(), {
      'admin-products-fab',
      'admin-categories-fab',
      'admin-coupons-fab',
    });
    expect(tags.toSet().length, 3); // all distinct
  });

  testWidgets('wires onPressed', (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminFab(
            branch: 'products',
            label: 'New product',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('New product'));
    expect(tapped, 1);
  });
}
