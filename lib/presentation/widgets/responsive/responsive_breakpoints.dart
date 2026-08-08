/// Shared responsive breakpoints for the app's constraint-based layouts.
///
/// Everything here is measured against the *available content width* (the
/// same `LayoutBuilder` convention as [ShellScaffold.wideBreakpoint]) — never
/// against a device or platform string. The breakpoints are deliberately
/// chosen so the widget-test suite's fixed viewports (390 / 420 / 800 / 900 /
/// 1200) exercise both sides of every switch deterministically:
///
/// * [contentMaxWidth] — above this, page content stops growing and centers.
///   The catalog grid already self-adapts via `maxCrossAxisExtent`.
/// * [twoPane] — wide enough to split a screen into two panes (product
///   detail image|info, checkout form|summary). Sits between the admin-flow
///   viewport (900) and the shell rail test (1200), so two-pane only engages
///   on genuinely wide windows/desktops.
/// * [formRow] — wide enough to lay form fields side by side. Between the
///   narrow shop flows (390/420) and the form tests (800).
abstract final class ResponsiveBreakpoints {
  /// Page content (lists, grids, dashboards) stops growing at this width.
  static const double contentMaxWidth = 1200;

  /// Screens with a natural left/right split use two panes at this width.
  static const double twoPane = 1000;

  /// Form fields (e.g. shipping name+phone, pricing) sit side by side at
  /// this width and stack below it.
  static const double formRow = 700;

  /// Forms are capped tighter than page lists — long text lines read better.
  static const double formMaxWidth = 760;
}
