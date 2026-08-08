import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/message_view.dart';
import '../../widgets/responsive/content_max_width.dart';
import 'catalog_cubit.dart';
import 'widgets/loaded_catalog.dart';

/// The customer catalog. Provides the DI-registered [CatalogCubit] via a
/// **value** provider: DI owns the cubit's lifecycle (lazy singleton), so
/// this must never close it — a `create` provider (closeOnDispose: true)
/// would poison the shared instance the moment the screen unmounts.
///
/// The loaded body (search, filters, grid) lives in [LoadedCatalog]
/// (`widgets/`).
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogCubit>.value(
      value: getIt<CatalogCubit>(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) => switch (state) {
          CatalogLoading() => const Center(child: CircularProgressIndicator()),
          CatalogError() => const ErrorView(),
          CatalogEmpty() => MessageView(
              icon: Icons.inventory_2_outlined,
              title: l10n.catalogEmptyTitle,
              message: l10n.catalogEmptyMessage,
            ),
          CatalogLoaded() => ContentMaxWidth(
            child: LoadedCatalog(state: state),
          ),
        },
      ),
    );
  }
}
