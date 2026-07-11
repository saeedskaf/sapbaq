import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/shared/data/models/mosque.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Searchable mosque picker for assigning a MOST_NEEDED destination.
/// Pops the chosen mosque as `(id, name)`.
class MosquePickerSheet extends StatefulWidget {
  final AdminRepository repository;
  const MosquePickerSheet({super.key, required this.repository});

  @override
  State<MosquePickerSheet> createState() => _MosquePickerSheetState();
}

class _MosquePickerSheetState extends State<MosquePickerSheet> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Mosque> _mosques = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.fetchMosques(search: search);
      if (!mounted) return;
      setState(() {
        _mosques = page.results;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            TextCustom.subheading(text: l10n.chooseMosque),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (q) => _load(q.trim()),
                decoration: InputDecoration(
                  hintText: l10n.searchMosqueHint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            ),
            Expanded(child: _list(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _list(AppLocalizations l10n) {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(
        message: _error!,
        retryLabel: l10n.retry,
        onRetry: () => _load(_searchController.text.trim()),
      );
    }
    if (_mosques.isEmpty) {
      return EmptyView(
        message: l10n.noSearchResults,
        icon: Icons.mosque_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _mosques.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: context.colors.border),
      itemBuilder: (context, i) {
        final m = _mosques[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).pop((id: m.id, name: m.name)),
          leading: Icon(Icons.mosque_outlined, color: context.colors.primary),
          title: TextCustom(
            text: m.name,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: m.area.isEmpty
              ? null
              : TextCustom(
                  text: m.area,
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
        );
      },
    );
  }
}
