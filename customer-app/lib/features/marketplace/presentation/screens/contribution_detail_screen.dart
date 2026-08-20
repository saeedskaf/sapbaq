import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// One contribution's journey, drawn from the server's timeline.
///
/// The backend sends the steps ready to render — titles in both languages, the
/// order, and which one is current — so this screen contains no status logic of
/// its own. That matters most for an equipment campaign, where `funding` stays
/// current after payment: it is what explains "I paid, and nothing is installed
/// yet" — the rest of the donors haven't arrived.
class ContributionDetailScreen extends StatefulWidget {
  final int contributionId;
  const ContributionDetailScreen({super.key, required this.contributionId});

  @override
  State<ContributionDetailScreen> createState() =>
      _ContributionDetailScreenState();
}

class _ContributionDetailScreenState extends State<ContributionDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  ContributionDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final detail = await context.read<MarketplaceRepository>().contribution(
        widget.contributionId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.contributionDetailTitle),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: switch (_status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(),
        LoadStatus.failure => ErrorView(
          message: _error ?? l10n.comingSoon,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
        LoadStatus.success => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _Header(detail: _detail!),
              const SizedBox(height: 16),
              if (_detail!.timeline.isNotEmpty)
                _Timeline(steps: _detail!.timeline),
            ],
          ),
        ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ContributionDetail detail;
  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = detail.contribution;
    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosqueLine(
            mosque: c.mosque,
            icon: switch (c.kind) {
              ContributionKind.water => Icons.water_drop_rounded,
              ContributionKind.maintenance ||
              ContributionKind.contract => Icons.build_rounded,
              _ => Icons.kitchen_rounded,
            },
          ),
          // What the money bought. Water and maintenance fund no catalogue
          // item, so the row leaves on its own rather than being branched away.
          if (c.modelName.isNotEmpty || c.modelThumb != null) ...[
            const SizedBox(height: 12),
            _FundedUnit(contribution: c),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: c.kind == ContributionKind.equipment
                      ? l10n.yourShare
                      : l10n.amountLabel,
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
              TextCustom(
                text: l10n.priceKwd(c.amount),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ],
          ),
          if (c.createdAt != null) ...[
            const SizedBox(height: 6),
            TextCustom(
              text: formatShortDateTime(c.createdAt!.toIso8601String()),
              fontSize: 12,
              color: context.colors.textHint,
            ),
          ],
        ],
      ),
    );
  }
}

/// The unit this contribution paid towards — its photo and its composed name,
/// laid out exactly like the campaign card the donor gave from, so the receipt
/// shows the same thing the decision did. Tapping opens every angle of it.
///
/// A product approved without a combination sends `variant: null` and only its
/// cover (backend answers 2026-08-06) — one photo, and the row still stands.
class _FundedUnit extends StatelessWidget {
  final Contribution contribution;
  const _FundedUnit({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final images = contribution.modelImages;
    final name = contribution.modelName;
    return InkWell(
      onTap: switch (images.length) {
        0 => null,
        1 => () => openInAppImage(context, url: images.first),
        _ => () => openInAppImageGallery(context, urls: images),
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          ProductThumb(
            url: contribution.modelThumb,
            size: 56,
            radius: 12,
            placeholderIcon: Icons.kitchen_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: name,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (images.length > 1)
            Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: context.colors.textHint,
            ),
        ],
      ),
    );
  }
}

