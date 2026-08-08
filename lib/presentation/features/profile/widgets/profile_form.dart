import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/shipping_info.dart';
import '../../../../domain/usecases/checkout/validate_shipping.dart';
import '../../../l10n/error_messages.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/responsive/content_max_width.dart';
import '../../../widgets/responsive/responsive_breakpoints.dart';
import '../../../widgets/shipping_info_fields.dart';
import '../profile_cubit.dart';
import 'profile_settings_section.dart';

/// The profile tab's editable form of the saved shipping details (name /
/// phone / address) — the same [ShippingInfo] the checkout pre-fills from and
/// [PlaceOrder] saves.
///
/// Reactive seeding: the form is driven by the watch stream, so a profile
/// saved during checkout appears here automatically. The `_dirty` guard
/// ensures an external update never clobbers fields the user is mid-typing.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.state});

  final ProfileLoaded state;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
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
  void didUpdateWidget(covariant ProfileForm oldWidget) {
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
      child: ContentMaxWidth(
        maxWidth: ResponsiveBreakpoints.formMaxWidth,
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
          ShippingInfoFields(
            nameController: _name,
            phoneController: _phone,
            addressController: _address,
            validateField: _validateField,
            nameKey: 'profile-name',
            phoneKey: 'profile-phone',
            addressKey: 'profile-address',
            onChanged: (_) => setState(() => _dirty = true),
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
          const ProfileSettingsSection(),
        ],
      ),
      ),
    );
  }
}
