import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../core/entities/shipping_info.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/money.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/checkout/place_order.dart';
import '../../../domain/usecases/checkout/validate_shipping.dart';

/// Checkout: the shipping form → [PlaceOrder] → inline success view.
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
  /// form can never disagree with [PlaceOrder]'s own validation.
  String? _validateField(String field) {
    final errors = validateShipping(ShippingInfo(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
    ));
    return errors[field];
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
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed;
    if (placed != null) return _SuccessView(order: placed);
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Shipping details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cash on delivery only — pay when your order arrives.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (_) => _validateField(kShippingPhoneField),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-address'),
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Delivery address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              validator: (_) => _validateField(kShippingAddressField),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('checkout-save-profile'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Save my details for next time'),
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
                  : const Text('Place order — Cash on delivery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Order placed!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Order ${order.orderNumber} · ${formatCents(order.totalCents)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will call ${order.shipping.phone} to confirm delivery details.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Back to shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
