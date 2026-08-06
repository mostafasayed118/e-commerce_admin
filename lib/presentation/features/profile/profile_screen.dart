import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/message_view.dart';
import 'profile_cubit.dart';
import 'widgets/profile_form.dart';

/// The customer's profile tab: an editable form of the saved shipping
/// details (name / phone / address) — the same [ShippingInfo] the checkout
/// pre-fills from and [PlaceOrder] saves — followed by the persisted
/// Appearance / Language preferences and the admin entry
/// ([ProfileForm] + [ProfileSettingsSection] in `widgets/`).
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
          ProfileLoaded() => ProfileForm(state: state),
        },
      ),
    );
  }
}
