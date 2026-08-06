import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/message_view.dart';

void main() {
  Future<void> pump(WidgetTester tester, MessageView view) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));

  testWidgets('renders the icon and title', (WidgetTester tester) async {
    await pump(
      tester,
      const MessageView(icon: Icons.inbox, title: 'Your cart is empty'),
    );

    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('renders the optional message when provided',
      (WidgetTester tester) async {
    await pump(
      tester,
      const MessageView(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: 'Please try again later.',
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
  });

  testWidgets('omits the message row when not provided',
      (WidgetTester tester) async {
    await pump(
      tester,
      const MessageView(icon: Icons.check_circle, title: 'Done'),
    );

    expect(find.text('Done'), findsOneWidget);
    // No message text anywhere.
    expect(
      find.descendant(
        of: find.byType(MessageView),
        matching: find.textContaining('later'),
      ),
      findsNothing,
    );
  });

  testWidgets('renders the optional action and wires its tap',
      (WidgetTester tester) async {
    var tapped = 0;
    await pump(
      tester,
      MessageView(
        icon: Icons.add,
        title: 'No products yet',
        action: FilledButton(
          onPressed: () => tapped++,
          child: const Text('Add product'),
        ),
      ),
    );

    expect(find.text('Add product'), findsOneWidget);
    await tester.tap(find.text('Add product'));
    expect(tapped, 1);
  });
}
