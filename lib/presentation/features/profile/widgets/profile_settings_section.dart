import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../locale/locale_cubit.dart';
import '../../../theme/theme_cubit.dart';

/// The profile tab's preferences block: the persisted **Appearance** (theme)
/// and **Language** (AR/EN) switches plus the admin dashboard entry.
///
/// The two settings Cubits are DI singletons backed by the UiPrefs table, so
/// both choices survive restarts. The explicit `bloc:` keeps this testable
/// without the app root's MultiBlocProvider (the flow tests pump the raw
/// router).
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.preferences, style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Text(
          l10n.appearance,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Theme switch — persisted via the DI ThemeCubit (UiPrefs table),
        // so the choice survives restarts.
        BlocBuilder<ThemeCubit, ThemeMode>(
          bloc: getIt<ThemeCubit>(),
          builder: (context, mode) => SegmentedButton<ThemeMode>(
            key: const Key('profile-theme-mode'),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.system),
                icon: const Icon(Icons.brightness_auto_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.light),
                icon: const Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.dark),
                icon: const Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) =>
                getIt<ThemeCubit>().setThemeMode(selection.first),
          ),
        ),
        const SizedBox(height: 24),
        // Language switch — persisted via the DI LocaleCubit (UiPrefs
        // table) and applied instantly by MaterialApp (locale + RTL). Each
        // language is shown in its OWN name ('English'/'العربية') — the
        // i18n convention: language names are never translated.
        Text(
          l10n.language,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<LocaleCubit, Locale>(
          bloc: getIt<LocaleCubit>(),
          builder: (context, locale) => SegmentedButton<Locale>(
            key: const Key('profile-locale'),
            segments: const [
              ButtonSegment(
                value: Locale('en'),
                label: Text('English'),
                icon: Icon(Icons.language, size: 18),
              ),
              ButtonSegment(
                value: Locale('ar'),
                label: Text('العربية'),
                icon: Icon(Icons.translate, size: 18),
              ),
            ],
            selected: {locale},
            onSelectionChanged: (selection) => getIt<LocaleCubit>()
                .setLocaleCode(selection.first.languageCode),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        // The one on-screen entry to the admin area (everything else under
        // /admin/ is reached after the PIN gate; the router guard keeps it
        // locked). Placed here — the profile tab is "your account" — so the
        // dashboard is discoverable without cluttering the shop shell.
        ListTile(
          key: const Key('profile-admin-entry'),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(l10n.adminDashboard),
          subtitle: Text(l10n.adminDashboardSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/admin/gate'),
        ),
      ],
    );
  }
}
