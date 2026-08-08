import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/theme/app_theme.dart';

/// Pins AppTheme's contract: one seed drives both brightnesses (so light and
/// dark stay visually consistent), and the component themes are tuned lightly
/// — flat app bars, a taller bottom bar + always-labeled rail (the admin
/// shell's navigation), rounded inputs, and flat rounded cards.
void main() {
  test('light and dark derive from one brand seed at their brightness', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);

    // ColorScheme.fromSeed picks the primary from the seed's tonal palette at
    // a different tone per brightness (light ~40, dark ~80). The M3 tonal
    // adaptation nudges the hue a fraction of a degree across tones, so a 1°
    // window pins "same seed family" while still rejecting a different seed
    // (which would differ by tens of degrees).
    final lightHue = HSLColor.fromColor(light.colorScheme.primary).hue;
    final darkHue = HSLColor.fromColor(dark.colorScheme.primary).hue;
    expect(darkHue, closeTo(lightHue, 1.0));
  });

  test('the app bar is flat and each theme matches its own scheme surfaces',
      () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final appBar = theme.appBarTheme;
      expect(appBar.centerTitle, isFalse);
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 1);
      expect(appBar.backgroundColor, theme.colorScheme.surface);
      expect(appBar.foregroundColor, theme.colorScheme.onSurface);
    }
  });

  test('navigation is tuned for the bottom bar and the admin rail', () {
    final theme = AppTheme.light;

    final navBar = theme.navigationBarTheme;
    expect(navBar.height, 68);
    expect(navBar.indicatorColor, theme.colorScheme.secondaryContainer);

    // The admin shell's rail always shows labels (no collapsed hover-only
    // state), so destinations stay readable on the wide admin layout.
    final rail = theme.navigationRailTheme;
    expect(rail.labelType, NavigationRailLabelType.all);
  });

  test('inputs get rounded borders with consistent padding', () {
    final input = AppTheme.light.inputDecorationTheme;

    final border = input.border;
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border as OutlineInputBorder).borderRadius,
      BorderRadius.circular(12),
    );
    expect(
      input.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  });

  test('cards are flat, rounded, and sit on the surface container', () {
    final theme = AppTheme.light;
    final card = theme.cardTheme;

    expect(card.elevation, 0);
    expect(card.margin, EdgeInsets.zero);
    expect(card.color, theme.colorScheme.surfaceContainerLow);

    final shape = card.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    expect(
      (shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
  });
}
