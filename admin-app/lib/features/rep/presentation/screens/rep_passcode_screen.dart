import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/passcode_input.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Second step of the rep login: the [phone] was entered on [RepLoginScreen],
/// here the rep types the 4-digit passcode. Entering the last digit submits
/// automatically — there is no submit button. On success the session flips and
/// the router lands on the rep shell.
class RepPasscodeScreen extends StatefulWidget {
  final String phone;
  const RepPasscodeScreen({super.key, required this.phone});

  @override
  State<RepPasscodeScreen> createState() => _RepPasscodeScreenState();
}

class _RepPasscodeScreenState extends State<RepPasscodeScreen> {
  final _passcodeController = TextEditingController();
  bool _busy = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Guard against a lost `extra` (e.g. a cold restart on this route): without
    // a phone there is nothing to sign in with, so fall back to step one.
    if (widget.phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(AppRoutes.repLoginName);
      });
    }
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passcodeController.text.length != kPasscodeLength) {
      ShowMessage.error(context, l10n.repPasscodeRequired);
      return;
    }
    setState(() {
      _busy = true;
      _hasError = false;
    });
    try {
      await context.read<AuthRepository>().repLogin(
        phone: widget.phone,
        passcode: _passcodeController.text,
      );
      // Session flip → the router redirects to the rep shell.
    } on ApiException catch (e) {
      if (!mounted) return;
      // Clear the wrong passcode so the rep can retry immediately.
      _passcodeController.clear();
      setState(() => _hasError = true);
      ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.repPasscodeStepTitle,
      subtitle: l10n.repPasscodeStepSubtitle,
      children: [
        // The number being signed into, with a quick way back to change it.
        Center(
          child: Column(
            children: [
              TextCustom(
                text: widget.phone,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              TextButton(
                onPressed: _busy ? null : () => context.pop(),
                child: TextCustom(
                  text: l10n.repChangePhone,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PasscodeInput(
          controller: _passcodeController,
          autofocus: true,
          enabled: !_busy,
          hasError: _hasError,
          onChanged: (_) {
            if (_hasError) setState(() => _hasError = false);
          },
          onCompleted: (_) {
            if (!_busy) _submit();
          },
        ),
        const SizedBox(height: 24),
        if (_busy)
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
            onPressed: _busy
                ? null
                : () => context.pushNamed(AppRoutes.repForgotName),
            child: TextCustom(
              text: l10n.repForgotPasscode,
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
