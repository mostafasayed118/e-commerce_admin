import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The full-stack coverage audit: every source file under `lib/` must be
/// referenced by at least one file under `test/` — either imported directly
/// (the common case, including covered-through-composition files like the
/// mappers, which the repository tests import and round-trip) or listed in
/// [_allowed] with an explicit reason.
///
/// This is the automated form of the manual sweeps that closed the
/// presentation/data/domain coverage gaps: adding a new `lib/` source
/// without a test fails the audit until you either add the test or justify
/// an allowlist entry. Run with:
///
///     flutter test test/tool/coverage_audit_test.dart
///
/// It also runs as part of the full suite, so a coverage regression fails
/// CI the same way any other test does.
///
/// The scan assumes tests import lib files in the `package:shop_admin/...`
/// form (the repo's convention throughout) — a future relative import into
/// `lib/` would be falsely flagged, which is a benign false positive that a
/// test author can resolve by using the package form.
///
/// The same one command also guards the test-side consolidation: public
/// top-level definitions across `test/helpers/` must each live in exactly one
/// file (a duplicate would collide on import), so a helper-extraction
/// regression — e.g. a new file re-declaring an existing helper — fails here
/// instead of surfacing as an import error deep in some flow test.
void main() {
  test('every lib source file is imported by a test or explicitly listed',
      () {
    final libRoot = Directory('lib');
    final testRoot = Directory('test');
    expect(libRoot.existsSync(), isTrue);
    expect(testRoot.existsSync(), isTrue);

    // All lib/ sources, normalized to forward slashes so the package import
    // form (`package:shop_admin/<path>`) matches on any platform.
    final libFiles = <String>[
      for (final entity in libRoot.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          entity.path.replaceAll('\\', '/'),
    ]..sort();

    // The whole test tree read once; the import scan is a single regex pass.
    final testContents = StringBuffer();
    for (final entity in testRoot.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        testContents
          ..write(entity.readAsStringSync())
          ..write('\n');
      }
    }
    final tests = testContents.toString();

    final unjustified = <String>[];
    final justified = <String>[];
    for (final libPath in libFiles) {
      if (_isGenerated(libPath)) continue;
      final libRelative = libPath.substring('lib/'.length);
      final imported = RegExp(
        RegExp.escape('package:shop_admin/$libRelative'),
      ).hasMatch(tests);
      if (imported) continue;
      if (_allowed.containsKey(libPath)) {
        justified.add('$libPath\n    -- ${_allowed[libPath]}');
      } else {
        unjustified.add(libPath);
      }
    }

    if (justified.isNotEmpty) {
      // Visible during maintenance even when the audit passes.
      debugPrint('coverage audit: allowlisted (kept in place deliberately):\n'
          '${justified.join('\n')}');
    }

    // Allowlist keys must still exist: a deleted source leaves a stale entry
    // that would otherwise pass silently (renames already fail loudly, since
    // the renamed file shows up uncovered).
    final staleKeys =
        _allowed.keys.where((key) => !libFiles.contains(key)).toList();
    expect(
      staleKeys,
      isEmpty,
      reason: '_allowed entries that no longer exist — drop them:\n'
          '${staleKeys.join('\n')}',
    );

    expect(
      unjustified,
      isEmpty,
      reason: 'lib/ sources with no test reference (add a test, or extend '
          'the _allowed map with a reason):\n${unjustified.join('\n')}',
    );
  });

  test('test/helpers has no duplicated public top-level definitions', () {
    final helperDir = Directory('test/helpers');
    expect(helperDir.existsSync(), isTrue);

    // Public top-level symbols must live in exactly one helper file —
    // importing two files that both declare the same name is a compile
    // error, so a duplicate is the earliest possible consolidation break.
    // Private (`_`-prefixed) names are library-scoped and exempt. The four
    // branches cover classes/mixins/extensions/enums, typedefs (name before
    // the `=`), functions (including generic return types), and top-level
    // const/final/var declarations — any of them duplicated would collide.
    final definitions = RegExp(
      r'^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)*'
      r'(?:class|mixin|enum|extension)\s+(\w+)'
      r'|^typedef\s+(?:[^\s=]+\s+)?(\w+)\s*='
      r'|^[A-Za-z_$][\w$<>, ?.\[\]*]*\s+(\w+)\s*\('
      r'|^(?:const|final|var)\s+(?:[^\s=]+\s+)?(\w+)\s*=',
    );
    final byName = <String, List<String>>{};
    for (final entity in helperDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      for (final line in entity.readAsStringSync().split('\n')) {
        final match = definitions.firstMatch(line);
        if (match == null) continue;
        // Branch 3 (functions) must not mistake an initializer's call for a
        // declaration: `final total = computeTotal(1);` would otherwise
        // record 'computeTotal'. A real declaration's '=' (default parameter
        // values) sits inside the parens, so '=' before the first '(' means
        // the line is an expression, not a declaration.
        if (match.group(3) != null) {
          final eq = line.indexOf('=');
          final open = line.indexOf('(');
          if (eq >= 0 && (open < 0 || eq < open)) continue;
        }
        final name =
            match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4)!;
        if (name.startsWith('_')) continue;
        (byName[name] ??= []).add(path);
      }
    }

    // Guard: if the scan ever finds nothing, the check is silently disabled.
    expect(
      byName,
      isNotEmpty,
      reason: 'the helper scan must find declarations — a rename of the '
          'directory or the regex would silently defeat the check',
    );

    final duplicated = byName.entries
        .where((entry) => entry.value.length > 1)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    expect(
      duplicated,
      isEmpty,
      reason: 'duplicated public top-level definitions across test/helpers '
          '(each public helper must live in exactly one file):\n'
          '${duplicated.map((e) => '${e.key} — ${e.value.join(', ')}').join('\n')}',
    );
  });
}

