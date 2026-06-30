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

/// Ticket categories — the backend owns the enum; this stable list is safe to
/// hard-code (default OTHER).
const List<String> _categories = [
  'ORDER',
  'PAYMENT',
  'DELIVERY',
  'ACCOUNT',
  'OTHER',
];

String ticketCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'ORDER':
      return l10n.ticketCategoryOrder;
    case 'PAYMENT':
      return l10n.ticketCategoryPayment;
    case 'DELIVERY':
      return l10n.ticketCategoryDelivery;
    case 'ACCOUNT':
      return l10n.ticketCategoryAccount;
    default:
      return l10n.ticketCategoryOther;
  }
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String _category = 'OTHER';
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
        category: _category,
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
            const SizedBox(height: 16),
            TextCustom(
              text: l10n.ticketCategory,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    label: TextCustom(
                      text: ticketCategoryLabel(l10n, c),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
