import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';

/// The app root: theme management (Material 3 light/dark) + the GoRouter.
///
/// Everything below is pure presentation — all state and data flow through
/// GetIt-injected Cubits/repositories (Clean Architecture layers).
class ShopAdminApp extends StatelessWidget {
  const ShopAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Shop Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: buildAppRouter(),
          );
        },
      ),
    );
  }
}
