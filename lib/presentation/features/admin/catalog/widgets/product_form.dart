import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/entities/category.dart';
import '../../../../../core/entities/product.dart';
import '../../../../../core/error/result.dart';
import '../../../../../data/services/image_store.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/responsive/content_max_width.dart';
import '../../../../widgets/responsive/responsive_breakpoints.dart';
import '../../widgets/admin_storefront_action.dart';
import '../admin_catalog_cubit.dart';
import 'product_basic_fields.dart';
import 'product_image_field.dart';
import 'product_pricing_fields.dart';

/// The admin create/edit form body. Rendered by [ProductFormScreen] once the
/// edited product is resolved from the shared catalog state (`null` product
/// → create mode).
///
/// The image picker is intentionally NOT covered by widget tests: it opens a
/// platform dialog (gallery/file selector) that cannot run in the test
/// harness. Everything else — validation, the save path, error display — is
/// tested end-to-end via the admin flow test.
class ProductForm extends StatefulWidget {
  const ProductForm({super.key, required this.product, required this.categories});

  final Product? product;
  final List<Category> categories;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.product?.name ?? '',
  );
  late final TextEditingController _nameAr = TextEditingController(
    text: widget.product?.nameAr ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final TextEditingController _descriptionAr = TextEditingController(
    text: widget.product?.descriptionAr ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.product == null ? '' : _centsToInput(widget.product!.priceCents),
  );
  late final TextEditingController _discount = TextEditingController(
    text: widget.product?.discountPercent.toString() ?? '0',
  );
  late final TextEditingController _stock = TextEditingController(
    text: widget.product?.stock.toString() ?? '0',
  );

  late int? _categoryId = widget.product?.categoryId ??
      (widget.categories.isEmpty ? null : widget.categories.first.id);
  late String? _imagePath = widget.product?.imagePath;

  /// The image the product already had when the form opened. Files picked
  /// *this session* are deletable; this one belongs to the product on disk.
  late final String? _initialImagePath = widget.product?.imagePath;
  bool _saved = false;
  bool _saving = false;
  String? _error;
  bool _pickingImage = false;

  /// `1234 -> "12.34"` — the inverse of the form's parse, so an edited price
  /// shows as the user would type it.
  static String _centsToInput(int cents) {
    final dollars = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    return '$dollars.$fraction';
  }

  /// Parses a currency string (`12.34`, `12,3`, `12`) into cents.
  /// Returns null when invalid (empty, negative, >2 decimals, non-numeric).
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
    // Best-effort cleanup: a file picked this session but never saved (the
    // user backed out of the form) would otherwise be orphaned on disk. The
    // product's original file is never touched here.
    final picked = _imagePath;
    if (!_saved && picked != null && picked != _initialImagePath) {
      getIt<ImageStore>().deleteImage(picked);
    }
    _name.dispose();
    _nameAr.dispose();
    _description.dispose();
    _descriptionAr.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final result = await getIt<ImageStore>().saveImage(File(picked.path));
      if (!mounted) return;
      result.fold(
        onSuccess: (path) => setState(() => _imagePath = path),
        onFailure: (error) => _showError(context.errorText(error)),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _removeImage() async {
    final current = _imagePath;
    if (current != null && current != _initialImagePath) {
      // Only physically delete files picked this session. The product's
      // original file stays on disk: if the user backs out unsaved, the
      // product must still find its image; if they save, the DB reference is
      // cleared and the leftover file is a harmless (policy-accepted) orphan.
      await getIt<ImageStore>().deleteImage(current);
    }
    if (mounted) setState(() => _imagePath = null);
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final priceCents = _parseCents(_price.text)!;
    final discount = int.parse(_discount.text);
    final stock = int.parse(_stock.text);
    final cubit = getIt<AdminCatalogCubit>();

    // Arabic fields are optional: an empty box is persisted as null so the
    // display falls back to the canonical English text (never a blank).
    final nameAr = emptyToNull(_nameAr.text);
    final descriptionAr = emptyToNull(_descriptionAr.text);

    setState(() => _saving = true);
    final result = widget.product == null
        ? await cubit.createProduct(Product(
            id: 0, // generated by the data layer
            categoryId: _categoryId!,
            name: _name.text.trim(),
            description: _description.text.trim(),
            nameAr: nameAr,
            descriptionAr: descriptionAr,
            priceCents: priceCents,
            discountPercent: discount,
            stock: stock,
            imagePath: _imagePath,
          ))
        : await cubit.updateProduct(widget.product!.copyWith(
            categoryId: _categoryId!,
            name: _name.text.trim(),
            description: _description.text.trim(),
            nameAr: nameAr,
            descriptionAr: descriptionAr,
            priceCents: priceCents,
            discountPercent: discount,
            stock: stock,
            imagePath: _imagePath,
          ));
    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        // Prevent dispose-time cleanup from deleting the file we just saved.
        _saved = true;
        context.pop();
      },
      onFailure: (error) {
        setState(() {
          _saving = false;
          _error = context.errorText(error);
        });
      },
    );
  }

  String? _validateRequired(String? value) => (value == null || value.trim().isEmpty)
      ? context.l10n.requiredField
      : null;

  // Validation messages are display text — the digits (0, 100) follow the
  // active locale, like every other number in the app.
  String? _validatePrice(String? value) {
    final cents = value == null ? null : _parseCents(value);
    if (cents == null || cents <= 0) {
      return context.localizeDigits(context.l10n.priceGreaterThanZero);
    }
    return null;
  }

  String? _validatePercent(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0 || parsed > 100) {
      return context.localizeDigits(context.l10n.percentRange);
    }
    return null;
  }

  String? _validateStock(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 0) {
      return context.localizeDigits(context.l10n.stockNonNegative);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editProduct : l10n.newProduct),
        actions: const [AdminStorefrontAction()],
      ),
      body: Form(
        key: _formKey,
        child: ContentMaxWidth(
          maxWidth: ResponsiveBreakpoints.formMaxWidth,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProductImageField(
              imagePath: _imagePath,
              picking: _pickingImage,
              onPick: _pickImage,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 20),

            ProductBasicFields(
              nameController: _name,
              nameArController: _nameAr,
              categories: widget.categories,
              categoryId: _categoryId,
              onCategoryChanged: (value) => setState(() => _categoryId = value),
              nameValidator: _validateRequired,
            ),
            const SizedBox(height: 16),

            ProductPricingFields(
              priceController: _price,
              discountController: _discount,
              stockController: _stock,
              priceValidator: _validatePrice,
              percentValidator: _validatePercent,
              stockValidator: _validateStock,
            ),
            const SizedBox(height: 16),

            TextFormField(
              key: const Key('product-description'),
              controller: _description,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            TextFormField(
              key: const Key('product-description-ar'),
              controller: _descriptionAr,
              decoration: InputDecoration(
                labelText: l10n.arabicDescriptionOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: scheme.error),
              ),
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
                  : Text(l10n.saveProduct),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
