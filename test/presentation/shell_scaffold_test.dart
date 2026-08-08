import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/presentation/shells/shell_scaffold.dart';

import '../helpers/test_app.dart';

/// A minimal shell route so the shell gets a real [StatefulNavigationShell]
/// (it is a concrete StatefulWidget built by go_router — not mockable).
///
/// The route's `builder` is injectable so the same harness serves the shell
/// directly (destinations are supplied by the test) and the real [ShopShell].
GoRouter shellRouter(Widget Function(StatefulNavigationShell) shellBuilder) =>
    GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              shellBuilder(navigationShell),
          branches: [
            for (final (path, label) in [
              ('/a', 'Branch A'),
              ('/b', 'Branch B'),
              ('/c', 'Branch C'),
              ('/d', 'Branch D'),
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) =>
                        Center(child: Text('Content $label')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

/// Pumps [router] at [size] and returns the resolved [ShellScaffold].
Future<ShellScaffold> pumpShell(
  WidgetTester tester,
  GoRouter router,
  Size size, {
  Locale? locale,
}) async {
  await pumpRouterSurface(
    tester,
    router: router,
    size: size,
    locale: locale,
  );
  return tester.widget<ShellScaffold>(find.byType(ShellScaffold));
}

void main() {
  group('breakpoint switch', () {
    testWidgets('narrow (< wideBreakpoint) renders the bottom NavigationBar',
        (WidgetTester tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: 'Search',
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      // Labels render on the bottom bar.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('wide (>= wideBreakpoint) renders the rail and no bottom bar',
        (WidgetTester tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: 'Search',
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(1000, 700));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('719px (just below the breakpoint) renders the bar',
        (WidgetTester tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: 'Search',
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(719, 800));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('720px (exactly the breakpoint) renders the rail',
        (WidgetTester tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: 'Search',
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(720, 800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(ShellScaffold.wideBreakpoint, 720);
    });
  });

  group('badge', () {
    testWidgets('a badge count renders on its destination', (tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: [
            const ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.shopping_cart,
              selectedIcon: Icons.shopping_cart,
              label: 'Cart',
              badgeCount: 3,
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(400, 800));

      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.descendant(
            of: find.byType(Badge),
            matching: find.text('3'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the badge count converts to Eastern digits under ar',
        (tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: [
            const ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.shopping_cart,
              selectedIcon: Icons.shopping_cart,
              label: 'Cart',
              badgeCount: 3,
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(400, 800),
          locale: const Locale('ar'));

      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.descendant(
            of: find.byType(Badge),
            matching: find.text('٣'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a zero badge count hides the label entirely', (tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            ShellDestination(
              icon: Icons.shopping_cart,
              selectedIcon: Icons.shopping_cart,
              label: 'Cart',
              badgeCount: 0,
            ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(400, 800));

      // No Badge with a "0" label anywhere (Badge.isLabelVisible = false).
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('0')),
        findsNothing,
      );
    });
  });

  group('navigation', () {
    testWidgets('tapping a destination switches to its branch',
        (WidgetTester tester) async {
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: [
            for (final label in ['A', 'B', 'C', 'D'])
              ShellDestination(
                icon: Icons.circle_outlined,
                selectedIcon: Icons.circle,
                label: label,
              ),
          ],
        ),
      );
      await pumpShell(tester, router, const Size(400, 800));

      // Initial branch.
      expect(find.text('Content Branch A'), findsOneWidget);

      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();

      // Branch C is now the active one; the others are kept alive but hidden.
      expect(find.text('Content Branch C'), findsOneWidget);
      expect(find.text('Content Branch A'), findsNothing);

      // Re-selecting the active branch is a no-op reset (stays on C).
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(find.text('Content Branch C'), findsOneWidget);
    });
  });

  group('exit action', () {
    testWidgets('wide pins the exit to the rail; tapping runs onTap',
        (WidgetTester tester) async {
      var exited = false;
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
          ],
          exitAction: (
            icon: Icons.storefront_outlined,
            label: 'Leave',
            onTap: () => exited = true,
          ),
        ),
      );
      await pumpShell(tester, router, const Size(1000, 700));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.storefront_outlined));
      await tester.pump();
      expect(exited, isTrue);
      // The exit is not a destination switch — the branch is unchanged.
      expect(find.text('Content Branch A'), findsOneWidget);
    });

    testWidgets('narrow renders the exit as an extra bar entry running onTap',
        (WidgetTester tester) async {
      var exited = false;
      final router = shellRouter(
        (navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              icon: Icons.home,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
          ],
          exitAction: (
            icon: Icons.storefront_outlined,
            label: 'Leave',
            onTap: () => exited = true,
          ),
        ),
      );
      await pumpShell(tester, router, const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      // One branch destination + the exit entry.
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(NavigationDestination),
        ),
        findsNWidgets(2),
      );

      await tester.tap(find.byIcon(Icons.storefront_outlined));
      await tester.pump();
      expect(exited, isTrue);
      expect(find.text('Content Branch A'), findsOneWidget);
    });

    testWidgets('no exit action renders no affordance in either layout',
        (WidgetTester tester) async {
      // Two branch destinations: NavigationBar requires >= 2.
      ShellScaffold shellWithoutExit(StatefulNavigationShell shell) =>
          ShellScaffold(
            navigationShell: shell,
            destinations: const [
              ShellDestination(
                icon: Icons.home,
                selectedIcon: Icons.home,
                label: 'Home',
              ),
              ShellDestination(
                icon: Icons.search,
                selectedIcon: Icons.search,
                label: 'Search',
              ),
            ],
          );

      await pumpShell(
        tester,
        shellRouter(shellWithoutExit),
        const Size(1000, 700),
      );
      expect(find.byType(IconButton), findsNothing); // no rail trailing

      await pumpShell(
        tester,
        shellRouter(shellWithoutExit),
        const Size(400, 800),
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(NavigationDestination),
        ),
        findsNWidgets(2), // branch destinations only, no exit entry
      );
    });
  });
}
