import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/constants/app_assets.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';
import 'package:sapbaq/features/orders/data/models/delivery_proof.dart';
import 'package:sapbaq/features/orders/data/models/order.dart';
import 'package:sapbaq/features/orders/data/models/review.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:sapbaq/features/orders/presentation/widgets/status_badge.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (reason == null) return; // dismissed / kept the order
    cubit.cancel(reason: reason.isEmpty ? null : reason);
  }

  Future<void> _rate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<OrderDetailCubit>();
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReviewSheet(),
    );
    if (result == null) return;
    final ok = await cubit.submitReview(rating: result.$1, comment: result.$2);
    if (ok && context.mounted) ShowMessage.success(context, l10n.reviewThanks);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => OrderDetailCubit(
        context.read<OrdersRepository>(),
        context.read<PaymentRepository>(),
      )..load(orderId),
      child: Scaffold(
        appBar: AppBar(
          title: TextCustom.subheading(text: l10n.orderDetailsTitle),
        ),
        body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
          listenWhen: (a, b) => b.message != null && a.message != b.message,
          listener: (context, state) =>
              ShowMessage.error(context, state.message!),
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
              case LoadStatus.failure:
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<OrderDetailCubit>().load(orderId),
                );
              case LoadStatus.success:
                return RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () => context.read<OrderDetailCubit>().refresh(),
                  child: _Body(
                    order: state.order!,
                    review: state.review,
                    proofs: state.proofs,
                  ),
                );
            }
          },
        ),
        bottomNavigationBar: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            final order = state.order;
            if (order == null) return const SizedBox.shrink();

            if (order.isPending) {
              return _BottomBar(
                child: Row(
                  children: [
                    Expanded(
                      child: ButtonCustom.secondary(
                        text: l10n.cancelOrder,
                        enabled: !state.busy,
                        onPressed: () => _confirmCancel(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ButtonCustom.primary(
                        text: l10n.payNow,
                        isLoading: state.busy,
                        onPressed: () => context.read<OrderDetailCubit>().pay(),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (order.status == 'DELIVERED' && state.review == null) {
              return _BottomBar(
                child: ButtonCustom.primary(
                  text: l10n.rateOrder,
                  isLoading: state.busy,
                  onPressed: () => _rate(context),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Order order;
  final Review? review;
  final List<DeliveryProof> proofs;
  const _Body({required this.order, this.review, this.proofs = const []});

  @override
  Widget build(BuildContext context) {
    // Group proofs by destination; null-destination proofs render order-level.
    final byDestination = <int?, List<DeliveryProof>>{};
    for (final proof in proofs) {
      byDestination.putIfAbsent(proof.destinationId, () => []).add(proof);
    }
    final orderLevelProofs = byDestination[null] ?? const <DeliveryProof>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _SummaryCard(order: order),
        if (review != null) ...[
          const SizedBox(height: 14),
          _ReviewCard(review: review!),
        ],
        const SizedBox(height: 16),
        for (final destination in order.destinations) ...[
          _DestinationCard(
            destination: destination,
            proofs: byDestination[destination.id] ?? const [],
          ),
          const SizedBox(height: 14),
        ],
        if (orderLevelProofs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.5),
            ),
            child: _ProofStrip(proofs: orderLevelProofs),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Order order;
  const _SummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = formatShortDate(order.createdAt);
    final notes = order.customerNotes;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextCustom.heading(
                  text: l10n.orderRef(order.displayCode),
                  fontSize: 18,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextCustom(
                text: l10n.totalLabel,
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
              TextCustom(
                text: l10n.priceKwd(order.totalAmount),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetaRow(
            icon: Icons.place_outlined,
            text: l10n.destinationsCount(order.destinationCount),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaRow(icon: Icons.calendar_today_rounded, text: date),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: context.colors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextCustom(
                      text: notes,
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    // Arabic → align right; English → align left.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: context.colors.textSecondary,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }
}

/// Surface bar with a soft top shadow for the screen's primary actions.
class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            text: l10n.yourReview,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ColorsCustom.primaryDark,
          ),
          const SizedBox(height: 6),
          _Stars(rating: review.rating),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextCustom.body(
              text: review.comment,
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 22,
            color: ColorsCustom.warning,
          ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final OrderDestination destination;
  final List<DeliveryProof> proofs;
  const _DestinationCard({required this.destination, this.proofs = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driver = destination.driver;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        destination.isMostNeeded
                            ? Icons.volunteer_activism_rounded
                            : Icons.place_rounded,
                        size: 20,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextCustom(
                        text: destination.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(status: destination.status),
                  ],
                ),
                if (driver != null) ...[
                  const SizedBox(height: 14),
                  _DriverTile(driver: driver),
                ],
                const SizedBox(height: 16),
                _DestinationTimeline(destination: destination),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in destination.items) _ItemRow(item: item),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextCustom(
                  text: l10n.totalLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
                TextCustom(
                  text: l10n.priceKwd(destination.subtotal),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
          if (proofs.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _ProofStrip(proofs: proofs),
            ),
          ],
        ],
      ),
    );
  }
}

/// Per-destination delivery timeline (FLUTTER_TASKS T4). Each destination is
/// delivered independently, so its progress comes from `destination.status` +
/// its own timestamps — not the coarse `order.status` tracker at the top.
/// Reached steps are highlighted with their time; upcoming steps are muted.
class _DestinationTimeline extends StatelessWidget {
  final OrderDestination destination;
  const _DestinationTimeline({required this.destination});

  // The team-leader hand-off (`ASSIGNED_TO_TEAM`) is an internal staff step the
  // customer shouldn't see, so it's omitted here and treated as PENDING below.
  static const List<String> _steps = [
    'PENDING',
    'ASSIGNED',
    'IN_DELIVERY',
    'DELIVERED',
  ];

  String? _timeFor(String step) {
    switch (step) {
      case 'ASSIGNED':
        return destination.assignedAt;
      case 'IN_DELIVERY':
        return destination.inDeliveryAt;
      case 'DELIVERED':
        return destination.deliveredAt;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Collapse the hidden team-leader step onto PENDING: until a handler is
    // assigned, the customer simply sees the destination as still pending.
    final status = destination.status == 'ASSIGNED_TO_TEAM'
        ? 'PENDING'
        : destination.status;

    if (status == 'CANCELLED') {
      return _TimelineStep(
        label: orderStatusLabel(l10n, 'CANCELLED'),
        time: formatShortDateTime(destination.cancelledAt),
        done: true,
        isLast: true,
        color: ColorsCustom.error,
      );
    }

    final current = _steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineStep(
            label: orderStatusLabel(l10n, _steps[i]),
            time: formatShortDateTime(_timeFor(_steps[i])),
            done: current >= 0 && i <= current,
            isLast: i == _steps.length - 1,
            color: context.colors.primary,
          ),
      ],
    );
  }
}

/// One row of [_DestinationTimeline]: a dot + connector and the step's
/// label/time, dimmed when the step hasn't been reached yet.
class _TimelineStep extends StatelessWidget {
  final String label;
  final String time;
  final bool done;
  final bool isLast;
  final Color color;
  const _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = done ? color : context.colors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: context.colors.border),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextCustom(
                      text: label,
                      fontSize: 13,
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      color: done
                          ? context.colors.textPrimary
                          : context.colors.textHint,
                    ),
                  ),
                  if (done && time.isNotEmpty)
                    TextCustom(
                      text: time,
                      fontSize: 11.5,
                      color: context.colors.textHint,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  final User driver;
  const _DriverTile({required this.driver});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              size: 18,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: l10n.driverLabel,
                  fontSize: 12,
                  color: context.colors.textHint,
                ),
                const SizedBox(height: 2),
                TextCustom(
                  text: driver.fullName,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (driver.phone case final phone? when phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  TextCustom(
                    text: phone,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = resolveMediaUrl(item.product.image);
    // Arabic → align right; English → align left (same rule for name & quantity).
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textAlign = isArabic ? TextAlign.right : TextAlign.left;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: imageUrl == null
                  ? ColoredBox(
                      color: context.colors.surfaceVariant,
                      child: Icon(
                        Icons.water_drop_outlined,
                        color: context.colors.textHint,
                        size: 20,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: context.colors.surfaceVariant,
                        child: Icon(
                          Icons.water_drop_outlined,
                          color: context.colors.textHint,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: item.product.name,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
          const SizedBox(width: 8),
          TextCustom(
            text: '×${item.quantity}',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            textAlign: textAlign,
          ),
          const SizedBox(width: 12),
          TextCustom(
            text: l10n.priceKwd(item.lineTotal),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ],
      ),
    );
  }
}

class _ProofStrip extends StatelessWidget {
  final List<DeliveryProof> proofs;
  const _ProofStrip({required this.proofs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_rounded,
              size: 16,
              color: context.colors.primary,
            ),
            const SizedBox(width: 6),
            TextCustom(
              text: l10n.deliveryProofs,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColorsCustom.primaryDark,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: proofs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ProofThumb(proof: proofs[i]),
          ),
        ),
        // The delivery note belongs to the delivery, not to any one image
        // (there can be several photos). Show each distinct note once here,
        // inside the proofs section, rather than over a single image.
        for (final note in {
          for (final p in proofs)
            if (p.note.trim().isNotEmpty) p.note.trim(),
        }) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: context.colors.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextCustom(
                  text: note,
                  fontSize: 12.5,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProofThumb extends StatelessWidget {
  final DeliveryProof proof;
  const _ProofThumb({required this.proof});

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(proof.file);
    return GestureDetector(
      // Images open in the in-app zoom viewer; videos play in the in-app player.
      onTap: url == null
          ? null
          : () {
              if (proof.isImage) {
                _showProof(context, proof, url);
              } else {
                openInAppVideo(context, proof.file);
              }
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (proof.isImage && url != null)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ProofPlaceholder(),
                )
              else if (proof.isVideo)
                const _VideoCover()
              else
                const _ProofPlaceholder(),
              if (proof.isVideo)
                const PositionedDirectional(
                  bottom: 6,
                  start: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cover for a video proof: the brand mark card (videos have no server-side
/// thumbnail, so we show the logo instead of a blank tile).
class _VideoCover extends StatelessWidget {
  const _VideoCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.asset(AppAssets.logoMark, fit: BoxFit.contain),
      ),
    );
  }
}

class _ProofPlaceholder extends StatelessWidget {
  const _ProofPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceVariant,
      child: Icon(Icons.image_outlined, color: context.colors.textHint),
    );
  }
}

void _showProof(BuildContext context, DeliveryProof proof, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: proof.isImage
                  ? InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _ProofPlaceholder(),
                      ),
                    )
                  : const AspectRatio(
                      aspectRatio: 1,
                      child: _ProofPlaceholder(),
                    ),
            ),
          ),
          // The delivery note is shown once in the proofs section, not here —
          // it belongs to the whole delivery, not to this single image. The
          // caption keeps only this photo's own upload time.
          if (proof.uploadedAt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextCustom(
                text: _formatProofDate(proof.uploadedAt!),
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _formatProofDate(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}/${two(date.month)}/${two(date.day)} • '
      '${two(date.hour)}:${two(date.minute)}';
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: TextCustom.subheading(text: l10n.cancelOrderConfirm),
      content: FormFieldCustom(
        controller: _controller,
        hintText: l10n.cancelReasonHint,
        isRequired: false,
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: TextCustom(
            text: l10n.keepOrder,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: TextCustom(
            text: l10n.confirmCancel,
            color: ColorsCustom.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + safeBottom),
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
            const SizedBox(height: 16),
            TextCustom.subheading(
              text: l10n.rateOrderTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setState(() => _rating = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: ColorsCustom.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FormFieldCustom(
              controller: _controller,
              hintText: l10n.reviewCommentHint,
              isRequired: false,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ButtonCustom.primary(
              text: l10n.submitReview,
              onPressed: () =>
                  Navigator.pop(context, (_rating, _controller.text.trim())),
            ),
          ],
        ),
      ),
    );
  }
}
