import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A single label/value detail row; skipped when [value] is blank.
class NeedDetail {
  final String label;
  final String value;
  const NeedDetail(this.label, this.value);
  bool get isEmpty => value.trim().isEmpty;
}

/// One action button on a [NeedCard].
class NeedAction {
  final String label;
  final Color? color;
  final bool isPrimary;
  final VoidCallback onTap;

  const NeedAction({required this.label, required this.onTap, this.color})
    : isPrimary = false;
  const NeedAction.primary({required this.label, required this.onTap})
    : color = null,
      isPrimary = true;
}

/// Shared moderation-queue card (water flags / equipment requests): a header
/// with a status chip, the mosque, detail rows, and a row of role-gated
/// actions (replaced by a spinner while [busy]).
class NeedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final NeedMosque? mosque;
  final List<NeedDetail> details;
  final List<NeedAction> actions;
  final bool busy;

  const NeedCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.mosque,
    this.details = const [],
    this.actions = const [],
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = details.where((d) => !d.isEmpty).toList();
    final m = mosque;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: context.colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: title,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(context, l10n, status),
            ],
          ),
          if (m != null &&
              (m.name.isNotEmpty || m.locationLine.isNotEmpty)) ...[
            const SizedBox(height: 10),
            _MetaRow(
              icon: Icons.mosque_outlined,
              text: [
                m.name,
                if (m.locationLine.isNotEmpty) m.locationLine,
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
          ],
          for (final d in rows) ...[
            const SizedBox(height: 6),
            _MetaRow(label: d.label, text: d.value),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            if (busy)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
              )
            else
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _actionButton(actions[i])),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(NeedAction a) {
    if (a.isPrimary) {
      return ButtonCustom.primary(text: a.label, onPressed: a.onTap);
    }
    return ButtonCustom(
      text: a.label,
      color: a.color ?? ColorsCustom.error,
      textColor: ColorsCustom.textOnPrimary,
      onPressed: a.onTap,
    );
  }
}

/// Localized label for a mosque-need status (water flags / equipment requests),
/// shared by the card chip and the queue filter pills.
String needStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'SUBMITTED' => l10n.repStatusSubmitted,
      'APPROVED' => l10n.repStatusApproved,
      'FULFILLED' => l10n.repStatusFulfilled,
      'REJECTED' => l10n.repStatusRejected,
      'CANCELLED' => l10n.repStatusCancelled,
      _ => status,
    };

Widget _statusChip(BuildContext context, AppLocalizations l10n, String status) {
  final color = switch (status) {
    'SUBMITTED' => context.colors.primary,
    'APPROVED' => ColorsCustom.warning,
    'FULFILLED' => ColorsCustom.success,
    'REJECTED' || 'CANCELLED' => context.colors.danger,
    _ => context.colors.textHint,
  };
  final label = needStatusLabel(l10n, status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextCustom(
      text: label,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String text;
  const _MetaRow({this.icon, this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: context.colors.textHint),
          const SizedBox(width: 6),
        ],
        if (label != null) ...[
          TextCustom(
            text: label!,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.textHint,
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
