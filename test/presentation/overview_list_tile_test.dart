import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/features/admin/overview/widgets/overview_list_tile.dart';

/// Pumps the tile standalone — it reads no localization, so a plain
/// MaterialApp is enough (the overview consumers all wrap it in a Scaffold).
Future<void> pumpTile(WidgetTester tester, OverviewListTile tile) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: tile)));

OverviewListTile tile({
  VoidCallback? onTap,
  TextStyle? titleStyle,
}) =>
    OverviewListTile(
      avatarBackground: const Color(0xFFE0F2FE),
      avatarForeground: const Color(0xFF0369A1),
      avatarIcon: Icons.local_offer,
      title: 'Top coupon',
      titleStyle: titleStyle,
      subtitle: const Text('subtitle line'),
      trailing: const Text('60% used'),
      onTap: onTap,
    );

void main() {
  testWidgets('renders the avatar, title, subtitle, and trailing',
      (WidgetTester tester) async {
    await pumpTile(tester, tile());

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, const Color(0xFFE0F2FE));
    expect(avatar.foregroundColor, const Color(0xFF0369A1));
    expect(find.byIcon(Icons.local_offer), findsOneWidget);
    expect(find.text('Top coupon'), findsOneWidget);
    expect(find.text('subtitle line'), findsOneWidget);
    expect(find.text('60% used'), findsOneWidget);
  });

  testWidgets('defaults to a w600 title and honors a style override',
      (WidgetTester tester) async {
    await pumpTile(tester, tile());
    expect(
      tester.widget<Text>(find.text('Top coupon')).style?.fontWeight,
      FontWeight.w600,
    );

    // LowStockTile passes the plain weight — the override wins as-is.
    await pumpTile(
      tester,
      tile(titleStyle: const TextStyle(fontWeight: FontWeight.normal)),
    );
    expect(
      tester.widget<Text>(find.text('Top coupon')).style?.fontWeight,
      FontWeight.normal,
    );
  });

  testWidgets('invokes onTap when tapped', (WidgetTester tester) async {
    var tapped = false;
    await pumpTile(tester, tile(onTap: () => tapped = true));

    await tester.tap(find.text('Top coupon'));

    expect(tapped, isTrue);
  });

  testWidgets('is inert without onTap', (WidgetTester tester) async {
    await pumpTile(tester, tile());

    await tester.tap(find.text('Top coupon'));
    expect(tester.takeException(), isNull);
  });
}
