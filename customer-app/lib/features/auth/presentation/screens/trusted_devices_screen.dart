import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/trusted_device.dart';
import 'package:sapbaq/features/auth/presentation/bloc/trusted_devices_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Manage the devices the user has trusted (Sapbaq_AUTH_Flow §3.2). Shows each
/// device with its last-used date, marks the current one, and lets the user
/// revoke the others — a revoked device needs a fresh OTP on its next sign-in.
class TrustedDevicesScreen extends StatelessWidget {
  const TrustedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrustedDevicesCubit(context.read<AuthRepository>())..load(),
      child: const _TrustedDevicesView(),
    );
  }
}

class _TrustedDevicesView extends StatelessWidget {
  const _TrustedDevicesView();

  Future<void> _confirmRevoke(BuildContext context, TrustedDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TrustedDevicesCubit>();
    final name = device.deviceName.isEmpty
        ? l10n.trustedDeviceUnnamed
        : device.deviceName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: TextCustom.subheading(text: l10n.revokeDeviceTitle),
        content: TextCustom(text: l10n.revokeDeviceBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: TextCustom(text: l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: TextCustom(
              text: l10n.revokeDeviceAction,
              color: ColorsCustom.error,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.revoke(device.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: TextCustom(
          text: l10n.trustedDevicesTitle,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
      body: BlocConsumer<TrustedDevicesCubit, TrustedDevicesState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError != null) {
            ShowMessage.error(context, state.actionError!);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<TrustedDevicesCubit>().load(),
            color: context.colors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              children: [
                TextCustom(
                  text: l10n.trustedDevicesDescription,
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(height: 16),
                if (state.status == TrustedListStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == TrustedListStatus.error)
                  _CenteredNote(text: state.listError ?? l10n.trustedDevicesError)
                else if (state.devices.isEmpty)
                  _CenteredNote(text: l10n.trustedDevicesEmpty)
                else
                  ...state.devices.map(
                    (d) => _TrustedDeviceTile(
                      device: d,
                      onRevoke: (state.busy || d.current)
                          ? null
                          : () => _confirmRevoke(context, d),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrustedDeviceTile extends StatelessWidget {
  final TrustedDevice device;
  final VoidCallback? onRevoke;
  const _TrustedDeviceTile({required this.device, required this.onRevoke});

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastUsed = device.lastUsedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smartphone_rounded,
            color: context.colors.primary,
            size: 22,
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
                        text: device.deviceName.isEmpty
                            ? l10n.trustedDeviceUnnamed
                            : device.deviceName,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.current) ...[
                      const SizedBox(width: 8),
                      const _CurrentBadge(),
                    ],
                  ],
                ),
                if (lastUsed != null) ...[
                  const SizedBox(height: 2),
                  TextCustom(
                    text: l10n.trustedDeviceLastUsed(_formatDate(lastUsed)),
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          if (device.current)
            // The device you're using can't be revoked from itself.
            TextCustom(
              text: l10n.trustedDeviceThis,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textHint,
            )
          else
            IconButton(
              onPressed: onRevoke,
              icon: Icon(
                Icons.link_off_rounded,
                color: ColorsCustom.error,
              ),
              tooltip: l10n.revokeDeviceAction,
            ),
        ],
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextCustom(
        text: l10n.trustedDeviceCurrent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.colors.primary,
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  final String text;
  const _CenteredNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: TextCustom(
          text: text,
          fontSize: 14,
          color: context.colors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
