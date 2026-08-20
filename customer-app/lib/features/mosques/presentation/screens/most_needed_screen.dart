import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The curated "most needed" list — a flat, short, admin-ordered list rather
/// than the governorate → area drill-down. That is the whole point of it: the
/// donor who doesn't know which mosque to help gets a shortlist, not a search.
///
/// Pops the picked mosque as a [DonationDestination] flagged `viaMostNeeded`,
/// so the badge and the reporting know how the donor arrived — the destination
/// itself is an ordinary mosque (delivery §4).
class MostNeededScreen extends StatefulWidget {
  /// True (the default) when this is the destination picker: a tap pops the
  /// mosque as a destination. False from the mosques tab, where a tap opens the
  /// mosque's own page instead — same list, different intent.
  final bool asPicker;

  const MostNeededScreen({super.key, this.asPicker = true});

  @override
  State<MostNeededScreen> createState() => _MostNeededScreenState();
}

class _MostNeededScreenState extends State<MostNeededScreen> {
  final _controller = ScrollController();
  final List<Mosque> _mosques = [];
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final page = await context.read<MosquesRepository>().fetchMosques(
        mostNeeded: true,
      );
      if (!mounted) return;
      setState(() {
        _mosques
          ..clear()
          ..addAll(page.results);
        _page = 1;
        _hasMore = page.hasMore;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.failure;
        _error = e.message;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await context.read<MosquesRepository>().fetchMosques(
        page: _page + 1,
        mostNeeded: true,
      );
      if (!mounted) return;
      setState(() {
        _mosques.addAll(page.results);
        _page += 1;
        _hasMore = page.hasMore;
      });
    } on ApiException {
      // Keep what's on screen; the next scroll retries.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _pick(Mosque mosque) {
    if (!widget.asPicker) {
      context.pushNamed(
        AppRoutes.mosqueDetailName,
        pathParameters: {'id': '${mosque.id}'},
      );
      return;
    }
    Navigator.of(context).pop(
      DonationDestination(
        mosqueId: mosque.id,
        label: mosque.name,
        isMostNeeded: mosque.isMostNeeded,
        viaMostNeeded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: TextCustom.subheading(text: l10n.mostNeededShort)),
      body: switch (_status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(),
        LoadStatus.failure => ErrorView(
          message: _error ?? l10n.comingSoon,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
        LoadStatus.success when _mosques.isEmpty => EmptyView(
          message: l10n.noSearchResults,
          icon: Icons.mosque_outlined,
        ),
        LoadStatus.success => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _load,
          child: ListView.separated(
            controller: _controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _mosques.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextCustom(
                    text: l10n.mostNeededPickBody,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                );
              }
              final mosque = _mosques[i - 1];
              return MosqueCard(
                mosque: mosque,
                onTap: () => _pick(mosque),
                trailing: Icon(
                  widget.asPicker
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.chevron_right_rounded,
                  color: context.colors.textHint,
                  size: 22,
                ),
              );
            },
          ),
        ),
      },
    );
  }
}
