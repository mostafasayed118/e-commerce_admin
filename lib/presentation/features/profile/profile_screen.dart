import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/shipping_info.dart';
import '../../../domain/usecases/checkout/validate_shipping.dart';
import '../../widgets/message_view.dart';
import 'profile_cubit.dart';

/// The customer's profile tab: an editable form of the saved shipping
/// details (name / phone / address) — the same [ShippingInfo] the checkout
/// pre-fills from and [PlaceOrder] saves.
///
/// Reactive seeding: the form is driven by the watch stream, so a profile
/// saved during checkout appears here automatically. The `_dirty` guard
/// ensures an external update never clobbers fields the user is mid-typing.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
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
  /// form can never disagree with [SaveProfile]'s own validation.
  String? _validateField(String field) {
    final errors = validateShipping(ShippingInfo(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
    ));
    return errors[field];
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
    final state = widget.state;
    final isEmpty = state.profile.isEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Used to pre-fill the checkout form. '
            'Orders always carry their own snapshot of these details.',
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
                      'No saved details yet — fill them in here, or checkout '
                      'will save them automatically.',
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
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
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
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (_) => _validateField(kShippingPhoneField),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-address'),
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (_) => _validateField(kShippingAddressField),
          ),
          const SizedBox(height: 8),
          if (state.saveError != null) ...[
            Text(
              state.saveError!,
              key: const Key('profile-error'),
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 8),
          ] else if (state.justSaved) ...[
            Text(
              'Profile saved.',
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
                : const Text('Save profile'),
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
            title: const Text('Admin dashboard'),
            subtitle: const Text('PIN-protected shop management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/admin/gate'),
          ),
        ],
      ),
    );
  }
}
