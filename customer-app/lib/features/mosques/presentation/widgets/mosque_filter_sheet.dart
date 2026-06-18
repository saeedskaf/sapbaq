import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The governorate/area/block selection returned by the filter sheet.
class MosqueFilterSelection {
  final String? governorate;
  final String? area;
  final String? block;
  const MosqueFilterSelection({this.governorate, this.area, this.block});
}

/// Cascading governorate → area → block filter sheet. Returns the chosen
/// [MosqueFilterSelection], or null if dismissed.
Future<MosqueFilterSelection?> showMosqueFilterSheet(
  BuildContext context, {
  required MosquesRepository repo,
  String? governorate,
  String? area,
  String? block,
}) {
  return showModalBottomSheet<MosqueFilterSelection>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MosqueFilterSheet(
      repo: repo,
      governorate: governorate,
      area: area,
      block: block,
    ),
  );
}

class _MosqueFilterSheet extends StatefulWidget {
  final MosquesRepository repo;
  final String? governorate;
  final String? area;
  final String? block;
  const _MosqueFilterSheet({
    required this.repo,
    this.governorate,
    this.area,
    this.block,
  });

  @override
  State<_MosqueFilterSheet> createState() => _MosqueFilterSheetState();
}

class _MosqueFilterSheetState extends State<_MosqueFilterSheet> {
  MosqueFilters _filters = const MosqueFilters();
  String? _gov;
  String? _area;
  String? _block;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _gov = widget.governorate;
    _area = widget.area;
    _block = widget.block;
    _reloadFacets(initial: true);
  }

  Future<void> _reloadFacets({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final filters =
          await widget.repo.fetchFilters(governorate: _gov, area: _area);
      if (mounted) setState(() => _filters = filters);
    } catch (_) {
      // Leave whatever facets we have; the dropdowns just won't expand.
    } finally {
      if (mounted && initial) setState(() => _loading = false);
    }
  }

  void _onGov(String? v) {
    setState(() {
      _gov = v;
      _area = null;
      _block = null;
    });
    _reloadFacets();
  }

  void _onArea(String? v) {
    setState(() {
      _area = v;
      _block = null;
    });
    _reloadFacets();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          TextCustom.subheading(text: l10n.filterTitle),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _Dropdown(
              label: l10n.filterGovernorate,
              allLabel: l10n.filterAll,
              value: _gov,
              options: _filters.governorates,
              onChanged: _onGov,
            ),
            const SizedBox(height: 12),
            _Dropdown(
              label: l10n.filterArea,
              allLabel: l10n.filterAll,
              value: _area,
              options: _filters.areas,
              onChanged: _gov == null ? null : _onArea,
            ),
            const SizedBox(height: 12),
            _Dropdown(
              label: l10n.filterBlock,
              allLabel: l10n.filterAll,
              value: _block,
              options: _filters.blocks,
              onChanged:
                  _area == null ? null : (v) => setState(() => _block = v),
            ),
          ],
          const SizedBox(height: 20),
          ButtonCustom.primary(
            text: l10n.applyButton,
            onPressed: () => Navigator.pop(
              context,
              MosqueFilterSelection(
                governorate: _gov,
                area: _area,
                block: _block,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ButtonCustom.secondary(
            text: l10n.clearFilters,
            onPressed: () =>
                Navigator.pop(context, const MosqueFilterSelection()),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String allLabel;
  final String? value;
  final List<FilterOption> options;
  final ValueChanged<String?>? onChanged;

  const _Dropdown({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a stale value that isn't in the current options.
    final validValue = options.any((o) => o.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(
          text: label,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.textSecondary,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          // Re-create the field when the selection/options change so the
          // cascading reset (e.g. clearing area when governorate changes) shows.
          key: ValueKey('$label:$validValue:${options.length}'),
          initialValue: validValue,
          isExpanded: true,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: TextCustom(text: allLabel),
            ),
            for (final o in options)
              DropdownMenuItem<String?>(
                value: o.value,
                child: TextCustom(
                  text: '${o.value} (${o.count})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
