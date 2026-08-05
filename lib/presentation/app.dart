import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection.dart';
import 'locale/locale_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';

/// The app root: persisted theme + locale (Material 3 light/dark, AR/EN)
/// and the GoRouter.
///
/// Both settings Cubits are DI-owned singletons (persisted via the drift
/// UiPrefs table) and provided here so any screen can read them — the
/// Profile tab hosts the switches. Everything below is pure presentation:
/// state and data flow through GetIt-injected Cubits/repositories (Clean
/// Architecture layers).
class ShopAdminApp extends StatelessWidget {
  const ShopAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp.router(
            title: 'Shop Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: LocaleCubit.supported,
            routerConfig: buildAppRouter(),
          ),
        ),
      ),
    );
  }
}