/// Generated output — regenerated, never hand-edited, so no test owns them.
bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path == 'lib/l10n/app_localizations.dart' ||
    path == 'lib/l10n/app_localizations_en.dart' ||
    path == 'lib/l10n/app_localizations_ar.dart';

/// Explicit exceptions: lib/ files that no test imports directly but that are
/// covered through composition or are infrastructure. Each entry needs a
/// reason so a future reader can tell the deliberate from the accidental.
///
/// Populated from the audit's first run: every file here was verified to be
/// covered through composition (reached via the router in the flow tests,
/// re-exported by a cubit, rendered through by widget tests) rather than
/// being a real gap. If a file later gains a direct test, drop its entry.
const Map<String, String> _allowed = {
  // Schema declarations: columns/constraints are pinned through
  // app_database_test's migrations and seed_data_test, not imported.
  'lib/data/database/tables.dart': 'schema — pinned via app_database_test',

  // App entrypoint glue: main() is never invoked by any test, but the app it
  // boots (ShopAdminApp) is pumped by every full-app test via setupTestDi.
  'lib/main.dart': 'entrypoint glue — the app it boots is pumped everywhere',

  // Screens: pure wiring, reached only through the router; the flow tests
  // (catalog/cart/orders/profile/wishlist/checkout/admin_*) and the digits
  // sweep pump the full app and drive every one of them end-to-end.
  'lib/presentation/features/admin/catalog/categories_screen.dart':
      'screen — driven by admin_catalog_flow_test',
  'lib/presentation/features/admin/catalog/product_form_screen.dart':
      'screen — driven by admin_form_push_test',
  'lib/presentation/features/admin/coupons/coupon_form_screen.dart':
      'screen — driven by admin_form_push_test',
  'lib/presentation/features/admin/coupons/coupons_screen.dart':
      'screen — driven by admin_coupons_flow_test',
  'lib/presentation/features/admin/orders/admin_orders_screen.dart':
      'screen — driven by admin_orders_flow_test',
  'lib/presentation/features/admin/reviews/reviews_screen.dart':
      'screen — driven by admin_reviews_flow_test',
  'lib/presentation/features/admin/overview/admin_overview_screen.dart':
      'screen — driven by admin_overview_flow_test',
  'lib/presentation/features/catalog/catalog_screen.dart':
      'screen — driven by catalog_flow_test',
  'lib/presentation/features/catalog/product_detail_screen.dart':
      'screen — driven by catalog_flow_test + product_detail_screen_test',
  'lib/presentation/features/checkout/checkout_screen.dart':
      'screen — driven by checkout_coupon_flow_test',
  'lib/presentation/features/orders/order_detail_screen.dart':
      'screen — driven by orders_flow_test',
  'lib/presentation/features/orders/orders_screen.dart':
      'screen — driven by orders_flow_test',
  'lib/presentation/features/profile/profile_screen.dart':
      'screen — driven by profile_flow_test',
  'lib/presentation/features/wishlist/wishlist_screen.dart':
      'screen — driven by wishlist_flow_test',

  // States: re-exported by their cubit (`export '..._state.dart'`), so the
  // cubit tests construct and assert them through the cubit import.
  'lib/presentation/features/admin/orders/admin_orders_state.dart':
      'state — re-exported by admin_orders_cubit, pinned in its test',
  'lib/presentation/features/catalog/catalog_state.dart':
      'state — re-exported by catalog_cubit, pinned in its test',
  'lib/presentation/features/orders/orders_state.dart':
      'state — re-exported by orders_cubit, pinned in its test',
  'lib/presentation/features/profile/profile_state.dart':
      'state — re-exported by profile_cubit, pinned in its test',

  // Route tables + name constants: exercised through the router in
  // app_router_test and every flow test (which navigate those routes).
  'lib/presentation/router/routes/admin_routes.dart':
      'routes — exercised via app_router_test + admin flows',
  'lib/presentation/router/routes/detail_routes.dart':
      'routes — exercised via app_router_test + detail flows',
  'lib/presentation/router/routes/shop_routes.dart':
      'routes — exercised via app_router_test + shop flows',
  'lib/presentation/router/routes/route_names.dart':
      'route-name constants — used by the routes, navigated in flows',
};
