import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/addresses/data/addresses_repository.dart';
import 'package:sapbaq/features/addresses/data/models/address.dart';
import 'package:sapbaq/features/addresses/presentation/bloc/addresses_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Saved addresses — list with add / edit / delete and a default marker.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          AddressesCubit(context.read<AddressesRepository>())..load(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: TextCustom.subheading(text: l10n.addressesTitle),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: TextCustom(
              text: l10n.addAddress,
              color: context.colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: BlocConsumer<AddressesCubit, AddressesState>(
            listenWhen: (a, b) => b.message != null && a.message != b.message,
            listener: (context, state) =>
                ShowMessage.error(context, state.message!),
            builder: (context, state) {
              if (state.status == LoadStatus.loading) {
                return const LoadingView();
              }
              if (state.status == LoadStatus.failure) {
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<AddressesCubit>().load(),
                );
              }
              if (state.items.isEmpty) {
                return EmptyView(
                  message: l10n.emptyAddresses,
                  icon: Icons.location_on_outlined,
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 96,
                ),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _AddressCard(
                  address: state.items[i],
                  onEdit: () => _openForm(context, existing: state.items[i]),
                  onDelete: () => _confirmDelete(context, state.items[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Address? existing}) async {
    final cubit = context.read<AddressesCubit>();
    final saved = await context.pushNamed<bool>(
      AppRoutes.addressFormName,
      extra: existing,
    );
    if (saved == true) cubit.load();
  }

  void _confirmDelete(BuildContext context, Address address) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AddressesCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: TextCustom.subheading(text: l10n.deleteAddressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: TextCustom(
              text: l10n.cancelButton,
              color: context.colors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.delete(address.id);
            },
            child: TextCustom(
              text: l10n.deleteButton,
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = address.label.isNotEmpty ? address.label : address.area;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 18,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TextCustom(
                        text: title,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      _DefaultBadge(label: l10n.defaultBadge),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                TextCustom(
                  text: address.summary,
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: context.colors.primary,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  final String label;
  const _DefaultBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextCustom(
        text: label,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.colors.primary,
      ),
    );
  }
}
