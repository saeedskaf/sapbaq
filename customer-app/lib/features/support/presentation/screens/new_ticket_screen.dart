import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Open a new support ticket. Pops `true` on success so the list can refresh.
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final repo = context.read<SupportRepository>();
    setState(() => _busy = true);
    try {
      await repo.createTicket(
        subject: _subject.text.trim(),
        body: _body.text.trim(),
      );
      if (!mounted) return;
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ShowMessage.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.newTicket)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            FormFieldCustom(
              controller: _subject,
              label: l10n.ticketSubject,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.ticketSubjectRequired
                  : null,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _body,
              label: l10n.ticketMessage,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.ticketMessageRequired
                  : null,
            ),
            const SizedBox(height: 20),
            ButtonCustom.primary(
              text: l10n.submitTicket,
              isLoading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
