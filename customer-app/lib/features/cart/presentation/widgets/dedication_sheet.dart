import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The dedication captured for a cooler: the name engraved and whether the
/// person is alive or deceased. An empty [name] means the donor chose not to
/// engrave anything — the caller sends no dedication in that case.
typedef Dedication = ({String name, String status});

/// Collects a cooler dedication before adding it to the cart. Engraving a name
/// is optional (a toggle): resolves to the [Dedication] on confirm — with an
/// empty name when the donor opts out — or null if the sheet is dismissed.
Future<Dedication?> showDedicationSheet(BuildContext context) {
  return showModalBottomSheet<Dedication>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DedicationSheet(),
  );
}

class _DedicationSheet extends StatefulWidget {
  const _DedicationSheet();

  @override
  State<_DedicationSheet> createState() => _DedicationSheetState();
}

class _DedicationSheetState extends State<_DedicationSheet> {
  final _controller = TextEditingController();
  String _status = 'ALIVE';

  /// Whether the donor wants a name engraved. On by default — engraving is the
  /// point of the sheet — but they can turn it off to add a plain cooler.
  bool _engrave = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    // Opted out of engraving — add the cooler with no dedication.
    if (!_engrave) {
      Navigator.of(context).pop((name: '', status: ''));
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ShowMessage.error(context, l10n.dedicationNameRequired);
      return;
    }
    Navigator.of(context).pop((name: name, status: _status));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        media.viewInsets.bottom + media.padding.bottom + 20,
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom(
            text: l10n.dedicationTitle,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
          const SizedBox(height: 4),
          TextCustom(
            text: l10n.dedicationSubtitle,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 16),
          _EngraveToggle(
            label: l10n.dedicationEngraveToggle,
            value: _engrave,
            onChanged: (v) => setState(() => _engrave = v),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _engrave
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _confirm(),
                        decoration: InputDecoration(
                          labelText: l10n.dedicationNameLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatusChip(
                              label: l10n.dedicationAlive,
                              selected: _status == 'ALIVE',
                              onTap: () => setState(() => _status = 'ALIVE'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatusChip(
                              label: l10n.dedicationDeceased,
                              selected: _status == 'DECEASED',
                              onTap: () => setState(() => _status = 'DECEASED'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 20),
          ButtonCustom.primary(text: l10n.addToCart, onPressed: _confirm),
        ],
      ),
    );
  }
}

/// The "engrave a name" switch that reveals or hides the dedication fields.
class _EngraveToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EngraveToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            child: TextCustom(
              text: label,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryFill : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextCustom(
          text: label,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected
              ? context.colors.onPrimary
              : context.colors.textPrimary,
        ),
      ),
    );
  }
}
