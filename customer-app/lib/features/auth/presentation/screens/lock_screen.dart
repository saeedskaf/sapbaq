import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/passcode_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';
import 'package:sapbaq/features/auth/presentation/bloc/lock_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// App-entry unlock for a persisted session (Sapbaq_AUTH_Flow §7/§10). Shown on
/// every cold launch of a set-up account: Face ID / Touch ID (if enabled) or the
/// 4-digit passcode. "Use different account" logs out.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    context.read<AuthRepository>().cachedUser().then((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (_) => LockCubit(
        context.read<AuthRepository>(),
        phone: user.phone ?? '',
      ),
      child: _LockView(user: user),
    );
  }
}

class _LockView extends StatefulWidget {
  final User user;
  const _LockView({required this.user});

  @override
  State<_LockView> createState() => _LockViewState();
}

class _LockViewState extends State<_LockView> {
  final _controller = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final l10n = AppLocalizations.of(context)!;
    context.read<LockCubit>().init(reason: l10n.biometricReason);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<LockCubit>().unlockWithPasscode(passcode: _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = widget.user.firstName.trim();

    return BlocConsumer<LockCubit, UnlockState>(
      listener: (context, state) {
        if (state.message != null) ShowMessage.error(context, state.message!);
        if (state.wrongPasscode) {
          _controller.clear();
          ShowMessage.error(context, l10n.passcodeWrong);
        }
        if (state.locked) {
          _controller.clear();
          context.pushNamed(
            AppRoutes.forgotPasscodeName,
            queryParameters: {'phone': widget.user.phone ?? ''},
          );
        }
      },
      builder: (context, state) {
        return AuthScaffold(
          title: name.isEmpty ? l10n.lockTitle : l10n.lockGreeting(name),
          subtitle: l10n.lockSubtitle,
          children: [
            const SizedBox(height: 8),
            PasscodeInput(
              controller: _controller,
              autofocus: !state.biometricEnabled,
              enabled: !state.busy,
              hasError: state.wrongPasscode,
              onCompleted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            if (state.biometricEnabled)
              Center(
                child: TextButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => context.read<LockCubit>().unlockWithBiometrics(
                            reason: l10n.biometricReason,
                          ),
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    color: context.colors.primary,
                    size: 22,
                  ),
                  label: TextCustom(
                    text: l10n.unlockWithBiometrics,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
              ),
            if (state.busy) ...[
              const SizedBox(height: 8),
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
            ],
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: state.busy
                    ? null
                    : () => context.read<LockCubit>().logout(),
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
