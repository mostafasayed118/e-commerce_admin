import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';

/// Wraps a [GoRouter] in the app's localization delegates, mirroring what
/// [ShopAdminApp] does — the flow tests pump the raw router (not the app
/// root), and every screen now reads `context.l10n`, so without the delegates
/// those tests would throw. The default platform locale (en_US) resolves to
/// English, keeping existing string assertions intact.
Widget testApp(GoRouter router) => MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
