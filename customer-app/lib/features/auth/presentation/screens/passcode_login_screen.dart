import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/passcode_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/passcode_login_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Returning sign-in (Sapbaq_AUTH_Flow §7): enter the 4-digit passcode. No OTP.
/// A new device (428) routes to device trust; a locked passcode (423) routes to
/// recovery — both carrying the number (and passcode, for the trust retry).
class PasscodeLoginScreen extends StatelessWidget {
  final String phone;
  const PasscodeLoginScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasscodeLoginCubit(context.read<AuthRepository>()),
      child: _PasscodeLoginView(phone: phone),
    );
  }
}

class _PasscodeLoginView extends StatefulWidget {
  final String phone;
  const _PasscodeLoginView({required this.phone});

  @override
  State<_PasscodeLoginView> createState() => _PasscodeLoginViewState();
}

class _PasscodeLoginViewState extends State<_PasscodeLoginView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<PasscodeLoginCubit>().login(
      phone: widget.phone,
      passcode: _controller.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthFlowListener(
      child: BlocConsumer<PasscodeLoginCubit, PasscodeLoginState>(
        listener: (context, state) {
          if (state.message != null) ShowMessage.error(context, state.message!);
          if (state.wrongPasscode) {
            _controller.clear();
            ShowMessage.error(context, l10n.passcodeWrong);
          }
          if (state.outcome == PasscodeOutcome.deviceUntrusted) {
            // Pass the passcode via `extra` (in-memory) so it never lands in the
            // route's query string.
            context.pushNamed(
              AppRoutes.deviceTrustName,
              queryParameters: {'phone': widget.phone},
              extra: _controller.text,
            );
            _controller.clear();
          }
          if (state.outcome == PasscodeOutcome.locked) {
            context.pushNamed(
              AppRoutes.forgotPasscodeName,
              queryParameters: {'phone': widget.phone},
            );
            _controller.clear();
          }
        },
        builder: (context, state) {
          return AuthScaffold(
            title: l10n.welcomeBackTitle,
            subtitle: l10n.enterPasscodeSubtitle(ltrIsolate(widget.phone)),
            children: [
              const SizedBox(height: 8),
              PasscodeInput(
                controller: _controller,
                enabled: !state.busy,
                hasError: state.wrongPasscode,
                onCompleted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (state.busy)
                Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(
                        context.colors.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: state.busy
                      ? null
                      : () => context.pushNamed(
                          AppRoutes.forgotPasscodeName,
                          queryParameters: {'phone': widget.phone},
                        ),
                  child: TextCustom(
                    text: l10n.forgotPasscode,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
