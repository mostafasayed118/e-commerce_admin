import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../core/entities/shipping_info.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/checkout/place_order.dart';
import '../../../domain/usecases/checkout/validate_shipping.dart';
import '../../l10n/error_messages.dart';
import '../../l10n/l10n_ext.dart';
import 'order_success_view.dart';

/// Checkout: the shipping form → [PlaceOrder] → the success screen
/// ([OrderSuccessView]).
///
/// One screen, three local steps (form / placing / success) — small enough
/// that a Cubit would be ceremony (Section C.3). The form pre-fills from the
/// saved customer profile (best-effort read; failures just leave it blank).
///
/// The success view shows the snapshot totals and order number; the cart is
/// already cleared by `placeOrder` (Task 8) by the time we get here.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _saveProfile = true;
  bool _placing = false;
  String? _error;
  Order? _placed; // non-null → success view

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final profile = await getIt<SettingsRepository>().getProfile();
    if (!mounted) return;
    profile.fold(
      onSuccess: (info) {
        if (info == null || info.isEmpty) return;
        _name.text = info.name;
        _phone.text = info.phone;
        _address.text = info.address;
      },
      // Best-effort convenience: a failed read leaves the form blank.
      onFailure: (_) {},
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Field validators reuse the domain rules (validate_shipping.dart) so the
  /// form can never disagree with [PlaceOrder]'s own validation. The domain
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

  Future<void> _placeOrder() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _placing = true);
    final result = await getIt<PlaceOrder>()(
      ShippingInfo(
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
      ),
      saveProfile: _saveProfile,
    );
    if (!mounted) return;

    result.fold(
      onSuccess: (order) => setState(() {
        _placing = false;
        _placed = order;
      }),
      onFailure: (error) => setState(() {
        _placing = false;
        _error = context.errorText(error);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed;
    if (placed != null) return OrderSuccessView(order: placed);
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.shippingDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.codOnlyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-name'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (_) => _validateField(kShippingNameField),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (_) => _validateField(kShippingPhoneField),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-address'),
              controller: _address,
              decoration: InputDecoration(
                labelText: l10n.deliveryAddress,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              validator: (_) => _validateField(kShippingAddressField),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('checkout-save-profile'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.saveDetailsNextTime),
              value: _saveProfile,
              onChanged: (value) => setState(() => _saveProfile = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _placing ? null : _placeOrder,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.placeOrderCod),
            ),
          ],
        ),
      ),
    );
  }
}