/// The vertical stepper: a dot per step with a connector between, and whatever
/// that step's `meta` carries underneath its title.
class _Timeline extends StatelessWidget {
  final List<ContributionStep> steps;
  const _Timeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            _Step(
              step: steps[i],
              isLast: i == steps.length - 1,
              // The connector belongs to the step above it, and takes that
              // step's colour: a done step joins solidly to the next, a
              // not-yet step trails off grey.
              nextState: i + 1 < steps.length ? steps[i + 1].state : null,
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final ContributionStep step;
  final bool isLast;
  final ContributionStepState? nextState;

  const _Step({
    required this.step,
    required this.isLast,
    required this.nextState,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final color = _color(context, step.state);
    final current = step.state == ContributionStepState.current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _Dot(state: step.state, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: step.state == ContributionStepState.done
                        ? context.colors.primary.withValues(alpha: 0.35)
                        : context.colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    text: step.titleFor(lang),
                    fontSize: 14,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: step.state == ContributionStepState.pending
                        ? context.colors.textSecondary
                        : context.colors.textPrimary,
                  ),
                  if (step.at != null) ...[
                    const SizedBox(height: 2),
                    TextCustom(
                      text: formatShortDateTime(step.at!.toIso8601String()),
                      fontSize: 11.5,
                      color: context.colors.textHint,
                    ),
                  ],
                  _StepMeta(step: step),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _color(BuildContext context, ContributionStepState state) =>
      switch (state) {
        ContributionStepState.done => context.colors.primary,
        ContributionStepState.current => ColorsCustom.warning,
        ContributionStepState.pending => context.colors.textHint,
        ContributionStepState.cancelled => context.colors.textHint,
        ContributionStepState.expired => ColorsCustom.error,
      };
}

class _Dot extends StatelessWidget {
  final ContributionStepState state;
  final Color color;
  const _Dot({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    final filled = state != ContributionStepState.pending;
    final icon = switch (state) {
      ContributionStepState.done => Icons.check_rounded,
      ContributionStepState.cancelled => Icons.close_rounded,
      ContributionStepState.expired => Icons.timer_off_rounded,
      _ => null,
    };
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: icon == null
          ? null
          : Icon(icon, size: 13, color: ColorsCustom.textOnPrimary),
    );
  }
}

/// The step's extras, by `code` (task 2 §3). Anything unrecognized — a step a
/// newer backend added — simply renders nothing extra.
class _StepMeta extends StatelessWidget {
  final ContributionStep step;
  const _StepMeta({required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[];

    final share = step.metaString('share');
    if (share.isNotEmpty) {
      children.add(
        _MetaLine(label: l10n.yourShare, value: l10n.priceKwd(share)),
      );
    }

    // The funding step is the one that explains the wait: paid, but the goal
    // isn't met yet.
    final progress = step.metaProgress;
    final funded = step.metaString('funded');
    final target = step.metaString('target');
    if (progress != null || (funded.isNotEmpty && target.isNotEmpty)) {
      children.add(
        _FundingMeta(progress: progress ?? 0, funded: funded, target: target),
      );
    }

    final caseStatus = step.metaString('case_status');
    if (caseStatus.isNotEmpty) {
      children.add(
        _MetaLine(label: l10n.maintenanceCaseStatus, value: caseStatus),
      );
    }

    final startsAt = step.metaString('starts_at');
    final endsAt = step.metaString('ends_at');
    if (startsAt.isNotEmpty || endsAt.isNotEmpty) {
      children.add(
        _MetaLine(
          label: l10n.contractPeriod,
          value: [
            formatShortDate(startsAt),
            formatShortDate(endsAt),
          ].where((s) => s.isNotEmpty).join(' — '),
        ),
      );
    }

    final statement = step.metaString('statement');
    if (statement.isNotEmpty) {
      children.add(
        _MetaLine(label: l10n.fulfilmentStatement, value: statement),
      );
    }

    final photo = step.metaString('photo');
    if (photo.isNotEmpty) children.add(_ProofPhoto(url: photo));

    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: child),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return TextCustom(
      text: '$label: $value',
      fontSize: 12.5,
      color: context.colors.textSecondary,
    );
  }
}

class _FundingMeta extends StatelessWidget {
  final int progress;
  final String funded;
  final String target;

  const _FundingMeta({
    required this.progress,
    required this.funded,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 100) / 100,
            minHeight: 8,
            backgroundColor: context.colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(context.colors.primary),
          ),
        ),
        if (funded.isNotEmpty && target.isNotEmpty) ...[
          const SizedBox(height: 4),
          TextCustom(
            text: l10n.fundedOfTarget(funded, target),
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ],
      ],
    );
  }
}

/// The delivery/installation photo — now carried by the final step's meta, not
/// the contribution's old `proof_photo` field.
class _ProofPhoto extends StatelessWidget {
  final String url;
  const _ProofPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolved = resolveMediaUrl(url);
    if (resolved == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(
          text: l10n.proofPhotoLabel,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => openInAppImage(context, url: url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: context.colors.surfaceVariant),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
