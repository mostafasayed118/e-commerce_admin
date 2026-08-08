import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/entities/coupon.dart';
import '../../../../../core/error/result.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/responsive/content_max_width.dart';
import '../../../../widgets/responsive/responsive_breakpoints.dart';
import '../../../orders/order_date_format.dart';
import '../../widgets/admin_storefront_action.dart';
import '../admin_coupons_cubit.dart';

/// The admin create/edit form body. Rendered by [CouponFormScreen] once the
/// edited coupon is resolved from the shared coupons state (`null` coupon →
/// create mode).
///
/// Money inputs follow the product form's convention: dollars with decimals
/// parsed to integer cents; an empty optional money field means 0.
class CouponForm extends StatefulWidget {
  const CouponForm({super.key, this.coupon});

  final Coupon? coupon;

  @override
  State<CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<CouponForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _code = TextEditingController(
    text: widget.coupon?.code ?? '',
  );
  late final TextEditingController _value = TextEditingController(
    text: widget.coupon == null
        ? ''
        : widget.coupon!.type == CouponDiscountType.fixed
            ? _centsToInput(widget.coupon!.value)
            : widget.coupon!.value.toString(),
  );
  late final TextEditingController _minSpend = TextEditingController(
    text: widget.coupon == null || widget.coupon!.minSpendCents == 0
        ? ''
        : _centsToInput(widget.coupon!.minSpendCents),
  );
  late final TextEditingController _maxUses = TextEditingController(
    text: widget.coupon?.maxUses?.toString() ?? '',
  );

  late CouponDiscountType _type =
      widget.coupon?.type ?? CouponDiscountType.percent;
  late DateTime? _expiresAt = widget.coupon?.expiresAt;
  late bool _isActive = widget.coupon?.isActive ?? true;

  bool _saving = false;
  String? _error;

  /// `1234 -> "12.34"` — inverse of [_parseCents], same as the product form.
  static String _centsToInput(int cents) {
    final dollars = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    return '$dollars.$fraction';
  }

  /// Parses a currency string into cents; null when invalid (mirrors the
  /// product form's parser).
  static int? _parseCents(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final parts = normalized.split('.');
    if (parts.length > 2) return null;
    final dollars = int.tryParse(parts[0]);
    if (dollars == null || dollars < 0) return null;
    var cents = 0;
    if (parts.length == 2) {
      if (parts[1].length > 2) return null;
      final fraction = int.tryParse(parts[1].padRight(2, '0'));
      if (fraction == null) return null;
      cents = fraction;
    }
    return dollars * 100 + cents;
  }

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minSpend.dispose();
    _maxUses.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) =>
      (value == null || value.trim().isEmpty)
          ? context.l10n.requiredField
          : null;

  // Validation messages are display text — the digits (0, 100) follow the
  // active locale, like every other number in the app.
  String? _validateValue(String? value) {
    if (_type == CouponDiscountType.percent) {
      final parsed = int.tryParse(value ?? '');
      if (parsed == null || parsed < 1 || parsed > 100) {
        return context.localizeDigits(context.l10n.percentRange);
      }
      return null;
    }
    final cents = value == null ? null : _parseCents(value);
    if (cents == null || cents <= 0) {
      return context.localizeDigits(context.l10n.priceGreaterThanZero);
    }
    return null;
  }

  String? _validateMaxUses(String? value) {
    if (value == null || value.trim().isEmpty) return null; // unlimited
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1) return context.l10n.requiredField;
    return null;
  }

  String? _validateMinSpend(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null; // optional
    // _save parses with `!`, so anything unparseable here must be caught.
    final cents = _parseCents(input);
    if (cents == null) {
      return context.localizeDigits(context.l10n.priceGreaterThanZero);
    }
    return null;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = _expiresAt ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final value = _type == CouponDiscountType.percent
        ? int.parse(_value.text)
        : _parseCents(_value.text)!;
    final minSpendInput = _minSpend.text.trim();
    final minSpendCents = minSpendInput.isEmpty ? 0 : _parseCents(minSpendInput)!;
    final maxUsesInput = _maxUses.text.trim();
    final maxUses = maxUsesInput.isEmpty ? null : int.parse(maxUsesInput);

    final existing = widget.coupon;
    final draft = Coupon(
      id: existing?.id ?? 0, // generated by the data layer on create
      code: _code.text,
      type: _type,
      value: value,
      minSpendCents: minSpendCents,
      expiresAt: _expiresAt,
      maxUses: maxUses,
      usedCount: existing?.usedCount ?? 0,
      isActive: _isActive,
    );

    final cubit = context.read<AdminCouponsCubit>();
    setState(() => _saving = true);
    final result = existing == null
        ? await cubit.createCoupon(draft)
        : await cubit.updateCoupon(draft);
    if (!mounted) return;

    result.fold(
      onSuccess: (_) => context.pop(),
      onFailure: (error) {
        setState(() {
          _saving = false;
          _error = context.errorText(error);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coupon == null ? l10n.newCoupon : l10n.editCoupon),
        actions: const [AdminStorefrontAction()],
      ),
      body: Form(
        key: _formKey,
        child: ContentMaxWidth(
          maxWidth: ResponsiveBreakpoints.formMaxWidth,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('coupon-code'),
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.couponCode,
                hintText: l10n.couponCodeHint,
                border: const OutlineInputBorder(),
              ),
              validator: _validateCode,
            ),
            const SizedBox(height: 16),
            SegmentedButton<CouponDiscountType>(
              segments: [
                ButtonSegment(
                  value: CouponDiscountType.percent,
                  label: Text(l10n.discountPercent),
                  icon: const Icon(Icons.percent),
                ),
                ButtonSegment(
                  value: CouponDiscountType.fixed,
                  label: Text(l10n.couponFixedType),
                  icon: const Icon(Icons.attach_money),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) => setState(() {
                _type = selection.first;
                _value.clear();
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('coupon-value'),
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _type == CouponDiscountType.percent
                    ? l10n.discountPercent
                    : l10n.couponFixedValue,
                prefixText: _type == CouponDiscountType.fixed ? r'$ ' : null,
                border: const OutlineInputBorder(),
              ),
              validator: _validateValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('coupon-min-spend'),
              controller: _minSpend,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.minSpendOptional,
                // The '0 = ...' is guidance prose — convert like every other
                // number (matches the form validators).
                hintText: context.localizeDigits(l10n.minSpendHint),
                prefixText: r'$ ',
                border: const OutlineInputBorder(),
              ),
              validator: _validateMinSpend,
            ),
            const SizedBox(height: 16),
            // Expiry: a picker row with a clear action (null = never).
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickExpiry,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _expiresAt == null
                          ? l10n.neverExpires
                          // The shared order date formatter: localized month
                          // names AND Eastern digits for `ar` (intl's raw
                          // DateFormat keeps Western digits — see
                          // order_date_format.dart).
                          : formatOrderDate(
                              _expiresAt!,
                              locale:
                                  Localizations.localeOf(context).languageCode,
                            ),
                    ),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    tooltip: l10n.removeExpiry,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _expiresAt = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('coupon-max-uses'),
              controller: _maxUses,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.maxUsesOptional,
                hintText: l10n.unlimited,
                border: const OutlineInputBorder(),
              ),
              validator: _validateMaxUses,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('coupon-active'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.couponActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
