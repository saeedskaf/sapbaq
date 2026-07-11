import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/passcode_rules.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/passcode_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/set_passcode_cubit.dart';
import 'package:sapbaq/features/auth/presentation/passcode_messages.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// End of onboarding (Sapbaq_AUTH_Flow §5/§6): choose a 4-digit passcode
/// (entered twice), then opt into biometric unlock. Weak codes are rejected up
/// front. On finish the repository opens the app.
class SetPasscodeScreen extends StatelessWidget {
  const SetPasscodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetPasscodeCubit(context.read<AuthRepository>())..init(),
      child: const _SetPasscodeView(),
    );
  }
}

class _SetPasscodeView extends StatefulWidget {
  const _SetPasscodeView();

  @override
  State<_SetPasscodeView> createState() => _SetPasscodeViewState();
}

class _SetPasscodeViewState extends State<_SetPasscodeView> {
  final _controller = TextEditingController();
  String _first = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCompleted(BuildContext context, SetPasscodeState state) {
    final l10n = AppLocalizations.of(context)!;
    final code = _controller.text;
    if (state.step == SetPasscodeStep.enter) {
      final issue = checkPasscode(code);
      if (issue != PasscodeIssue.none) {
        setState(() => _error = passcodeIssueMessage(l10n, issue));
        _controller.clear();
        return;
      }
      setState(() {
        _first = code;
        _error = null;
      });
      _controller.clear();
      context.read<SetPasscodeCubit>().toConfirm();
    } else if (state.step == SetPasscodeStep.confirm) {
      if (code != _first) {
        setState(() => _error = l10n.passcodeMismatch);
        _controller.clear();
        context.read<SetPasscodeCubit>().restart();
        return;
      }
      setState(() => _error = null);
      context.read<SetPasscodeCubit>().submit(passcode: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SetPasscodeCubit, SetPasscodeState>(
      listenWhen: (a, b) =>
          a.step != b.step || a.message != b.message,
      listener: (context, state) {
        if (state.message != null) ShowMessage.error(context, state.message!);
        // Clear the field when returning to the first entry.
        if (state.step == SetPasscodeStep.enter) _controller.clear();
      },
      builder: (context, state) {
        if (state.step == SetPasscodeStep.biometric) {
          return _BiometricOptIn(
            busy: state.busy,
            onEnable: () =>
                context.read<SetPasscodeCubit>().finish(enableBiometric: true),
            onSkip: () =>
                context.read<SetPasscodeCubit>().finish(enableBiometric: false),
          );
        }

        final confirming = state.step == SetPasscodeStep.confirm;
        return AuthScaffold(
          title: l10n.setPasscodeTitle,
          subtitle: confirming
              ? l10n.confirmPasscodeSubtitle
              : l10n.setPasscodeSubtitle,
          children: [
            const SizedBox(height: 8),
            PasscodeInput(
              // A fresh key per step resets focus/animation between enter/confirm.
              key: ValueKey(state.step),
              controller: _controller,
              enabled: !state.busy,
              hasError: _error != null,
              onCompleted: (_) => _onCompleted(context, state),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              TextCustom(
                text: _error!,
                fontSize: 13,
                color: context.colors.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            if (state.busy)
              Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(context.colors.primary),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: state.busy
                    ? null
                    : () => context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested()),
                child: TextCustom(
                  text: l10n.useDifferentAccount,
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The biometric opt-in shown after the passcode is set.
class _BiometricOptIn extends StatelessWidget {
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const _BiometricOptIn({
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return AuthScaffold(
      title: l10n.biometricTitle,
      subtitle: l10n.biometricSubtitle,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Icon(
            isIOS ? Icons.face_rounded : Icons.fingerprint_rounded,
            size: 72,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 28),
        ButtonCustom.primary(
          text: l10n.biometricEnable,
          isLoading: busy,
          onPressed: busy ? null : onEnable,
        ),
        const SizedBox(height: 10),
        ButtonCustom.secondary(
          text: l10n.biometricSkip,
          onPressed: busy ? null : onSkip,
        ),
      ],
    );
  }
}
