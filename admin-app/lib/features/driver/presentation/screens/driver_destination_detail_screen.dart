import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/maps_launcher.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/driver/data/models/driver_destination.dart';
import 'package:sapbaq_admin/features/driver/presentation/bloc/driver_destination_detail_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/order_sections.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

class DriverDestinationDetailScreen extends StatelessWidget {
  final int destinationId;
  const DriverDestinationDetailScreen({super.key, required this.destinationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DriverDestinationDetailCubit(
        context.read<DriverRepository>(),
        destinationId,
      )..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _accept(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<DriverDestinationDetailCubit>().accept();
    if (ok && context.mounted) ShowMessage.success(context, l10n.acceptedMsg);
  }

  Future<void> _start(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok =
        await context.read<DriverDestinationDetailCubit>().startDelivery();
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.deliveryStartedMsg);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<DriverDestinationDetailCubit>();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RejectSheet(),
    );
    if (reason == null) return;
    final ok = await cubit.reject(reason);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.rejectedMsg);
      context.pop();
    }
  }

  Future<void> _uploadProof(BuildContext context, int destinationId) async {
    await context.pushNamed(
      AppRoutes.driverProofName,
      pathParameters: {'id': '$destinationId'},
    );
    if (context.mounted) context.read<DriverDestinationDetailCubit>().load();
  }

  Future<void> _openLocation(
    BuildContext context,
    DriverDestination dest,
    AppLocalizations l10n,
  ) async {
    final opened = await openMapsUrl(dest.mosque?.mapsUrl);
    if (!opened && context.mounted) {
      final address = dest.mosque?.address ?? '';
      ShowMessage.info(context, address.isEmpty ? l10n.noLocation : address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<DriverDestinationDetailCubit,
        DriverDestinationDetailState>(
      listenWhen: (a, b) => a.message != b.message && b.message != null,
      listener: (context, state) => ShowMessage.error(context, state.message!),
      builder: (context, state) {
        final dest = state.destination;
        return Scaffold(
          appBar: AppBar(
            title: TextCustom.subheading(
              text: dest == null
                  ? l10n.deliveryDetailsTitle
                  : l10n.orderRefShort(dest.shortReference),
            ),
          ),
          body: _body(context, state, l10n),
          bottomNavigationBar: dest == null
              ? null
              : _ActionBar(
                  destination: dest,
                  acting: state.acting,
                  onAccept: () => _accept(context),
                  onReject: () => _reject(context),
                  onStart: () => _start(context),
                  onUploadProof: () => _uploadProof(context, dest.id),
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    DriverDestinationDetailState state,
    AppLocalizations l10n,
  ) {
    if (state.status == LoadStatus.loading && state.destination == null) {
      return const LoadingView();
    }
    if (state.status == LoadStatus.failure && state.destination == null) {
      return ErrorView(
        message: state.message ?? l10n.genericError,
        retryLabel: l10n.retry,
        onRetry: () => context.read<DriverDestinationDetailCubit>().load(),
      );
    }
    final dest = state.destination;
    if (dest == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        DestinationSection(
          label: dest.label,
          destinationType: dest.destinationType,
          status: dest.status,
          mosque: dest.mosque,
          items: dest.items,
          subtotal: dest.subtotal,
          onOpenLocation: dest.mosque == null
              ? null
              : () => _openLocation(context, dest, l10n),
        ),
        if (dest.customer != null)
          SectionCard(
            title: l10n.customerLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: dest.customer!.fullName,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                TextCustom(
                  text: dest.customer!.phone,
                  fontSize: 13,
                  color: ColorsCustom.textSecondary,
                ),
              ],
            ),
          ),
        if ((dest.customerNotes ?? '').isNotEmpty)
          SectionCard(
            title: l10n.notesLabel,
            child: TextCustom(
              text: dest.customerNotes!,
              fontSize: 14,
              color: ColorsCustom.textSecondary,
            ),
          ),
        if (dest.isDelivered)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorsCustom.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: ColorsCustom.success,
                ),
                const SizedBox(width: 8),
                TextCustom(
                  text: l10n.deliveredNote,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColorsCustom.success,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final DriverDestination destination;
  final bool acting;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onUploadProof;

  const _ActionBar({
    required this.destination,
    required this.acting,
    required this.onAccept,
    required this.onReject,
    required this.onStart,
    required this.onUploadProof,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[];

    if (destination.isNew) {
      children.add(
        ButtonCustom.primary(
          text: l10n.acceptButton,
          isLoading: acting,
          onPressed: onAccept,
        ),
      );
      children.add(const SizedBox(height: 10));
      children.add(
        ButtonCustom(
          text: l10n.rejectButton,
          color: ColorsCustom.error,
          textColor: ColorsCustom.textOnPrimary,
          enabled: !acting,
          onPressed: onReject,
        ),
      );
    } else if (destination.canStartDelivery) {
      children.add(
        ButtonCustom.primary(
          text: l10n.startDeliveryButton,
          icon: const Icon(
            Icons.local_shipping_outlined,
            color: ColorsCustom.textOnPrimary,
            size: 20,
          ),
          isLoading: acting,
          onPressed: onStart,
        ),
      );
    } else if (destination.isInDelivery) {
      children.add(
        ButtonCustom.primary(
          text: l10n.uploadProofButton,
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: ColorsCustom.textOnPrimary,
            size: 20,
          ),
          onPressed: onUploadProof,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Bottom sheet collecting an optional rejection reason; pops the reason.
class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsCustom.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom.subheading(text: l10n.rejectTitle, color: ColorsCustom.error),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.rejectReasonHint),
          ),
          const SizedBox(height: 20),
          ButtonCustom(
            text: l10n.confirmReject,
            color: ColorsCustom.error,
            textColor: ColorsCustom.textOnPrimary,
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.cancelButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
