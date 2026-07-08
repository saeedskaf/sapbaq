import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/profile_completion_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Final onboarding step for a fresh account: name + email. On success the
/// repository flips the session to authenticated and the router opens the app.
/// The backend requires a verified phone first (enforced upstream in the flow).
class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCompletionCubit(context.read<AuthRepository>()),
      child: const _ProfileCompletionView(),
    );
  }
}

class _ProfileCompletionView extends StatefulWidget {
  const _ProfileCompletionView();

  @override
  State<_ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<_ProfileCompletionView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    // Prefill from anything the provider already gave us (e.g. Google name).
    final user = context.read<AuthBloc>().state.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _middleName = TextEditingController(text: user?.middleName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<ProfileCompletionCubit>().submit(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      middleName: _middleName.text.trim(),
      email: _email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocConsumer<ProfileCompletionCubit, ProfileCompletionState>(
      listener: (context, state) {
        if (state.status == FormStatus.failure && state.message != null) {
          ShowMessage.error(context, state.message!);
        }
        // On success the session becomes authenticated → the router opens home.
      },
      builder: (context, state) {
        final loading = state.status == FormStatus.submitting;
        return AuthScaffold(
          title: l10n.completeProfileTitle,
          subtitle: l10n.completeProfileSubtitle,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormFieldCustom(
                    controller: _firstName,
                    label: l10n.firstNameLabel,
                    textInputAction: TextInputAction.next,
                    validator: validators.requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  FormFieldCustom(
                    controller: _middleName,
                    label: l10n.middleNameLabel,
                    isRequired: false,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  FormFieldCustom(
                    controller: _lastName,
                    label: l10n.lastNameLabel,
                    textInputAction: TextInputAction.next,
                    validator: validators.requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  FormFieldCustom(
                    controller: _email,
                    label: l10n.emailLabel,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: validators.combineValidators([
                      validators.requiredValidator,
                      validators.emailValidator,
                    ]),
                    onSubmitted: (_) => _submit(context),
                  ),
                  const SizedBox(height: 20),
                  ButtonCustom.primary(
                    text: l10n.continueButton,
                    isLoading: loading,
                    onPressed: loading ? null : () => _submit(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                child: TextCustom(text: l10n.useDifferentAccount, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }
}
