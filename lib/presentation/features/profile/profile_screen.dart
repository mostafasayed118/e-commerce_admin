import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/shipping_info.dart';
import '../../../domain/usecases/checkout/validate_shipping.dart';
import '../../l10n/error_messages.dart';
import '../../l10n/l10n_ext.dart';
import '../../locale/locale_cubit.dart';
import '../../theme/theme_cubit.dart';
import '../../widgets/message_view.dart';
import 'profile_cubit.dart';

/// The customer's profile tab: an editable form of the saved shipping
/// details (name / phone / address) — the same [ShippingInfo] the checkout
/// pre-fills from and [PlaceOrder] saves.
///
/// Reactive seeding: the form is driven by the watch stream, so a profile
/// saved during checkout appears here automatically. The `_dirty` guard
/// ensures an external update never clobbers fields the user is mid-typing.
///
/// Also hosts the persisted **Appearance** (theme) and **Language** (AR/EN)
/// switches — the two settings Cubits are DI singletons backed by the
/// UiPrefs table, so both choices survive restarts.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>.value(
      value: getIt<ProfileCubit>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileError() => MessageView(
              icon: Icons.error_outline,
              title: l10n.somethingWentWrong,
              message: l10n.errorLoadFailed,
            ),
          ProfileLoaded() => _ProfileForm(state: state),
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.state});

  final ProfileLoaded state;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.state.profile.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.state.profile.phone);
  late final TextEditingController _address =
      TextEditingController(text: widget.state.profile.address);

  /// True once the user has edited any field. While dirty, incoming stream
  /// emissions (e.g. a profile saved during checkout) must NOT overwrite the
  /// in-progress edits — the seeded values are the user's now.
  bool _dirty = false;

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A successful save *commits* the fields: the form is pristine again, so
    // a later external change (a checkout saving a different profile) can
    // re-sync it. Editing once more re-arms the guard.
    if (widget.state.justSaved && !oldWidget.state.justSaved) {
      _dirty = false;
    }
    final updated = widget.state.profile;
    // Re-seed only when the stream delivered a *different* profile and the
    // form is pristine — otherwise the cubit's own re-emission after a save
    // would blink the fields back to the old values mid-edit.
    if (!_dirty && updated != oldWidget.state.profile) {
      _name.text = updated.name;
      _phone.text = updated.phone;
      _address.text = updated.address;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Field validators reuse the domain rules (validate_shipping.dart) so the
  /// form can never disagree with [SaveProfile]'s own validation. The domain
  /// returns stable [AppErrorCode]s; the UI renders them in the active
  /// locale (Task 23 refactor).
  String? _validateField(String field) {
    final errors = validateShipping(ShippingInfo(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
    ));
    final code = errors[field];
    return code == null ? null : errorTextForCode(context, code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<ProfileCubit>().save(ShippingInfo(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final state = widget.state;
    final isEmpty = state.profile.isEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.yourDetails, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.profileHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.noSavedDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.fullName,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (_) => _validateField(kShippingNameField),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phone,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (_) => _validateField(kShippingPhoneField),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-address'),
            controller: _address,
            decoration: InputDecoration(
              labelText: l10n.deliveryAddress,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (_) => _validateField(kShippingAddressField),
          ),
          const SizedBox(height: 8),
          if (state.saveErrorCode != null) ...[
            Text(
              errorTextForCode(context, state.saveErrorCode!),
              key: const Key('profile-error'),
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 8),
          ] else if (state.justSaved) ...[
            Text(
              l10n.profileSaved,
              key: const Key('profile-saved'),
              style: TextStyle(color: scheme.tertiary),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            key: const Key('profile-save'),
            onPressed: state.saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: state.saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveProfile),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
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
          // so the choice survives restarts. The explicit `bloc:` (like the
          // shell badge) keeps this screen testable without the app root's
          // MultiBlocProvider (the flow tests pump the raw router).
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
      ),
    );
  }
}
