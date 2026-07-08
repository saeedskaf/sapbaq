import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/passkey_device.dart';
import 'package:sapbaq/features/auth/presentation/bloc/passkey_devices_cubit.dart';
import 'package:sapbaq/features/auth/presentation/passkey_messages.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Manage the user's passkeys: list, add one for this device, or remove one.
class PasskeyDevicesScreen extends StatelessWidget {
  const PasskeyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PasskeyDevicesCubit(context.read<AuthRepository>())..load(),
      child: const _PasskeyDevicesView(),
    );
  }
}

class _PasskeyDevicesView extends StatelessWidget {
  const _PasskeyDevicesView();

  String _defaultDeviceName(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS ? 'iPhone' : 'Android';

  Future<void> _confirmDelete(BuildContext context, PasskeyDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PasskeyDevicesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: TextCustom.subheading(text: l10n.passkeyDeleteTitle),
        content: TextCustom(text: l10n.passkeyDeleteBody(device.deviceName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: TextCustom(text: l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: TextCustom(
              text: l10n.passkeyDeleteAction,
              color: ColorsCustom.error,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.delete(device.id);
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
          text: l10n.passkeysTitle,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
      body: BlocConsumer<PasskeyDevicesCubit, PasskeyDevicesState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError ||
            a.actionFailure != b.actionFailure ||
            (!a.registered && b.registered),
        listener: (context, state) {
          if (state.actionError != null) {
            ShowMessage.error(context, state.actionError!);
          }
          if (state.actionFailure != null) {
            ShowMessage.error(
              context,
              passkeyFailureMessage(l10n, state.actionFailure!),
            );
          }
          if (state.registered) {
            ShowMessage.success(context, l10n.passkeyRegistered);
          }
        },
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              TextCustom(
                text: l10n.passkeysDescription,
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: 16),
              ButtonCustom.primary(
                text: l10n.passkeyAddButton,
                icon: const Icon(Icons.add_rounded, size: 20),
                isLoading: state.busy,
                onPressed: state.busy
                    ? null
                    : () => context.read<PasskeyDevicesCubit>().register(
                        deviceName: _defaultDeviceName(context),
                      ),
              ),
              const SizedBox(height: 20),
              if (state.status == PasskeyListStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (state.status == PasskeyListStatus.error)
                _CenteredNote(text: state.listError ?? l10n.passkeyError)
              else if (state.devices.isEmpty)
                _CenteredNote(text: l10n.passkeyNoDevices)
              else
                ...state.devices.map(
                  (d) => _PasskeyTile(
                    device: d,
                    onDelete: state.busy ? null : () => _confirmDelete(context, d),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PasskeyTile extends StatelessWidget {
  final PasskeyDevice device;
  final VoidCallback? onDelete;
  const _PasskeyTile({required this.device, required this.onDelete});

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
          Icon(Icons.vpn_key_rounded, color: context.colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: device.deviceName.isEmpty
                      ? l10n.passkeyUnnamedDevice
                      : device.deviceName,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lastUsed != null) ...[
                  const SizedBox(height: 2),
                  TextCustom(
                    text: l10n.passkeyLastUsed(
                      '${lastUsed.year}-${lastUsed.month.toString().padLeft(2, '0')}-${lastUsed.day.toString().padLeft(2, '0')}',
                    ),
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: ColorsCustom.error),
            tooltip: l10n.passkeyDeleteAction,
          ),
        ],
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
